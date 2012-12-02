#!/usr/bin/perl
# ABSTRACT: rsync based backup script
# PODNAME: revobackup.pl
use strict;
use warnings;

use Sys::RevoBackup::Cmd;

my $Cmd = Sys::RevoBackup::Cmd::->new();
$Cmd->run();

exit 1;

__END__

=head1 NAME

revobackup - rsync based backup

=cut
