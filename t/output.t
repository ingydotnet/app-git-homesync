use strict;
use warnings;

use Test::More;

my $program = '../bin/git-home-sync';

# XXX
my $action = 'config';

my $cmd = join q{ },
    $program,
    '--dry-run',
    '--other-user=tommy',
    '--other-host=192.168.1.102',
    '--other-hostname=teebox',
    $action;

my $output = qx{$cmd 2>&1}; # (Get STDERR also)
chomp $output; # Remove the newline from the command

is(
    $output,
    q{$ git config --replace-all user.name 'tstanton@tmini'},
    qq{Output for "$action" action is correct}
);

done_testing(1);
