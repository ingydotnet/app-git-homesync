package Git::HomeSync::Command;
use Moose;
use namespace::autoclean;

use Git::HomeSync::Util;
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
    # Luckily, there is no namespace conflict for "hostname" when using
    # this Moose attribute
    default  => hostname,
);

sub opt_spec {
    return (
        [ 'dry-run', 'Only print the commands' ],
    );
}

#sub validate_args {
#    my ( $self, $opt, $args ) = @_;
#    die 'BLEH!' if $opt->{blah};
##    $self->validate( $opt, $args );
#}

__PACKAGE__->meta->make_immutable;

1;
