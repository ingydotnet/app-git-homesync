use strict;
use warnings;

use Test::More;

my $program = '../bin/git-home-sync';

# XXX
my $action = 'config';

# TODO Capture output
system $program,
    '--dry-run',
    '--other-user=tommy',
    '--other-host=192.168.1.102',
    '--other-hostname=teebox',
    $action;

done_testing;
