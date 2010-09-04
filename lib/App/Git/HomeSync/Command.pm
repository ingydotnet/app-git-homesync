package App::Git::HomeSync::Command;
use Moose;
use namespace::autoclean;

extends qw(MooseX::App::Cmd::Command);

use App::Git::HomeSync::Util;

use Sys::Hostname qw(hostname);

has 'debug' => (
    isa           => 'Bool',
    is            => 'rw',
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    cmd_aliases   => 'd',
    documentation => 'Print the commands as they are executed',
);

has 'dry-run' => (
    isa           => 'Bool',
    is            => 'rw',
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'Only print the commands',
);

has '_user' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => $ENV{USER},
);

has '_hostname' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => hostname,
);


has '_git_init_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    default    => q{git init},
);

has '_git_config_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_config_cmd {
    my $self = shift;
    return (
        sprintf q{git config --replace-all user.name '%s@%s'},
        $self->_user, $self->_hostname
    );
}

has '_git_fetch_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_fetch_cmd {
    my $self = shift;

    return (
        sprintf q{git fetch %s},
        $self->_remote_branch_name
    );
}

has '_git_branch_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_branch_cmd {
    my $self = shift;
    return (
        sprintf q{git branch master %s/master},
        $self->_remote_branch_name
    );
}

has '_git_checkout_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    builder    => '_build__git_checkout_cmd',
);

sub _build__git_checkout_cmd {
    return q{git checkout master .};
}

#sub validate_args {
#    my ( $self, $opt, $args ) = @_;
#    die 'BLEH!' if $opt->{blah};
##    $self->validate( $opt, $args );
#}

__PACKAGE__->meta->make_immutable;

1;
