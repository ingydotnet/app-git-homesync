package App::Git::HomeSync::Command::config;
use Mouse;
use namespace::autoclean;

extends qw(App::Git::HomeSync::Command);

sub abstract { q{Update user.name to CURRENT_USER@CURRENT_HOSTNAME} }

sub validate {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('No arguments are expected') if @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    App::Git::HomeSync::Util->run_cmds(
        {   dry_run => $self->{'dry-run'},
            debug   => $self->{debug},
            cmds    => [ $self->_git_config_user_cmd, ],
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
