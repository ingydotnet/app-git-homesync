use strict;
use warnings;

use Test::More;

check_actions( { actions => ['config'] } );

#check_actions(
#    {   actions => [ 'init', 'remote-add', 'make-master', 'remote-fix', ],
#        options => [
#            '--dry-run',                  '--other-user=tommy',
#            '--other-host=192.168.1.102', '--other-hostname=teebox',
#        ]
#    },
#);

# TODO Use Path::Class?
sub program_path {'./bin/git-home-sync'}

sub regexes {
    my $choice = shift;
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
    return $regexes->{$choice};
}

sub check_actions {
    my $args    = shift;
    my @actions = @{ $args->{actions} };
    my @options = $args->{options} ? @{ $args->{options} } : ();

    my $program_path = program_path();

    foreach my $action ( @actions ) {
        my $cmd = join q{ },
            $program_path,
            @options,
            $action;

        my @given_output = qx{$cmd 2>&1}; # (Get STDERR also)
        chomp $_ for @given_output; # Remove the newline from the command

        my $regexes = regexes($action);
        for ( my $i = 0; $i < @given_output; $i++ ) {
            my $line  = $given_output[$i];
            my $regex = $regexes->[$i];
            like $line, $regex, qq{Correct command for "$action" action};
        }
    }
}

done_testing;
