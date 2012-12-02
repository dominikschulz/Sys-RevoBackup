package Sys::RevoBackup::Cmd::Command::run;
# ABSTRACT: run revobackup

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
use Linux::Pidfile;
use Sys::RevoBackup;

# extends ...
extends 'Sys::RevoBackup::Cmd::Command';
# has ...
has '_pidfile' => (
    'is'    => 'ro',
    'isa'   => 'Linux::Pidfile',
    'lazy'  => 1,
    'builder' => '_init_pidfile',
);
# with ...
# initializers ...
sub _init_pidfile {
    my $self = shift;

    my $PID = Linux::Pidfile::->new({
        'pidfile'   => $self->config()->get('Revobackup::Pidfile', { Default => '/var/run/revobackup.pid', }),
        'logger'    => $self->logger(),
    });

    return $PID;
}

# your code here ...
sub execute {
    my $self = shift;

    $self->_pidfile()->create() or die('Script already running.');

    my $bankdir = $self->config()->get('Sys::RevoBackup::Bank');
    if ( !$bankdir ) {
        die('Bankdir not defined. You must set Sys::RevoBackup::bank to an existing directory! Aborting!');
    }
    if ( !-d $bankdir ) {
        die('Bankdir ('.$bankdir.') not found. You must set Sys::RevoBackup::bank to an existing directory! Aborting!');
    }

    my $concurrency = $self->config()->get( 'Sys::RevoBackup::Concurrency', { Default => 1, } );

    my $Revo = Sys::RevoBackup::->new(
        {
            'config'      => $self->config(),
            'logger'      => $self->logger(),
            'logfile'     => $self->config()->get( 'Sys::RevoBackup::Logfile', { Default => '/tmp/revo.log' } ),
            'bank'        => $bankdir,
            'concurrency' => $concurrency,
        }
    );

    my $status = $Revo->run();

    $self->_pidfile()->remove();

    return $status;
}

sub abstract {
    return 'Make some backups';
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Sys::RevoBackup::Cmd::Command::run - run all backup jobs

=method abstract

Workadound.

=method execute

Run the backups.

=cut
