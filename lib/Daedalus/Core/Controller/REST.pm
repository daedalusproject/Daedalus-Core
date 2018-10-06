package Daedalus::Core::Controller::REST;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON;
use Data::Dumper;

use base qw(Catalyst::Controller::REST);

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

=head2 return_response

Returns 200, 400 or 403 based on response status

=cut

sub return_response {
    my $self     = shift;
    my $c        = shift;
    my $response = shift;

    my $error_code = $response->{error_code};
    delete $response->{error_code};

    $response->{message} =~ s/^\s+|\s+$//g if ( exists $response->{message} );

    if ( $response->{_hidden_data} && $response->{_hidden_data}->{user} ) {
        if ( $response->{_hidden_data}->{user}->{is_super_admin} != 1 ) {
            delete $response->{_hidden_data};
        }
    }

    if ( $response->{status} ) {
        return $self->status_ok( $c, entity => $response, );
    }
    else {
        # Request has failed, remove _hidden_data
        delete $response->{_hidden_data};

        if ( $error_code == 403 ) {

            return $self->status_forbidden_entity( $c, entity => $response, );
        }
        elsif ( $error_code == 400 ) {
            return $self->status_bad_request_entity( $c, entity => $response, );
        }

    }
}

=head2 authorize_and_validate

Checks user or admin user, stops request processing if it is not valid.

Checks requested data, if they does not exists or have incorrect format (hashmaps too), stops request processing if it
is no valid.

=cut

sub authorize_and_validate {

    my ( $self, $c, $request_data ) = @_;

    # We expect auth and request parameters as arguments

    my $response;
    my $status = 1;
    my $data;

    # Authorize
    my $auth = delete $request_data->{auth};

    # Auth type is user or admin
    my $user;

    if ($auth) {
        if ( $auth->{type} eq "user" ) {
            $user = Daedalus::Users::Manager::get_user_from_session_token($c);
        }
        elsif ( $auth->{type} eq "admin" ) {
            $user = Daedalus::Users::Manager::is_admin_from_session_token($c);
        }

        if ( $user->{status} == 0 ) {
            $status   = 0;
            $response = $user;
        }
        elsif ( $user->{status} == 1 ) {
            $data->{user_data} = $user->{data};
        }
    }
    if ( $status == 0 ) {
        $response->{status} = 0;
    }
    else {
        $response->{status} = 1;
        $response->{data}   = $data;
    }

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
