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

    $self->return_authorized_response( $c, $response );
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

    $self->return_authorized_response( $c, $response );
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

    $self->return_rest_response( $c, $response );
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

            $self->status_bad_request_entity( $c, entity => $response, );
        }
        else {
            $response =
              Daedalus::Users::Manager::registerNewUser( $c, $is_admin );
        }
    }

    return $self->return_rest_response( $c, $response );
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

    $self->return_rest_response( $c, $response );
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

    $self->return_rest_response( $c, $response );
}

=head2 showinactiveusers

Admin users are allowed to watch which users registered by them still inactive.

=cut

sub showInactiveUsers : Path('/showinactiveusers') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub showInactiveUsers_POST {
    my ( $self, $c ) = @_;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);
    my $response;

    if ( !$is_admin->{status} ) {
        $response = $is_admin;
        return $self->status_forbidden_entity( $c, entity => $response, );
    }
    else {
        $response = Daedalus::Users::Manager::showInactiveUsers($c);
    }
    $self->return_rest_response( $c, $response );
}

=head2 showactiveusers

Admin users are allowed to watch which users registered who have confirmed their registration.

=cut

sub showActiveUsers : Path('/showactiveusers') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub showActiveUsers_POST {
    my ( $self, $c ) = @_;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);
    my $response;

    if ( !$is_admin->{status} ) {
        $response = $is_admin;
        return $self->status_forbidden_entity( $c, entity => $response, );
    }
    else {
        $response = Daedalus::Users::Manager::showActiveUsers($c);
    }
    $self->return_rest_response( $c, $response );
}

=head2 showorganizations

Users are allowed to show their organizations

=cut

sub showOrganizations : Path('/showorganizations') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub showOrganizations_POST {
    my ( $self, $c ) = @_;

    my $response;

    my $auth = Daedalus::Users::Manager::authUser($c);

    if ( !$auth->{status} ) {
        return $self->status_forbidden_entity( $c, entity => $auth, );
    }
    else {
        $response =
          Daedalus::Organizations::Manager::getUserOrganizations( $c, $auth );
    }

    $self->return_rest_response( $c, $response );
}

=head2 showorganizationusers

Admin users are allowed to show their organization users

=cut

sub showOrganizationUsers : Path('/showorganizationusers') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub showOrganizationUsers_POST {
    my ( $self, $c ) = @_;

    my $response;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);

    if ( $is_admin->{status} != 1 ) {    #Not an admin user
        $response = $is_admin;
        $self->return_authorized_response( $c, $response );
    }
    else {
        my $user = Daedalus::Users::Manager::get_user( $c,
            $c->{request}->{data}->{auth}->{email} );
        my $organization_request =
          Daedalus::Organizations::Manager::_getOrganizationFromToken( $c,
            $user->email );
        if ( $organization_request->{status} == 0 ) {
            $response = $organization_request;
        }
        else {
            my $organization = $organization_request->{organization};

            #Check is user is admin of $oganization
            my $is_organization_admin =
              Daedalus::Users::Manager::isOrganizationAdmin( $c, $user->id,
                $organization->id );
            my $is_super_admin =
              Daedalus::Users::Manager::isSuperAdminById( $c, $user->id );
            if ( $is_organization_admin->{status} == 0 && $is_super_admin == 0 )
            {
                $response->{status} = 0;

                # Do not reveal if the token exists if the user is not an admin
                $response->{message} = 'Invalid Organization token';
            }
            else {
                #Get users from organization
                $response =
                  Daedalus::Users::Manager::getOrganizationUsers( $c,
                    $organization->id, $is_super_admin );
            }
        }
        $self->return_rest_response( $c, $response );
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
