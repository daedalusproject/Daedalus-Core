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

    return $self->status_ok( $c, entity => $response, );
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

    return $self->status_ok( $c,
        entity => Daedalus::Users::Manager::isAdmin($c) );
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

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);

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
                $is_admin );
        }
    }

    return $self->status_ok( $c, entity => $response, );
}

=head2 registerNewUser

Admin users are able to create new users.

=cut

sub registerNewUser : Path('/registernewuser') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub registerNewUser_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status  => 'Failed',
            message => 'This method does not support GET requests.',
        },
    );
}

sub registerNewUser_POST {
    my ( $self, $c ) = @_;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);

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
              Daedalus::Users::Manager::registerNewUser( $c, $is_admin );
        }
    }

    return $self->status_ok( $c, entity => $response, );
}

=head2 showRegisteredUsers

Admin users are able to view which users has been registered by them.

=cut

sub showRegisteredUsers : Path('/showmyregisteredusers') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub showRegisteredUsers_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status  => 'Failed',
            message => 'This method does not support GET requests.',
        },
    );
}

sub showRegisteredUsers_POST {
    my ( $self, $c ) = @_;

    my $is_admin = Daedalus::Users::Manager::isAdmin($c);

    my $response;

    if ( $is_admin->{status} eq "Failed" ) {
        $response = $is_admin;
    }
    else {
        $response = Daedalus::Users::Manager::showRegisteredUsers($c);
    }

    return $self->status_ok( $c, entity => $response, );
}

=head2 confrimRegister

Receives Auth token, if that token is owned by unactive user, user is registered.

=cut

sub confrimRegister : Path('/confirmregistration') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub confrimRegister_GET {
    my ( $self, $c ) = @_;
    return $self->status_ok(
        $c,
        entity => {
            status  => 'Failed',
            message => 'This method does not support GET requests.',
        },
    );
}

sub confrimRegister_POST {
    my ( $self, $c ) = @_;
    my $response;

    $response = Daedalus::Users::Manager::confirmRegistration($c);

    return $self->status_ok( $c, entity => $response, );
}

=head1 Common functions

Common functions

=cut

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
