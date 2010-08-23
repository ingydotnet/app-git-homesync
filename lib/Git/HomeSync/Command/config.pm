package Git::HomeSync::Command::config;
use Git::HomeSync -command;

sub abstract { q{Update user.name to CURRENT_USER@CURRENT_HOSTNAME} }

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('No arguments are expected') if @$args;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $git_config_cmd =
        sprintf q{git config --replace-all user.name '%s@%s'},
        $self->user, $self->hostname;

    Git::HomeSync::Util->run_cmd(
        {   dry_run => $opt->{dry_run},
            cmd     => $git_config_cmd,
        }
    );
}

1;
