package Daedalus::Core::Controller::Users;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON;
use Data::Dumper;

use base qw(Catalyst::Controller::REST);

use Daedalus::Users::Manager;

__PACKAGE__->config( default => 'application/json' );
__PACKAGE__->config( json_options => { relaxed => 1 } );

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

Daedalus::Core::Controller::REST - Catalyst Controller

=head1 DESCRIPTION

Daedalus::Core REST Controller.

=head1 METHODS

=cut

sub begin : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
}

=head2 loginr

Login user

=cut

sub login : Path('/user/login') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub login_POST {
    my ( $self, $c ) = @_;

    my $response = Daedalus::Users::Manager::authUser($c);

    $self->return_authorized_response( $c, $response );
}

=head2 imAdmin

Check if logged user is Admin

=cut

sub imAdmin : Path('/user/imadmin') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub imAdmin_POST {
    my ( $self, $c ) = @_;

    my $response = Daedalus::Users::Manager::isAdmin($c);

    $self->return_authorized_response( $c, $response );
}

=head1 Common functions

Common functions

=cut

=head2 status_forbidden_entity

Returns forbidden status using custom response based on controller $response

=cut

sub status_forbidden_entity {
    my $self = shift;
    my $c    = shift;
    my %p    = Params::Validate::validate( @_, { entity => 1, }, );

    $c->response->status(403);
    $self->_set_entity( $c, $p{'entity'} );
    return 1;
}

=head2 status_bad_request_entity

Returns bad requests status using custom response based on controller $response

=cut

sub status_bad_request_entity {
    my $self = shift;
    my $c    = shift;
    my %p    = Params::Validate::validate( @_, { entity => 1, }, );

    $c->response->status(400);
    $self->_set_entity( $c, $p{'entity'} );
    return 1;
}

=head2 return_authorized_response

Returns 200 or 403 based on response status

=cut

sub return_authorized_response {
    my $self     = shift;
    my $c        = shift;
    my $response = shift;

    if ( $response->{status} ) {
        return $self->status_ok( $c, entity => $response, );
    }
    else {
        return $self->status_forbidden_entity( $c, entity => $response, );
    }
}

=head2 return_rest_response

Returns 200 or 400 based on response status

=cut

sub return_rest_response {
    my $self     = shift;
    my $c        = shift;
    my $response = shift;

    if ( $response->{status} ) {
        return $self->status_ok( $c, entity => $response, );
    }
    else {

        return $self->status_bad_request_entity( $c, entity => $response, );
    }
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
