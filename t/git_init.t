#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Archive::Extract ();

#use App::Cmd::Tester qw(test_app);
#use App::Git::HomeSync;

#use Git::PurePerl ();
use Path::Class ();
use File::Path qw( remove_tree );
use File::chdir qw( $CWD );
use autodie qw(:all);
use Readonly;

Readonly my $central_repo_dir_name => 'repository_remote-bare';
Readonly my $central_repo_tarball_name =>
    ( sprintf '%s.tar.gz', $central_repo_dir_name );

Readonly my $home_dir_name => 'HOME';
Readonly my $home_tarball_name =>
    ( sprintf '%s.tar.gz', $home_dir_name );

Readonly my $var_dir              => Path::Class::Dir->new(qw( t var ));
Readonly my $var_home_dir         => $var_dir->subdir($home_dir_name);
Readonly my $var_central_repo_dir => $var_dir->subdir($central_repo_dir_name);

=begin comment

(w/ --central-repo option)
[X] Get a bare central repo created, automatically
[X] Get a home directory created
    - Make sure that
        - It is a git repo
        - New expected files are now there
[ ] Sync to the central repo
    - Make sure that
        [X] It is a git repo
        [X] .gitignore exists
        [X] Conflicting files were moved aside
        [ ] git status is sound

(w/o --central-repo option)
[ ] Get a bare central repo created, manually
    - Update timeout to be faster
[X] Get a home directory created
[ ] Sync to the central repo
    - Make sure that
        [ ] It is a git repo
        [ ] .gitignore exists
        [ ] Conflicting files were moved aside
        [ ] git status is sound

=end comment

=cut

# (Might not be needed, thanks to "make clean" from Makefile.PL)
remove_tree( $var_home_dir->stringify )
    if -d $var_home_dir->stringify;
remove_tree( $var_central_repo_dir->stringify )
    if -d $var_central_repo_dir->stringify;

extract_home_dir();
run_init();

{
    local $CWD = $var_home_dir->stringify;
    my $working_dir = Path::Class::Dir->new;

    my @files = $working_dir->children;
    my @filenames = map { $_->stringify } @files;

    subtest 'New files from git' => sub {
        foreach my $filename (qw( .gitignore .emacs .vimrc )) {
            ok -f $filename, "$filename now exists";
        }

        done_testing;
    };

    my @moved_aside_files = grep /\.bash.+\.bak/, @filenames;
    cmp_ok( scalar @moved_aside_files, '==', 2,
        '2 bash files were moved aside' );
}

done_testing;

sub extract_home_dir {
    local $CWD = $var_dir->stringify;
    my $fixture_dir = Path::Class::Dir->new(
        '..', 'fixture',
    );
    my $home_tarball =
        $fixture_dir->subdir($home_tarball_name)->stringify;
    my $central_repo_tarball =
        $fixture_dir->subdir($central_repo_tarball_name)->stringify;

    foreach my $tarball ( $home_tarball, $central_repo_tarball ) {
        Archive::Extract->new(
            archive => $tarball,
            type    => 'tgz',
        )->extract;
    }
}

sub run_init {
    local $CWD = $var_home_dir->stringify;
    my $central_repo = Path::Class::Dir->new(
        '..', $central_repo_dir_name,
    )->stringify;

    my $action = 'init';
    my @options =(
        #0 ? '--debug' : '--dry-run',
        '--nodebug',
        qq{--central-repo="$central_repo"}
    );

    # FIXME This likely isn't portable
    my $cmd = join q{ },
        '../../../bin/git-home-sync',
        $action,
        @options,
        '2>/dev/null';
    diag qq{Running command: "$cmd"...};
    system $cmd;

    #my $result = test_app( 'App::Git::HomeSync' => [ $action, @options ] );
    #return $result;
}

