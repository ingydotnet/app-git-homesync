#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use App::Cmd::Tester qw(test_app);
use List::MoreUtils qw(any);

use App::Git::HomeSync;

check_actions(
    {   actions => ['init'],
        options => {
            'dry-run'      => undef,
            'central-repo' => '/tmp/bleh.git',
        },
    },
);

check_actions(
    {   actions => ['init'],
        options => { 'dry-run' => undef, },
    },
);

check_actions(
    {   actions => ['config'],
        options => { 'dry-run' => undef }
    },
);

sub check_actions {
    my $args         = shift;
    my @actions      = @{ $args->{actions} };
    my %option_pairs = %{ $args->{options} };
    my @options      = @{ _prepare_options( $args->{options} ) };

    foreach my $action ( @actions ) {
        my $result = test_app( 'App::Git::HomeSync' => [ $action, @options ] );

        my $given_output = $result->output;
        chomp $given_output; # Remove newline
        diag "OUTPUT:\n$given_output";
        my @given_output = split /\n/, $given_output;

        my $regexes = _get_regexes(
            {   action       => $action,
                option_pairs => \%option_pairs,
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

sub _get_regexes {
    my $opts         = shift;
    my $action       = $opts->{action};
    my %option_pairs = %{ $opts->{option_pairs} };

    my $has_central_repo
        = any { $_ eq 'central-repo' } keys %option_pairs;
    my $regexes = {
        (   'init' => $has_central_repo ?

            [ qr|^\$ git init|,
              qr|^\$ git config|,
              qr|^\$ git remote add .+bleh|,
              qr|^\$ git fetch|,
              qr|^\$ git branch|,
              qr|^\$ git checkout|,
              qr|^\$ git config|,
              qr|^\$ git config|, ]
              # TODO commit, push?

          : [ qr|^\$ git init --bare|,
              qr|^\$ git init|,
              qr|^\$ git config|,
              qr|^\$ git remote add .+var/git/|, # XXX Default contains
                                                 # "var" and "git"
              qr|^\$ git fetch|,
              qr|^\$ git branch|,
              qr|^\$ git checkout|,
              qr|^\$ git config|,
              qr|^\$ git config|,
              qr|^\$ git commit|,
              qr|^\$ git push|, ]
        ),
        'config' => [qr|^\$ git config|],
    };

    return $regexes->{$action};
}

sub _prepare_options {
    my $option_pairs = shift;

    # Prepend dashes to options for the command-line
    my @options;
    foreach my $option_name (keys %$option_pairs) {
        my $option_value = $option_pairs->{$option_name};

        my $option = "--$option_name";
        $option .= sprintf '=%s', $option_value
            if $option_value;

        push @options, $option;
    }

    return \@options;
}

done_testing;
