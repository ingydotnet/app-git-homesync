##
# name:      App::Git::HomeSync
# abstract:  Sync your home directories via Git
# author:    Tommy Stanton <tommystanton@gmail.com>
# license:   perl
# copyright: 2011
# see:
# - App::AYCABTU

use v5.10;

package App::Git::HomeSync;
use Mouse;
use namespace::autoclean;

our $VERSION = '0.01';

use App::Cmd::Tester 0.311 ();
use Archive::Extract 0.52 ();
use autodie 2.10 ();
use Carp 1.11 ();
use Cwd 3.33 ();
use Data::Section 0.101621 ();
use DateTime 0.70 ();
use ExtUtils::MakeMaker 6.56 ();
use File::chdir 0.1004 ();
use File::Copy 2.14 ();
use File::HomeDir 0.97 ();
use File::Path 2.08 ();
use Git::PurePerl 0.47 ();
use IO::All 0.41 ();
use IO::Prompter 0.001001 ();
use IPC::System::Simple 1.21 ();
use Lingua::EN::Numbers::Ordinate 1.02 ();
use List::MoreUtils 0.32 ();
use Mouse 0.93 ();
use MouseX::App::Cmd 0.08 ();
use MouseX::App::Cmd::Command 0.08 ();
use MouseX::Types::Path::Class 0.06 ();
use namespace::autoclean 0.12 ();
use Path::Class 0.24 ();
use Path::Class::Dir 0.24 ();
use Readonly 1.03 ();
use Sys::Hostname 1.11 ();
use Test::More 0.98 ();
use Want 0.18 ();

extends qw(MouseX::App::Cmd);

__PACKAGE__->meta->make_immutable;

1;
