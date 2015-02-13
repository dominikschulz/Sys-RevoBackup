package Sys::RevoBackup::Cmd::Command::backupcheck;

# ABSTRACT: backup integrity check command

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
use Sys::RevoBackup::Utils;

# extends ...
extends 'Sys::RevoBackup::Cmd::Command';

# has ...
has 'host' => (
  'is'            => 'ro',
  'isa'           => 'Bool',
  'required'      => 1,
  'default'       => 0,
  'traits'        => [qw(Getopt)],
  'cmd_aliases'   => 'h',
  'documentation' => 'Host to check',
);

# with ...
# initializers ...

# your code here ...
sub execute {
  my $self = shift;

  # Helper method for monitoring, just look up the last status to the given hostname
  if ( Sys::RevoBackup::Utils::backup_status( $self->config(), $self->host() ) ) {
    print "1\n";
    return 1;
  }
  print "0\n";
  return 1;
} ## end sub execute

sub abstract {
  return 'Check backup integrity';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Sys::RevoBackup::Cmd::Command::backupcheck - check the backup integrity

=method abstract

Workaround.

=method execute

Check the backup.

=cut
