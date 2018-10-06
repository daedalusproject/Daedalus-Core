package Daedalus::Core::Controller::Users;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON;
use Data::Dumper;

use base qw(Daedalus::Core::Controller::REST);

use Daedalus::Users::Manager;

__PACKAGE__->config( default => 'application/json' );
__PACKAGE__->config( json_options => { relaxed => 1 } );

BEGIN { extends 'Daedalus::Core::Controller::REST' }

=head1 NAME

Daedalus::Core::Controller::REST - Catalyst Controller

=head1 DESCRIPTION

Daedalus::Core REST Controller.

=head1 METHODS

=cut

sub begin : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
}

=head2 login

Login user

=cut

sub login : Path('/user/login') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub login_POST {
    my ( $self, $c ) = @_;

    my $response = Daedalus::Users::Manager::auth_user($c);

    $response->{error_code} = 403;

    $self->return_response( $c, $response );
}

=head2 im_admin

Check if logged user is Admin

=cut

sub im_admin : Path('/user/imadmin') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub im_admin_GET {
    my ( $self, $c ) = @_;

    my $response;

    my $authorizeation_and_validatation =
      $self->authorize_and_validate( $c, { auth => { type => "admin" } } );

    if ( $authorizeation_and_validatation->{status} == 0 ) {
        $response = $authorizeation_and_validatation;
    }
    elsif ( $authorizeation_and_validatation->{status} == 1 ) {
        $response->{status}  = 1;
        $response->{message} = "You are an admin user.";
    }

    $self->return_response( $c, $response );
}

=head2 registerNewUser

Admin users are able to create new users.

=cut

sub register_new_user : Path('/user/register') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub register_new_user_POST {
    my ( $self, $c ) = @_;

    my $response;
    my $user_data;
    my $required_data;

    my $authorizeation_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'admin'
            },
            required_data => {
                'e-mail' => {
                    type     => "e-mail",
                    required => 1,
                },
                name => {
                    type     => "string",
                    required => 1,
                },
                surname => {
                    type     => "string",
                    required => 1,
                },
            }
        }
    );
    if ( $authorizeation_and_validatation->{status} == 0 ) {
        $response = $authorizeation_and_validatation;
    }
    else {
        $user_data = $authorizeation_and_validatation->{data}->{user_data};
        $required_data =
          $authorizeation_and_validatation->{data}->{required_data};

        $response =
          Daedalus::Users::Manager::register_new_user( $c, $user_data,
            $required_data );
        $response->{error_code} = 400;
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
    }

    return $self->return_response( $c, $response );
}

=head2 show_registered_users

Admin users are able to view which users has been registered by them.

=cut

sub show_registered_users : Path('/user/showregistered') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_registered_users_GET {
    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};
        $response =
          Daedalus::Users::Manager::show_registered_users( $c, $user_data );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
    }

    $self->return_response( $c, $response );
}

=head2 confirm_register

Receives Auth token, if that token is owned by inactive user, user is registered.

=cut

sub confirm_register : Path('/user/confirm') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub confirm_register_POST {
    my ( $self, $c ) = @_;
    my $response;

    $response = Daedalus::Users::Manager::confirm_registration($c);
    $response->{error_code} = 400;
    $self->return_response( $c, $response );
}

=head2 show_inactive_users

Admin users are allowed to watch which users registered by them still inactive.

=cut

sub show_inactive_users : Path('/user/showinactive') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_inactive_users_GET {
    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};
        $response =
          Daedalus::Users::Manager::show_inactive_users( $c, $user_data );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
        $response->{error_code} = 400;
    }

    $self->return_response( $c, $response );
}

=head2 show_active_users

Admin users are allowed to watch which users registered who have confirmed their registration.

=cut

sub show_active_users : Path('/user/showactive') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_active_users_GET {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};
        $response =
          Daedalus::Users::Manager::show_active_users( $c, $user_data );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
        $response->{error_code} = 400;
    }

    $self->return_response( $c, $response );
}

=head2 show_orphan_users

Admin users are allowed to list their registered users who has no organization

=cut

sub show_orphan_users : Path('/user/showorphan') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_orphan_users_GET {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};
        $response =
          Daedalus::Users::Manager::show_orphan_users( $c, $user_data );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
    }

    $self->return_response( $c, $response );
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
