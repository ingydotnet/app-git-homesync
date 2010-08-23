package App::Git::HomeSync::Command::config;
use App::Git::HomeSync -command;

sub abstract { q{Update user.name to CURRENT_USER@CURRENT_HOSTNAME} }

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('No arguments are expected') if @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    App::Git::HomeSync::Util->run_cmd(
        {   dry_run => $opt->{dry_run},
            debug   => $opt->{debug},
            cmd     => q{git config #...},#$self->_git_config_cmd,
        }
    );
}

1;
