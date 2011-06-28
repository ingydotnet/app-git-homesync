package App::Git::HomeSync;
use Mouse;
use namespace::autoclean;

# ABSTRACT: Sync your home directories via Git

extends qw(MouseX::App::Cmd);

__PACKAGE__->meta->make_immutable;

1;
