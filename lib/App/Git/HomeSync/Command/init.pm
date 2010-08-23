package App::Git::HomeSync::Command::init;
use App::Git::HomeSync -command;

sub abstract {
    q{Do a 'git init', then ACTIONs: config, remote-add, make-master}
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # TODO Do a --allow-empty commit if possible
    App::Git::HomeSync::Util->run_cmd(
        {   dry_run => $opt->{dry_run},
            debug   => $opt->{debug},
            cmd     => q{git init},
        }
    );
}

1;
