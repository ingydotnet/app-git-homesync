package App::Git::HomeSync::Command;
use Moose;
use namespace::autoclean;

use App::Git::HomeSync::Util;
use App::Cmd::Setup -command;

use Sys::Hostname qw(hostname);

has 'user' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => $ENV{USER},
);

has 'hostname' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => hostname, # Luckily, there is no namespace
                          # conflict for "hostname" when using this
                          # Moose attribute
);

sub opt_spec {
    return (
        [ 'debug',   'Print the commands as they are executed' ],
        [ 'dry-run', 'Only print the commands' ],
    );
}

## FIXME With straight-up App::Cmd, this attributes don't play nice with
## opt_spec().  Maybe MooseX::App::Cmd will help me do what I want.
#has '_git_config_cmd' => (
#    isa     => 'Str',
#    is      => 'ro',
#    builder => '_build__git_config_cmd',
#);

#sub _build__git_config_cmd {
#    return (
#        sprintf q{git config --replace-all user.name '%s@%s'},
#        $self->user, $self->hostname
#    );
#}

#sub validate_args {
#    my ( $self, $opt, $args ) = @_;
#    die 'BLEH!' if $opt->{blah};
##    $self->validate( $opt, $args );
#}

__PACKAGE__->meta->make_immutable;

1;
