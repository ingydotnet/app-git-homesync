#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use App::Cmd::Tester qw(test_app);

use App::Git::HomeSync;

check_actions(
    {   actions => ['init'],
        options => [
            '--dry-run',
            '--repo-path=/tmp/bleh.git',
            #'--other-user=tommy',
            #'--other-host=192.168.1.102',
            #'--other-hostname=teebox',
        ],
        has_repo_path => 1,
    },
);

check_actions(
    {   actions => ['init'],
        options => [
            '--dry-run',
            #'--other-user=tommy',
            #'--other-host=192.168.1.102',
            #'--other-hostname=teebox',
        ],
    },
);

check_actions(
    {   actions => ['config'],
        options => ['--dry-run']
    },
);

sub check_actions {
    my $args    = shift;
    my @actions = @{ $args->{actions} };
    my @options = $args->{options} ? @{ $args->{options} } : ();

    foreach my $action ( @actions ) {
        my $result = test_app( 'App::Git::HomeSync' => [ $action, @options ] );

        my $given_output = $result->output;
        chomp $given_output; # Remove newline
        diag "OUTPUT:\n$given_output";
        my @given_output = split /\n/, $given_output;

        my $regexes = get_regexes(
            {   action        => $action,
                has_repo_path => $args->{has_repo_path}
            }
        );
        cmp_ok( scalar @given_output, '==', scalar @$regexes,
            sprintf qq{"$action" action executed %s command(s)},
            scalar @$regexes
        ) or next;

        subtest qq{"$action" action commands} => sub {
            for ( my $i = 0; $i < @given_output; $i++ ) {
                my $line  = $given_output[$i];
                my $regex = $regexes->[$i];
                # There should be a regex that matches in sequence with the
                # output
                if ( $regex ) {
                    like $line, $regex, qq{Correct command};
                }
                else {
                    fail qq{Too many lines were printed};
                    last;
                }
            }
            done_testing;
        }
    }
}

sub get_regexes {
    my $opts = shift;
    my $regexes = {
        (   'init' => $opts->{has_repo_path} ?

            [ qr/^\$ git init/,
              qr/^\$ git config/,
              qr/^\$ git remote/,
              qr/^\$ git fetch/,
              qr/^\$ git branch/,
              qr/^\$ git checkout/, ]

          : [ qr/^\$ git init --bare/,
              qr/^\$ git init/,
              qr/^\$ git config/,
              qr/^\$ git remote/,
              qr/^\$ git fetch/,
              qr/^\$ git branch/,
              qr/^\$ git checkout/,
              qr/^\$ git config/,
              qr/^\$ git config/,
              qr/^\$ git commit/,
              qr/^\$ git push/, ]
        ),
        'config' => [qr/^\$ git config/],
    };
    return $regexes->{ $opts->{action} };
}

done_testing;
