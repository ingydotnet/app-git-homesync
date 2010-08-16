package Git::HomeSync::Util;
use Carp qw(croak);

sub run_cmd {
    my ( $class, $args ) = @_;
    croak 'No command was specified'
        unless $args->{cmd};

    if ( $args->{dry_run} || $args->{debug} ) {
        printf STDERR qq{\$ %s\n}, $args->{cmd};
    }
#    system($cmd) unless $args->{dry_run};
}

1;
