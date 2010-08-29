package App::Git::HomeSync;
use Moose;
use namespace::autoclean;

extends qw(MooseX::App::Cmd);

__PACKAGE__->meta->make_immutable;

1;
