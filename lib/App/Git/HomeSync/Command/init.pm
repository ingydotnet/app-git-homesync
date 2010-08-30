package App::Git::HomeSync::Command::init;
use Moose;
use namespace::autoclean;

extends qw(App::Git::HomeSync::Command);

sub abstract {
    q{Do a 'git init', then ACTIONs: config, remote-add, make-master}
}

use Cwd qw(getcwd);

has 'other-user' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 1,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The user of the other box that you want to sync '
                   . 'with',
);

has 'other-host' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 1,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The address of the other box that you want to '
                   . 'sync with',
);

has 'other-hostname' => (
    isa           => 'Str',
    is            => 'rw',
    required      => 0,
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'The hostname of the other box that you want to '
                   . 'sync with',
);

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

has '_other_repos_path' => (
    isa        => 'Str',
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);

sub _build__other_repos_path {
    my $self = shift;
    my ( $path, $user, $other_user )
        = ( getcwd, $self->_user, $self->{'other-user'} );
    # FIXME
    $path =~ s!^(/(?:home|Users)/)$user!$1$other_user!;

    return $path
}


has '_git_remote_add_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_remote_add_cmd {
    my $self = shift;
    return (
        sprintf qq{git remote add %s '%s@%s:%s'},
        $self->_remote_branch_name,
        $self->{'other-user'},
        $self->{'other-host'},
        $self->_other_repos_path
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('No arguments are expected') if @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # TODO Do a --allow-empty commit if possible
    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds => [
                map { $self->$_ }
                qw( _git_init_cmd
                    _git_config_cmd
                    _git_remote_add_cmd
                    _git_fetch_cmd
                    _git_branch_cmd )
            ],
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
