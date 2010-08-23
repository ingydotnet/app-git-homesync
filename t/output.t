use strict;
use warnings;

use Test::More;
use App::Cmd::Tester;

use Git::HomeSync;

check_actions( { actions => ['config'] } );

#check_actions(
#    {   actions => [ 'init', 'remote-add', 'make-master', 'remote-fix', ],
#        options => [
#            '--dry-run',                  '--other-user=tommy',
#            '--other-host=192.168.1.102', '--other-hostname=teebox',
#        ]
#    },
#);

sub regexes {
    my $action = shift;
    my $regexes = {
        'init' => [
            qr/^\$ git init/,
            qr/^\$ git config/,
            qr/^\$ git remote/,
            qr/^\$ git fetch/,
            qr/^# Creating/,
            qr/^\$ git branch/,
            qr/^\$ git checkout/,
        ],
        'config'     => [qr/^\$ git config/],
        'remote-add' => [ qr/^\$ git remote/, qr/^\$ git fetch/, ],
        'make-master' =>
            [ qr/^# Creating/, qr/^\$ git branch/, qr/^\$ git checkout/, ],
        'remote-fix' => [
            qr/^\$ git remote/,
            qr/^\$ git fetch/,
            qr/^# Deleting/,
            qr/^\$ git branch/,
            qr/^\$ git config/,
            qr/^\$ rm/,
        ],
    };
    return $regexes->{$action};
}

sub check_actions {
    my $args    = shift;
    my @actions = @{ $args->{actions} };
    my @options = $args->{options} ? @{ $args->{options} } : ();

    foreach my $action ( @actions ) {
        my $result = test_app( 'Git::HomeSync' => [ @options, $action ] );

        my $given_output = $result->output;
        chomp $given_output; # Remove newline
        my @given_output = split /\n/, $given_output;

        my $regexes = regexes($action);
        for ( my $i = 0; $i < @given_output; $i++ ) {
            my $line  = $given_output[$i];
            my $regex = $regexes->[$i];
            like $line, $regex, qq{Correct command for "$action" action};
        }
    }
}

done_testing;
