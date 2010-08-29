package App::Git::HomeSync::Util;
use Carp qw(croak);
#use autodie qw(:system);

sub run_cmds {
    my ( $class, $args ) = @_;
    croak 'No commands were specified'
        unless ref $args->{cmds} eq 'ARRAY';

    foreach my $cmd ( @{ $args->{cmds} } ) {
        if ( $args->{dry_run} || $args->{debug} ) {
            printf STDERR qq{\$ %s\n}, $cmd;
        }
        #system($cmd) unless $args->{dry_run};
    }
}

1;
