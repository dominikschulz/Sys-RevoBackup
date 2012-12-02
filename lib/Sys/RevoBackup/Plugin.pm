package Sys::RevoBackup::Plugin;
# ABSTRACT: baseclass for any revobackup plugin

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
# has ...
has 'parent' => (
    'is'    => 'rw',
    'isa'   => 'Sys::RevoBackup',
    'required' => 1,
);

has 'priority' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'lazy'  => 1,
    'builder' => '_init_priority',
);
# with ...
with qw(Log::Tree::RequiredLogger Config::Yak::RequiredConfig);
# initializers ...
sub _init_priority { return 0; }
# your code here ...
sub run_config_hook { return; }
sub run_prepare_hook { return; }
sub run_cleanup_hook { return; }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Sys::RevoBackup::Plugin - Baseclass for any RevoBackup plugin.

=method run_cleanup_hook

Run after the backup is finished.

=method run_config_hook

Run to configure all backups jobs. May supply additional backup jobs.

=method run_prepare_hook

Run before the backups are made but after the config hook was run.

=cut
