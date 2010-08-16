package Git::HomeSync::Util;

sub run_cmd {
    my ( $class, $args ) = @_;
    die 'No command was specified'
        unless $args->{cmd};

    if ( $args->{dry_run} || $args->{debug} ) {
        printf STDERR qq{\$ %s\n}, $args->{cmd};
    }
#    system($cmd) unless $args->{dry_run};
}

1;
