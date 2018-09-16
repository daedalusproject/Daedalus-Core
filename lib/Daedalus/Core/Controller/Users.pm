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

    $response->{error_code} = 403;

    $self->return_response( $c, $response );
}

=head2 imAdmin

Check if logged user is Admin

=cut

sub imAdmin : Path('/user/imadmin') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub imAdmin_GET {
    my ( $self, $c ) = @_;

    my $response;

    my $user = Daedalus::Users::Manager::get_user_from_session_token($c);
    my $user_data;

    if ( $user->{status} == 0 ) {
        $response = $user;
    }
    else {
        $user_data = $user->{data};
        $response->{data} =
          { user => { is_admin => $user_data->{data}->{user}->{is_admin} } };
        if ( $user_data->{data}->{user}->{is_admin} ) {
            $response->{status}  = 1;
            $response->{message} = "You are an admin user.";
        }
        else {
            $response->{status}  = 0;
            $response->{message} = "You are not an admin user.";

        }
    }

    $response->{error_code} = 400;

    $self->return_response( $c, $response );
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

Returns 200, 400 or 403 based on response status

=cut

sub return_response {
    my $self     = shift;
    my $c        = shift;
    my $response = shift;

    my $error_code = $response->{error_code};
    delete $response->{error_code};

    if ( $response->{_hidden_data} ) {
        if ( $response->{_hidden_data}->{user} ) {
            if ( $response->{_hidden_data}->{user}->{is_super_admin} != 1 ) {
                delete $response->{_hidden_data};
            }
        }
    }

    if ( $response->{status} ) {
        return $self->status_ok( $c, entity => $response, );
    }
    else {

        if ( $error_code == 403 ) {
            return $self->status_forbidden_entity( $c, entity => $response, );
        }
        if ( $error_code == 400 ) {
            return $self->status_bad_request_entity( $c, entity => $response, );
        }

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
