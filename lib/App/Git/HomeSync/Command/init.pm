package App::Git::HomeSync::Command::init;
use Moose;
use namespace::autoclean;

extends qw(App::Git::HomeSync::Command);

use File::chdir qw( $CWD );
use IO::Prompter;
use File::HomeDir ();
use Path::Class::Dir ();
use IO::All qw(io);
# XXX Needed?
use autodie qw(:io);

sub abstract {
    q{Supply the --central-repo option to sync directly}
}

has 'central-repo' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The full path to the central repository to sync to',
);

has '_central_repo' => (
    isa        => 'Str',
    is         => 'rw',
    required   => 0,
    lazy_build => 1,
);

sub _build__central_repo {
    my $self = shift;

    my $central_repo = Path::Class::Dir->new(
        $self->_repo_dir, $self->_repo_name
    );
    return $central_repo->stringify;
}

around '_central_repo' => sub {
    my $orig = shift;
    my $self = shift;

    # Don't prompt for paths if --central-repo was on the command-line
    return $self->{'central-repo'} if $self->{'central-repo'};
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
        (   sprintf q{Where shall we create the central repository? [%s]},
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
        (   sprintf q{What do you want to name the central repository? [%s]},
            $repo_name_default
        ),
        -in => *STDIN,
        -timeout => 30,
        -verbatim,
        -default => $repo_name_default,
    );
    return $user_repo_name;
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
    if ( $self->{'central-repo'} ) {
        $self->_sync_with_central_repo();
    }
    # Create the repo (and thereby the path)
    else {
        $self->_initialize_central_repo_and_sync();
    }
}

sub _sync_with_central_repo {
    my $self = shift;

    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds => [
                map { $self->$_ }
                qw( _git_init_cmd
                    _git_config_user_cmd
                    _git_remote_add_cmd
                    _git_fetch_cmd
                    _git_branch_cmd )
            ],
        }
    );

    $self->_move_aside_conflicting_files;

    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds => [
                map { $self->$_ }
                qw( _git_checkout_cmd
                    _git_config_branch_remote_cmd
                    _git_config_branch_merge_cmd )
            ],
        }
    );
}

sub _initialize_central_repo_and_sync {
    my $self = shift;

    my $orig_path = Path::Class::Dir->new();

    my $central_repo = Path::Class::Dir->new(
        $self->_central_repo
    );

    unless ( $self->{'dry-run'} ) {
        $central_repo->mkpath unless -d $central_repo->stringify;
    }

    unless ( $self->{'dry-run'} ) {
        $CWD = $central_repo->stringify;
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
    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds    => [
                map { $self->$_ }
                qw( _git_init_cmd
                    _git_config_user_cmd
                    _git_remote_add_cmd
                    _git_fetch_cmd
                    _git_branch_cmd )
            ],
        }
    );

    $self->_move_aside_conflicting_files;

    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds    => [
                map { $self->$_ }
                # TODO Add more diagnostics if the --allow-empty commit
                # autodies
                qw( _git_checkout_cmd
                    _git_config_branch_remote_cmd
                    _git_config_branch_merge_cmd
                    _git_commit_empty_cmd )
            ],
        }
    );

    my $gitignore_text = App::Git::HomeSync::Util->get_gitignore;
    io('.gitignore')->print($gitignore_text)
        if not $self->{'dry-run'};
    # TODO git add and git commit of .gitignore

    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds    => [
                map { $self->$_ }
                qw( _git_push_cmd )
            ],
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
