package Git::HomeSync::Command::config;
use Git::HomeSync -command;

sub abstract { 'Update user.name to CURRENT_USER@CURRENT_HOSTNAME' }

sub opt_spec {
    return (
        [ 'dry-run', 'Only print the commands' ],
    );
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
