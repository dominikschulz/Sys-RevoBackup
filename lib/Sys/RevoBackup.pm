package Sys::RevoBackup;

# ABSTRACT: an rsync-based backup script

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
use English qw( -no_match_vars );
use Try::Tiny;

use Sys::Run;
use Sys::FS;
use Job::Manager;
use Sys::RevoBackup::Job;

extends 'Sys::Bprsync' => { -version => 0.17 };

has 'bank' => (
  'is'       => 'ro',
  'isa'      => 'Str',
  'required' => 1,
);

has 'sys' => (
  'is'      => 'rw',
  'isa'     => 'Sys::Run',
  'lazy'    => 1,
  'builder' => '_init_sys',
);

has 'job_filter' => (
  'is'      => 'rw',
  'isa'     => 'Str',
  'default' => '',
);

has 'fs' => (
  'is'      => 'rw',
  'isa'     => 'Sys::FS',
  'lazy'    => 1,
  'builder' => '_init_fs',
);

sub _init_fs {
  my $self = shift;

  my $FS = Sys::FS::->new(
    {
      'logger' => $self->logger(),
      'sys'    => $self->sys(),
    }
  );

  return $FS;
} ## end sub _init_fs

with qw(Config::Yak::OrderedPlugins);

sub _plugin_base_class { return 'Sys::RevoBackup::Plugin'; }

sub _init_sys {
  my $self = shift;

  my $Sys = Sys::Run::->new(
    {
      'logger'            => $self->logger(),
      'ssh_hostkey_check' => 0,
    }
  );

  return $Sys;
} ## end sub _init_sys

sub _init_config_prefix {
  return 'Sys::RevoBackup';
}

sub _init_jobs {
  my $self = shift;

  my $JQ = Job::Manager::->new(
    {
      'logger'      => $self->logger(),
      'concurrency' => $self->concurrency(),
    }
  );

  my $verbose = $self->config()->get( $self->config_prefix() . '::Verbose' ) ? 1 : 0;
  my $dry     = $self->config()->get( $self->config_prefix() . '::Dry' )     ? 1 : 0;

VAULT: foreach my $job_name ( @{ $self->vaults() } ) {
    if ( $self->job_filter() && $job_name ne $self->job_filter() ) {

      # skip this job if it doesn't match the job filter
      $self->logger()->log( message => 'Skipping Job ' . $job_name . ' because it does not match the filter', level => 'debug', );
      next VAULT;
    } ## end if ( $self->job_filter...)
    try {
      my $Job = Sys::RevoBackup::Job::->new(
        {
          'parent'  => $self,
          'name'    => $job_name,
          'verbose' => $verbose,
          'logger'  => $self->logger(),
          'config'  => $self->config(),
          'bank'    => $self->bank(),
          'dry'     => $dry,
        }
      );
      $JQ->add($Job);
    } ## end try
    catch {
      $self->logger()->log( message => 'caught error: ' . $_, level => 'error', );
    };
  } ## end VAULT: foreach my $job_name ( @{ $self...})

  return $JQ;
} ## end sub _init_jobs

sub _job_prefix { return 'Vaults'; }

=method vaults

Return the list of vaults as an array ref.

=cut
sub vaults {
  my $self = shift;

  return [ $self->config()->get_array( $self->config_prefix() . '::' . $self->_job_prefix() ) ];
}

=method create_rotator

Create a new Sys::RotateBackup instance for the given vault.

=cut
sub create_rotator {
  my $self = shift;
  my $vault = shift;

  my $arg_ref = {
    'logger'  => $self->logger(),
    'sys'     => $self->sys(),
    'vault'   => $self->fs()->filename( ( $self->bank(), $vault ) ),
    'daily'   => $self->config()->get( 'RevoBackup::Rotations::Daily', { Default => 10, } ),
    'weekly'  => $self->config()->get( 'RevoBackup::Rotations::Weekly', { Default => 4, } ),
    'monthly' => $self->config()->get( 'RevoBackup::Rotations::Monthly', { Default => 12, } ),
    'yearly'  => $self->config()->get( 'RevoBackup::Rotations::Yearly', { Default => 10, } ),
  };

  my $common_prefix = $self->parent()->config_prefix() . q{::} . $self->_job_prefix() . q{::} . $vault . q{::};

  if ( $self->config()->get( $common_prefix . 'Rotations' ) ) {
    $arg_ref->{'daily'}   = $self->config()->get( $common_prefix . 'Rotations::Daily',   { Default => 10, } );
    $arg_ref->{'weekly'}  = $self->config()->get( $common_prefix . 'Rotations::Weekly',  { Default => 4, } );
    $arg_ref->{'monthly'} = $self->config()->get( $common_prefix . 'Rotations::Monthly', { Default => 12, } );
    $arg_ref->{'yearly'}  = $self->config()->get( $common_prefix . 'Rotations::Yearly',  { Default => 10, } );
  }

  return Sys::RotateBackup::->new($arg_ref);
}

sub run {
  my $self = shift;

  foreach my $Plugin ( @{ $self->plugins() } ) {
    try {
      $Plugin->run_config_hook();
    }
    catch {
      $self->logger()->log( message => 'Failed to run config hook of plugin ' . ref($Plugin) . ' w/ error: ' . $_, level => 'error', );
    };
  } ## end foreach my $Plugin ( @{ $self...})

  foreach my $Plugin ( @{ $self->plugins() } ) {
    try {
      $Plugin->run_prepare_hook();
    }
    catch {
      $self->logger()->log( message => 'Failed to run prepare hook of plugin ' . ref($Plugin) . ' w/ error: ' . $_, level => 'error', );
    };
  } ## end foreach my $Plugin ( @{ $self...})

  if ( !$self->_exec_pre() ) {
    $self->_cleanup(0);
  }
  if ( $self->jobs()->run() ) {
    $self->_cleanup(1);
    $self->_exec_post();
    return 1;
  }
  else {
    return;
  }
} ## end sub run

sub _cleanup {
  my $self = shift;
  my $ok   = shift;

  foreach my $Plugin ( @{ $self->plugins() } ) {
    try {
      $Plugin->run_cleanup_hook($ok);
    }
    catch {
      $self->logger()->log( message => 'Failed to run cleanup hook of plugin ' . ref($Plugin) . ' w/ error: ' . $_, level => 'error', );
    };
  } ## end foreach my $Plugin ( @{ $self...})

  return 1;
} ## end sub _cleanup

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 CONFIGURATION

Place the configuration inside /etc/revobackup/revobackup.conf

    <Sys>
        <RevoBackup>
            bank = /srv/backup/bank
            <Rotations>
                    daily = 10
                    weekly = 4
                    monthly = 12
                    yearly = 10
            </Rotations>
            <Vaults>
                    <test001>
                            source = /home/
                            description = Uhm
                            hardlink = 1
                            nocrossfs = 1
                    </test001>
                    <anotherhost>
                            source = anotherhost:/
                            description = Backup anotherhost
                    </anotherhost>
            </Vaults>
        </RevoBackup>
    </Sys>

=head1 NAME

Sys::RevoBackup - Rsync based backup script

=method run

Run the backups.

=cut
