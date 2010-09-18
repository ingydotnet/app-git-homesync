package App::Git::HomeSync::Command::init;
use Moose;
use namespace::autoclean;

extends qw(App::Git::HomeSync::Command);

use File::chdir qw( $CWD );
use IO::Prompter;
use File::HomeDir ();
use Path::Class::Dir ();

sub abstract {
    q{Supply the --master-repo option to sync directly}
}

use Cwd qw(getcwd);

# XXX Still needed?
has 'other-user' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    default       => sub { $ENV{USER} },
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The user of the other box that you want to sync '
                   . 'with',
);

# XXX Still needed?
has 'other-host' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The address of the other box that you want to '
                   . 'sync with',
);

# XXX Still needed?
has 'other-hostname' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The hostname of the other box that you want to '
                   . 'sync with',
);

has 'master-repo' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The full path to the master repository to sync to',
);

has '_master_repo' => (
    isa        => 'Str',
    is         => 'rw',
    required   => 0,
    lazy_build => 1,
);

sub _build__master_repo {
    my $self = shift;

    my $master_repo = Path::Class::Dir->new(
        $self->_repo_dir, $self->_repo_name
    );
    return $master_repo->stringify;
}

around '_master_repo' => sub {
    my $orig = shift;
    my $self = shift;

    # Don't prompt for paths if --master-repo was on the command-line
    return $self->{'master-repo'} if $self->{'master-repo'};
    return $self->$orig(@_);
};

has '_repo_dir' => (
    isa        => 'Str',
    is         => 'rw',
    required   => 0,
    lazy_build => 1,
);

sub _build__repo_dir {
    my $self = shift;

    my $home_dir = $self->_home_dir;
    my $repo_dir_default = $home_dir->subdir(qw( var git ));

    my $user_repo_dir = prompt(
        (   sprintf q{Where shall we create the master repository? [%s]},
            $repo_dir_default->stringify
        ),
        -in => *STDIN,
        -timeout => 30, # (To allow for running non-interactively in a
                        # test script)
        -verbatim,
        -complete => 'filenames',
        -default => $repo_dir_default->stringify,
    );
    $user_repo_dir = Path::Class::Dir->new($user_repo_dir);
    return $user_repo_dir->stringify;
}

has '_repo_name' => (
    isa        => 'Str',
    is         => 'rw',
    required   => 0,
    lazy_build => 1,
);

sub _build__repo_name {
    my $self = shift;

    my $repo_name_default = 'home.git';
    my $user_repo_name = prompt(
        (   sprintf q{What do you want to name the master repository? [%s]},
            $repo_name_default
        ),
        -in => *STDIN,
        -timeout => 30,
        -verbatim,
        -default => $repo_name_default,
    );
    return $user_repo_name;
}

# TODO Try to move these non-option attributes to Command.pm
has '_remote_branch_name' => (
    isa        => 'Str',
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);

sub _build__remote_branch_name {
    my $self = shift;
    my $remote_branch_name
        = $self->{'other-hostname'} ?
          $self->{'other-hostname'}
        : 'origin';
    return $remote_branch_name;
}

has '_git_remote_add_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_remote_add_cmd {
    my $self = shift;

    my $url = $self->_master_repo;

    my $remote_add_cmd = sprintf q{git remote add %s '%s'},
        $self->_remote_branch_name,
        $url;
    return $remote_add_cmd;
}

sub validate {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('No arguments are expected') if @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # TODO Prompt user to change to their home directory if they are not
    # already in it

    # If the user supplied the path on the command-line...
    if ( $self->{'master-repo'} ) {
        $self->_sync_with_master_repo();
    }
    # Create the repo (and thereby the path)
    else {
        $self->_initialize_master_repo_and_sync();
    }
}

sub _sync_with_master_repo {
    my $self = shift;

    # TODO Move aside conflicting files
    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds => [
                map { $self->$_ }
                qw( _git_init_cmd
                    _git_config_user_cmd
                    _git_remote_add_cmd
                    _git_fetch_cmd
                    _git_branch_cmd
                    _git_checkout_cmd )
            ],
        }
    );
}

sub _initialize_master_repo_and_sync {
    my $self = shift;

    my $orig_path = Path::Class::Dir->new();

    my $master_repo = Path::Class::Dir->new(
        $self->_master_repo
    );

    unless ( $self->{'dry-run'} ) {
        $master_repo->mkpath unless -d $master_repo->stringify;
    }

    unless ( $self->{'dry-run'} ) {
        $CWD = $master_repo->stringify;
    }
    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds    => [
                map { $self->$_ }
                qw( _git_init_bare_cmd )
            ],
        }
    );

    unless ( $self->{'dry-run'} ) {
        $CWD = $orig_path->stringify;
    }
    # TODO Move aside conflicting files
    # TODO Add .gitignore after empty commit
    # TODO Add more diagnostics if the --allow-empty commit autodies
    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds    => [
                map { $self->$_ }
                qw( _git_init_cmd
                    _git_config_user_cmd
                    _git_remote_add_cmd
                    _git_fetch_cmd
                    _git_branch_cmd
                    _git_checkout_cmd
                    _git_config_branch_remote_cmd
                    _git_config_branch_merge_cmd
                    _git_commit_empty_cmd
                    _git_push_cmd )
            ],
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
