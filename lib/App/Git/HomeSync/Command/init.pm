package App::Git::HomeSync::Command::init;
use Moose;
use namespace::autoclean;

extends qw(MooseX::App::Cmd::Command);

sub abstract {
    q{Do a 'git init', then ACTIONs: config, remote-add, make-master}
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # TODO Do a --allow-empty commit if possible
    App::Git::HomeSync::Util->run_cmd(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmd     => q{git init},
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
