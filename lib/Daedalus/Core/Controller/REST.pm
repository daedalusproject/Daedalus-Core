package Daedalus::Core::Controller::REST;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON;
use Data::Dumper;

use base qw(Catalyst::Controller::REST);

use Daedalus::Users::Manager;
use Daedalus::Organizations::Manager;
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

=head2 ping

Returns "pong"

=cut

sub begin : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
}

sub ping : Path('/ping') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub ping_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status => "pong",
        },
    );
}

=head2 loginUser

Login user

=cut

sub loginUser : Path('/login') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub loginUser_POST {
    my ( $self, $c ) = @_;

    my $response = Daedalus::Users::Manager::authUser($c);

    if ( $response->{status} ) {
        $self->status_ok( $c, entity => $response, );
    }
    else {
        $self->status_forbidden_entity( $c, entity => $response, );
    }
}

=head2 imAdmin

Check if logged user is Admin

=cut

sub imAdmin : Path('/imadmin') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub imAdmin_POST {
    my ( $self, $c ) = @_;

    my $response = Daedalus::Users::Manager::isAdmin($c);

    if ( $response->{status} ) {
        $response->{status} = 1;
        $self->status_ok( $c, entity => $response, );
    }
    else {
        $self->status_forbidden_entity( $c, entity => $response, );
    }
}

=head2 createOrganization

Create Organization

=cut

sub createOrganization : Path('/createorganization') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub createOrganization_POST {
    my ( $self, $c ) = @_;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);

    my $response;
    if ( !$is_admin->{status} ) {
        $response = $is_admin;
        return $self->status_forbidden_entity( $c, entity => $response, );
    }
    else {
        if ( !exists( $c->{request}->{data}->{organization_data} ) ) {
            return $self->status_bad_request_entity(
                $c,
                entity => {
                    status  => 0,
                    message => 'Invalid organization data.'
                }
            );
        }
        else {

            $response =
              Daedalus::Organizations::Manager::createOrganization( $c,
                $is_admin );
        }
    }

    if ( $response->{status} ) {
        $self->status_ok( $c, entity => $response, );
    }
    else {
        $self->status_bad_request_entity( $c, entity => $response, );
    }
}

=head2 registerNewUser

Admin users are able to create new users.

=cut

sub registerNewUser : Path('/registernewuser') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub registerNewUser_POST {
    my ( $self, $c ) = @_;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);

    my $response;

    if ( !$is_admin->{status} ) {
        $response = $is_admin;
        return $self->status_forbidden_entity( $c, entity => $response, );
    }
    else {
        if ( !exists( $c->{request}->{data}->{new_user_data} ) ) {
            $response = {
                status  => 0,
                message => 'Invalid user data.'
            };

            return $self->status_bad_request_entity( $c, entity => $response, );
        }
        else {
            $response =
              Daedalus::Users::Manager::registerNewUser( $c, $is_admin );
        }
    }

    if ( $response->{status} ) {

        return $self->status_ok( $c, entity => $response, );
    }
    else {
        return $self->status_bad_request_entity( $c, entity => $response, );
    }
}

=head2 showRegisteredUsers

Admin users are able to view which users has been registered by them.

=cut

sub showRegisteredUsers : Path('/showmyregisteredusers') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub showRegisteredUsers_POST {
    my ( $self, $c ) = @_;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);

    my $response;

    if ( !$is_admin->{status} ) {
        $response = $is_admin;
        return $self->status_forbidden_entity( $c, entity => $response, );
    }
    else {
        $response = Daedalus::Users::Manager::showRegisteredUsers($c);
    }

    if ( $response->{status} ) {

        return $self->status_ok( $c, entity => $response, );
    }
    else {
        return $self->status_bad_request_entity( $c, entity => $response, );
    }
}

=head2 confrimRegister

Receives Auth token, if that token is owned by unactive user, user is registered.

=cut

sub confrimRegister : Path('/confirmregistration') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub confrimRegister_POST {
    my ( $self, $c ) = @_;
    my $response;

    $response = Daedalus::Users::Manager::confirmRegistration($c);

    if ( $response->{status} ) {
        return $self->status_ok( $c, entity => $response, );
    }
    else {

        return $self->status_forbidden_entity( $c, entity => $response, );
    }
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

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
