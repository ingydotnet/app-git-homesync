package App::Git::HomeSync::Command::init;
use Moose;
use namespace::autoclean;

extends qw(App::Git::HomeSync::Command);

use File::chdir qw( $CWD );
use IO::Prompter;
use File::HomeDir ();
use Path::Class::Dir ();

sub abstract {
    q{Supply the --repo-path option to sync directly}
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

# XXX Still needed?
has '_is_repo_path_supplied' => (
    isa      => 'Bool',
    is       => 'rw',
    default  => 0,
    required => 0,
);

# TODO Rename to 'master-repo'
has 'repo-path' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The full path to the master repository to sync to',
    #lazy          => 1,
    #default       => sub { shift->_repo_path },
);

has '_repo_path' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
#    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
#    documentation => 'The full path to the master repository to sync to',
#    lazy          => 1,
#    builder       => '_build_repo_path',
    lazy_build => 1,
);

sub _build__repo_path {
    my $self = shift;

    my $repo_path = Path::Class::Dir->new(
        $self->_repo_dir, $self->_repo_name
    );
    return $repo_path->stringify;
}

around '_repo_path' => sub {
    my $orig = shift;
    my $self = shift;

    # Don't prompt for paths if --repo-path was on the command-line
    return $self->{'repo-path'} if $self->{'repo-path'};
    return $self->$orig(@_);
};

has '_repo_dir' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
#    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
#    documentation => 'The directory name to contain the master '
#                   . 'repository to be created',
#    lazy          => 1,
#    builder       => '_build_repo_dir',
    lazy_build => 1,
);

sub _build__repo_dir {
    my $self = shift;

    # TODO Move to attribute in Command.pm: _home_dir
    my $home_dir = File::HomeDir->my_home;
    my $repo_dir_default = Path::Class::Dir->new(
        $home_dir, 'var', 'git'
    );

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
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
#    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
#    documentation => 'The name of the master repository to create',
#    lazy          => 1,
#    builder       => '_build_repo_name',
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
    #$user_repo_name = Path::Class::Dir->new($user_repo_name);
    #return $user_repo_name->stringify;
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

# XXX Still needed?
has '_other_repo_path' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__other_repo_path {
    my $self = shift;
    my ( $path, $user, $other_user )
        = ( getcwd, $self->_user, $self->{'other-user'} );
    # FIXME
    $path =~ s!^(/(?:home|Users)/)$user!$1$other_user!;

    return $path;
}


has '_git_remote_add_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_remote_add_cmd {
    my $self = shift;

    my $url;
    if (   $self->{'other-user'}
        && $self->{'other-host'}
        && $self->_other_repo_path )
    {
        # XXX Still needed?
        $url = sprintf q{%s@%s:%s},
            $self->{'other-user'},
            $self->{'other-host'},
            $self->_other_repo_path;
    }
    else {
        $url = $self->_repo_path;
    }

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
    if ( $self->{'repo-path'} ) {
    #if ( $self->_is_repo_path_supplied ) {
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

    my $repo_path = Path::Class::Dir->new(
        $self->_repo_path
    );

    unless ( $self->{'dry-run'} ) {
        $repo_path->mkpath unless -d $repo_path->stringify;
    }

    unless ( $self->{'dry-run'} ) {
        $CWD = $repo_path->stringify;
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
