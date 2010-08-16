package Git::HomeSync::Command;
use Moose;
use namespace::autoclean;

use Git::HomeSync::Util;
use App::Cmd::Setup -command;

use Sys::Hostname;

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
    default  => hostname,
);

#sub opt_spec {
#    my ( $class, $app ) = @_;
#    return (
#        'This is the usage description',
#        [ 'blah' => "bleh" ],
##        $class->options($app),
#    )
#}
#
#sub validate_args {
#    my ( $self, $opt, $args ) = @_;
#    die 'BLEH!' if $opt->{blah};
##    $self->validate( $opt, $args );
#}

__PACKAGE__->meta->make_immutable;

1;