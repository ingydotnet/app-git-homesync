use strict;
use warnings;

use Test::More;
use Test::Differences;

my $program = '../bin/git-home-sync';

# TODO Use JSON or YAML in __DATA__
# ...or use Test::Base or TestML
my %actions = (
    'init'        => undef,
    'config'      => undef,
    'remote-add'  => undef,
    'make-master' => undef,
    'remote-fix'  => undef,
);
chomp ($actions{init} = <<'EOT');
$ git init
$ git config --replace-all user.name 'tstanton@tmini'
$ git remote add teebox 'tommy@192.168.1.102:/home/tommy/bin'
$ git fetch teebox
# Creating a 'master' branch, based off of the remote branch...
$ git branch master teebox/master
$ git checkout master .
EOT
chomp ($actions{config} = <<'EOT');
$ git config --replace-all user.name 'tstanton@tmini'
EOT
chomp ($actions{'remote-add'} = <<'EOT');
$ git remote add teebox 'tommy@192.168.1.102:/home/tommy/bin'
$ git fetch teebox
EOT
chomp ($actions{'make-master'} = <<'EOT');
# Creating a 'master' branch, based off of the remote branch...
$ git branch master teebox/master
$ git checkout master .
EOT
chomp ($actions{'remote-fix'} = <<'EOT');
$ git remote add teebox 'tommy@192.168.1.102:/home/tommy/bin'
$ git fetch teebox
# Deleting the 'origin/master' remote branch...
$ git branch -r -d origin/master
$ git config --remove-section remote.origin
$ rm -R .git/refs/remotes/origin/
EOT

foreach my $action ( keys %actions ) {
    my $cmd = join q{ },
        $program,
        '--dry-run',
        '--other-user=tommy',
        '--other-host=192.168.1.102',
        '--other-hostname=teebox',
        $action;
    my $given_output = qx{$cmd 2>&1}; # (Get STDERR also)
    chomp $given_output; # Remove the newline from the command

    my $expected_output = $actions{$action};
    # TODO Use Test::Deep's re(), so that the tests are flexible (the
    # printed path does not have to be exact) and will pass
    unified_diff;
    eq_or_diff(
        $given_output,
        $expected_output,
        qq{Output for "$action" action is correct}
    );
}

done_testing( scalar keys %actions );
