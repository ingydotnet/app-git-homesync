use strict;
use warnings;

use Test::More;

# TODO Use Path::Class?
my $program = './bin/git-home-sync';

my %actions = (
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
);

foreach my $action ( keys %actions ) {
    my $cmd = join q{ },
        $program,
        '--dry-run',
        '--other-user=tommy',
        '--other-host=192.168.1.102',
        '--other-hostname=teebox',
        $action;

    my @given_output = qx{$cmd 2>&1}; # (Get STDERR also)
    chomp $_ for @given_output; # Remove the newline from the command

    my @regexes = @{ $actions{$action} };
    for ( my $i = 0; $i < @given_output; $i++ ) {
        my $line  = $given_output[$i];
        my $regex = $regexes[$i];
        like $line, $regex, qq{Correct command for "$action" action};
    }
}

done_testing;
