package App::Git::HomeSync::Command;
use Moose;
use namespace::autoclean;

extends qw(MooseX::App::Cmd::Command);

use App::Git::HomeSync::Util;

use MooseX::Types::Path::Class;
use Sys::Hostname qw(hostname);
use DateTime;
use Cwd qw(getcwd);
use Git::PurePerl ();
use File::Copy qw(move);

has 'debug' => (
    isa           => 'Bool',
    is            => 'rw',
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    cmd_aliases   => 'd',
    # XXX Use --nodebug to disable output
    default       => 1,
    documentation => 'Print the commands as they are executed',
);

has 'dry-run' => (
    isa           => 'Bool',
    is            => 'rw',
    traits        => ['MooseX::Getopt::Meta::Attribute::Trait'],
    documentation => 'Only print the commands',
);

has '_user' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    # TODO Use getlogin() Perl built-in?
    default  => $ENV{USER},
);

has '_hostname' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => hostname,
);

has '_home_dir' => (
    is         => 'ro',
    isa        => 'Path::Class::Dir',
    required   => 1,
    coerce     => 1,
    lazy_build => 1,
);

sub _build__home_dir {
    my $home_dir = File::HomeDir->my_home;
    return $home_dir;
}

has '_cwd' => (
    is         => 'ro',
    isa        => 'Path::Class::Dir',
    required   => 1,
    coerce     => 1,
    lazy_build => 1,
);

sub _build__cwd {
    my $cwd = getcwd;
    return $cwd;
}

has '_git_obj' => (
    is         => 'ro',
    isa        => 'Git::PurePerl',
    required   => 0,
    lazy_build => 1,
);

sub _build__git_obj {
    my $self = shift;

    my $cwd = $self->_cwd;
    my $git = Git::PurePerl->new(
        directory => $cwd->stringify
    );

    return $git;
}

has '_git_init_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_init_cmd {
    return q{git init};
}

has '_git_init_bare_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_init_bare_cmd {
    return q{git init --bare};
}

has '_git_config_user_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_config_user_cmd {
    my $self = shift;
    return (
        sprintf q{git config --replace-all user.name '%s@%s'},
        $self->_user, $self->_hostname
    );
}

has '_git_config_branch_remote_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_config_branch_remote_cmd {
    my $self = shift;
    return (
        sprintf q{git config --replace-all branch.master.remote %s},
        $self->_remote_branch_name
    );
}

has '_git_config_branch_merge_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_config_branch_merge_cmd {
    my $self = shift;

    my $ref = sprintf 'refs/heads/%s', 'master';
    return
        qq{git config --replace-all branch.master.merge $ref};
}

has '_git_commit_empty_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_commit_empty_cmd {
    return q{git commit --allow-empty -m 'First commit (empty)'};
}

has '_git_push_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_push_cmd {
    return q{git push};
}

has '_remote_branch_name' => (
    isa        => 'Str',
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);

sub _build__remote_branch_name {
    return q{origin};
}

has '_git_remote_add_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_remote_add_cmd {
    my $self = shift;

    my $url = $self->_central_repo;

    my $remote_add_cmd = sprintf q{git remote add %s '%s'},
        $self->_remote_branch_name,
        $url;
    return $remote_add_cmd;
}

has '_git_fetch_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_fetch_cmd {
    my $self = shift;

    return (
        sprintf q{git fetch %s},
        $self->_remote_branch_name
    );
}

has '_git_branch_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_branch_cmd {
    my $self = shift;
    return (
        sprintf q{git branch master %s/master},
        $self->_remote_branch_name
    );
}

has '_git_checkout_cmd' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

sub _build__git_checkout_cmd {
    return q{git checkout master .};
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    die $self->_usage_text if $self->help_flag;
    $self->validate( $opt, $args );
}

sub _move_aside_conflicting_files {
    my $self = shift;
    return 0 if $self->{'dry-run'};

    my $remote_branch_ref =
        sprintf 'refs/remotes/%s/master',
        $self->_remote_branch_name;

    my $git = $self->_git_obj;

    my $remote_branch_sha1 = $git->ref_sha1($remote_branch_ref);
    my $remote_branch_obj  = $git->get_object($remote_branch_sha1);
    my $remote_file_objs   = $remote_branch_obj->tree->directory_entries;

    my @awaiting_remote_files =
        map { $_->{filename} } @$remote_file_objs;
    die 'Could not get a list of files in the repository'
        if not scalar @awaiting_remote_files and not $self->{'dry-run'};

    if ( @awaiting_remote_files and not $self->{'dry-run'} ) {
        foreach my $file (@awaiting_remote_files) {
            if ( -f $file || -d $file ) {
                # TODO Try MooseX::Types::DateTime
                my $dt   = DateTime->today->set_time_zone('local');
                my $date = $dt->strftime('%Y%m%d');

                my ( $old_filename, $new_filename ) =
                    ( $file, ( sprintf '%s.bak%s', $file, $date ) );
                move( $old_filename, $new_filename );

                print STDERR qq{# "$old_filename" --> "$new_filename"\n}
                    if $self->{debug};
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
