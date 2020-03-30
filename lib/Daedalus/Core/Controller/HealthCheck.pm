package Daedalus::Core::Controller::HealthCheck;

use 5.026_001;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON::XS;
use DateTime;
use Daedalus::Utils::Constants qw(
  $bad_request
);

use base qw(Daedalus::Core::Controller::REST);

__PACKAGE__->config( default => 'application/json' );
__PACKAGE__->config( json_options => { relaxed => 1 } );

BEGIN { extends 'Daedalus::Core::Controller::REST' }

our $VERSION = '0.01';

=head1 NAME

Daedalus::Core::Controller::HealthCheck - Catalyst Controller

=head1 SYNOPSIS

Daedalus::Core Health Check Controller.

=head1 DESCRIPTION

Daedalus::Core /ping and more endpoints controller

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS

=head2 begin

Health Checl Controller begin

=cut

sub begin : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    return;
}

=head2 ping

Returns "pong"

=cut

sub ping : Path('/ping') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 ping_GET

/ping is a GET request

=cut

sub ping_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status => "pong",
        },
    );
}

=encoding utf8

=head1 DIAGNOSTICS
=head1 CONFIGURATION AND ENVIRONMENT
=head1 DEPENDENCIES

See debian/control

=head1 INCOMPATIBILITIES
=head1 BUGS AND LIMITATIONS
=head1 LICENSE AND COPYRIGHT

Copyright 2018-2019 Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;

1;
