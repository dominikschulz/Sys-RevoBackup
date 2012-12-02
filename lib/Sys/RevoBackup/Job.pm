package Sys::RevoBackup::Job;
# ABSTRACT: an Revobackup job, spawns a worker

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Sys::RevoBackup::Worker;

extends 'Sys::Bprsync::Job';

foreach my $key (qw(bank vault)) {
    has $key => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'required' => 1,
    );
}

sub _startup {
    my $self = shift;

    # DGR: I really want the global effect this assignment has!
    ## no critic (RequireLocalizedPunctuationVars)
    $0 = 'revobackup - ' . $self->name();
    ## use critic

    return 1;
}

sub _init_worker {
    my $self = shift;

    my $Worker = Sys::RevoBackup::Worker::->new(
        {
            'config'  => $self->config(),
            'logger'  => $self->logger(),
            'parent'  => $self->parent(),
            'name'    => $self->name(),
            'verbose' => $self->verbose(),
            'bank'    => $self->bank(),
            'vault'   => $self->vault(),
            'dry'     => $self->dry(),
        }
    );
    return $Worker;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Sys::RevoBackup::Job - a RevoBackup job

=cut
