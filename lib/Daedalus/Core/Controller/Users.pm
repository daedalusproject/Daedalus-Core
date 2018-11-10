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

    my $required_data;
    my $response;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            required_data => {
                'e-mail' => {
                    type     => "e-mail",
                    required => 1,
                },
                password => {
                    type     => "password",
                    required => 1,
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $required_data =
          $authorization_and_validatation->{data}->{required_data};
        $response = Daedalus::Users::Manager::auth_user( $c, $required_data );
    }

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

    my $authorization_and_validatation =
      $self->authorize_and_validate( $c, { auth => { type => "admin" } } );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    elsif ( $authorization_and_validatation->{status} == 1 ) {
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

    my $authorization_and_validatation = $self->authorize_and_validate(
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
    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};
        $required_data =
          $authorization_and_validatation->{data}->{required_data};

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
    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'admin'
            },
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};
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

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            required_data => {
                'auth_token' => {
                    type     => "string",
                    required => 1,
                },
                password => {
                    type     => "string",
                    required => 0,
                },
            }
        }
    );
    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $response = Daedalus::Users::Manager::confirm_registration( $c,
            $authorization_and_validatation->{data}->{required_data} );
    }

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

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'admin'
            },
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};
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

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'admin'
            },
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};
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

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'admin'
            },
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};
        $response =
          Daedalus::Users::Manager::show_orphan_users( $c, $user_data );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
        $response->{error_code} = 400;
    }

    $self->return_response( $c, $response );
}

sub remove_user : Path('/user/remove') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub remove_user_DELETE {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $target_user;
    my $target_user_email;

    my $able_to_remove = 1;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'admin',
            },
            required_data => {
                user_email => {
                    type     => 'e-mail',
                    required => 1,
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};
        $target_user_email =
          $authorization_and_validatation->{data}->{required_data}
          ->{user_email};
        $target_user = Daedalus::Users::Manager::get_user_from_email( $c,
            $target_user_email );

        $response->{error_code} = 400;
        $response->{status}     = 0;
        $response->{message} =
"Requested user does not exists or it has not been registered by you.";

        if ( defined $target_user ) {
            if ( $user_data->{_hidden_data}->{user}->{is_super_admin} == 0 ) {
                if (
                    !defined Daedalus::Users::Manager::show_registered_users(
                        $c, $user_data )->{data}->{registered_users}
                    ->{ $target_user->email }
                  )
                {
                    $able_to_remove = 0;
                }
            }
            else {
                if ( $user_data->{data}->{user}->{"e-mail"} eq
                    $target_user->email )
                {
                    $able_to_remove = 0;
                }
            }
            if ( $able_to_remove == 1 ) {
                Daedalus::Users::Manager::remove_user( $c, $target_user );
                $response->{status} = 1;
                $response->{message} =
                  "Selected user has been removed from organization.";
            }
        }
    }

    $self->return_response( $c, $response );
}

=head2 user_data

Manages user data

=cut

sub user_data : Path('/user') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub user_data_GET {
    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $authorization_and_validatation =
      $self->authorize_and_validate( $c, { auth => { type => "user" } } );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    elsif ( $authorization_and_validatation->{status} == 1 ) {
        $user_data = $authorization_and_validatation->{data}->{user_data};
        $response->{status}       = 1;
        $response->{data}         = $user_data->{data};
        $response->{_hidden_data} = $user_data->{_hidden_data};
    }

    $self->return_response( $c, $response );
}

=head2 user_data_PUT

Updates user data

=cut

sub user_data_PUT {
    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $data_to_update = {};

    my $required_data = {
        name => {
            type     => 'string',
            required => 0,
        },
        surname => {
            type     => "string",
            required => 0,
        },
        phone => {
            type     => "phone",
            required => 0,
        },
    };

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'user',
            },
            required_data => $required_data,
        }
    );
    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    elsif ( $authorization_and_validatation->{status} == 1 ) {
        $user_data = $authorization_and_validatation->{data}->{user_data};
        for my $data ( keys %{$required_data} ) {
            if (
                defined $authorization_and_validatation->{data}
                ->{required_data}->{$data} )
            {
                $data_to_update->{$data} =
                  $authorization_and_validatation->{data}->{required_data}
                  ->{$data};
            }
        }
        if ($data_to_update) {
            Daedalus::Users::Manager::update_user_data( $c, $user_data,
                $data_to_update );
        }
        $response->{status}     = 1;
        $response->{error_code} = 400;
    }

    $self->return_response( $c, $response );
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;

1;
