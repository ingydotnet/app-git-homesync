package App::Git::HomeSync;
use Moose;
use namespace::autoclean;

# ABSTRACT: Sync your home directories via Git

extends qw(MooseX::App::Cmd);

__PACKAGE__->meta->make_immutable;

1;
