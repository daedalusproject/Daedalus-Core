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

sub loginUser_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status  => 'Failed',
            message => 'This method does not support GET requests.',
        },
    );
}

sub loginUser_POST {
    my ( $self, $c ) = @_;

    #$response = Daedalus::Utils::Responses::processResponse( $c, authUser($c));

    return $self->status_ok( $c,
        entity =>
          processResponse( Daedalus::Users::Manager::authUserUsingModel($c) ) );
}

=head2 imAdmin

Check if logged user is Admin

=cut

sub imAdmin : Path('/imadmin') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub imAdmin_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status  => 'Failed',
            message => 'This method does not support GET requests.',
        },
    );
}

sub imAdmin_POST {
    my ( $self, $c ) = @_;

    return $self->status_ok( $c, entity => processResponse( isAdmin($c) ) );
}

=head2 createOrganization

Create Organization

=cut

sub createOrganization : Path('/createorganization') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub createOrganization_GET {
    my ( $self, $c ) = @_;

    return $self->status_ok(
        $c,
        entity => {
            status  => 'Failed',
            message => 'This method does not support GET requests.',
        },
    );
}

sub createOrganization_POST {
    my ( $self, $c ) = @_;

    my $is_admin = isAdmin($c);

    my $response;

    if ( $is_admin->{status} eq "Failed" ) {
        $response = $is_admin;
    }
    else {
        if ( !exists( $c->{request}->{data}->{organization_data} ) ) {
            $response = {
                status  => 'Failed',
                message => 'Invalid organization data.'
            };
        }
        else {

            $response =
              Daedalus::Organizations::Manager::createOrganization( $c,
                $is_admin->{_hidden_data} );
        }
    }

    return $self->status_ok( $c, entity => processResponse($response), );
}

=head2 registerNewUser

Admin users are able to create new users.

=cut

sub registeruser : Path('/registernewuser') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub registeruser_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status  => 'Failed',
            message => 'This method does not support GET requests.',
        },
    );
}

sub registeruser_POST {
    my ( $self, $c ) = @_;

    my $is_admin = isAdmin($c);

    my $response;

    if ( $is_admin->{status} eq "Failed" ) {
        $response = $is_admin;
    }
    else {
        if ( !exists( $c->{request}->{data}->{new_user_data} ) ) {
            $response = {
                status  => 'Failed',
                message => 'Invalid user data.'
            };
        }
        else {

            $response =
              Daedalus::Users::Manager::registerNewUser( $c,
                $is_admin->{_hidden_data} );
        }
    }

    return $self->status_ok( $c, entity => processResponse($response), );
}

=head2 confrimRegister

Receives Auth token, if that token is owned by unactive user, user is registered.

=cut

sub confrimRegister : Path('/confirmuserregistration') : Args(1) :
  ActionClass('REST') {
    my ( $self, $c, $auth_token ) = @_;
    my ( $status, @user_info ) =
      Daedalus::Core::Controller::UserController->confirmUserRegistration( $c,
        $auth_token );
    die("Stop");
}

sub confrimRegister_POST {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status => "pong",
        },
    );
}

=head1 Common functions

Common functions

=cut

=head2 processResponse

Cleans _hidden_data field from responde, _hidden_data is not public

=cut

sub processResponse {
    my $response = shift;
    if ( exists $response->{_hidden_data} ) {
        delete $response->{_hidden_data};
    }
    return $response;
}

=head2 authUser

Determines if required user exists and its password match

=cut

sub authUser {

    my $c = shift;

    my $response = Daedalus::Users::Manager::authUserUsingModel(
        {
            request => $c->req,
            model   => $c->model('CoreRealms::User'),
        }
    );

    return $response;
}

=head2 isAdmin

Determines if required is and admin user

=cut

sub isAdmin {
    my $c = shift;

    my $response;
   #
   #    # Check user
   #    my $user_login_response = authUser($c);
   #
   #    if ( $user_login_response->{status} eq "Failed" ) {
   #        $response = $user_login_response;
   #    }
   #    else {
   #        $response = Daedalus::Users::Manager::isAdmin($user_login_response);
   #    }
    $response = Daedalus::Users::Manager::isAdmin($c);
    return $response;
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
