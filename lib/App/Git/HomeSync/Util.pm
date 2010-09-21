package App::Git::HomeSync::Util;
use Carp qw(croak);
use autodie qw(:system);
use Data::Section -setup => { inherit => 0 };

sub run_cmds {
    my ( $class, $args ) = @_;
    croak 'No commands were specified'
        unless ref $args->{cmds} eq 'ARRAY';

    foreach my $cmd ( @{ $args->{cmds} } ) {
        if ( $args->{dry_run} || $args->{debug} ) {
            printf STDERR qq{\$ %s\n}, $cmd;
        }
        system($cmd) unless $args->{dry_run};
    }
}

sub get_gitignore {
    my $class = shift;

    my $gitignore      = $class->section_data('gitignore');
    my $gitignore_text = $$gitignore;

    return $gitignore_text;
}

1;

__DATA__
__[ gitignore ]__
# Some of these rules are based on the default .gitignore supplied by
# gibak (http://eigenclass.org/hiki/gibak-backup-system-introduction),
# which were taken from git-home-history
# (http://jean-francois.richard.name/ghh/)

# XXX Ignore everything by default
/*
/.*

# Don't ignore yourself!
!/.gitignore

# Shell
#!/.bashrc
#!/.bash_profile

# Text editors
#!/.emacs
#!/.vimrc

# Bring in empty folder for log files
#!/var/log/.gitignore

# We do not want to track the tracking of other files:
.svn
#CVS

# Some editors use some special backup file formats.  Ignore them:
.#*
*~
# My manual backup files
#*.orig
#*.bak*
