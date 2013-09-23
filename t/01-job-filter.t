#!perl -T

use Test::More tests => 2;
use Sys::RevoBackup;
use Config::Yak;
use Test::MockObject::Universal;
use File::Temp qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1 );

my $MO = Test::MockObject::Universal::->new();
my $Cfg = Config::Yak::->new({
  'locations' => [],
});
$Cfg->set('Sys::RevoBackup::Verbose',0);
$Cfg->set('Sys::RevoBackup::Dry',1);
$Cfg->set('Sys::RevoBackup::Vaults::Apple',1);
$Cfg->set('Sys::RevoBackup::Vaults::Bananas',1);
my $Revo = Sys::RevoBackup::->new(
  {
    'config'    => $Cfg,
    'logger'    => $MO,
    'logfile'   => $tempdir.'/log',
    'bank'      => $tempdir,
    'concurrency' => 1,
    'job_filter' => 'bananas',
  }
);

my $Jobs = $Revo->jobs();

is(scalar(@{$Jobs->jobs()}),1,'Job Queue contains exactly one Job');
is($Jobs->jobs()->[0]->{'name'},'bananas','Job Queue contains the correct Job');

