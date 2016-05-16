#!/usr/bin/perl
# ABSTRACT: cron scheduler
# PODNAME: cron.pl
use strict;
use warnings;

use Schedule::Cron;

my $crontab = $ENV{'CRONTAB'} || 'conf/schedule.cron';
my $bin = $ENV{'REVOBACKUP_BIN'} || 'bin/revobackup.pl';

my $cron = Schedule::Cron::->new(\&dispatcher);
$cron->load_crontab($crontab);
print "Starting RevoBackup Cron Wrapper ...\n";
$cron->run(detach => 0);

sub dispatcher {
  my $job = shift;
  my @args = @_;

  print "Cron - $job - @args\n";
  my $cmd = $bin . " " . $job;
  my $rv = system($cmd) >> 8;
  if ($rv != 0) {
    print "ERROR: $cmd exited with error: $rv\n";
  }
}

__END__

=head1 NAME

revobackup - rsync based backup

=cut
