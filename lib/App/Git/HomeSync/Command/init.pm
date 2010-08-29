package App::Git::HomeSync::Command::init;
use Moose;
use namespace::autoclean;

extends qw(App::Git::HomeSync::Command);

sub abstract {
    q{Do a 'git init', then ACTIONs: config, remote-add, make-master}
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('No arguments are expected') if @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # TODO Do a --allow-empty commit if possible
    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds    => [ $self->_git_init_cmd ],
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
