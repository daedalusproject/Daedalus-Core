package Daedalus::Core::Controller::REST;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON::XS;
use Number::Phone;
use Daedalus::Utils::Constants qw(
  $bad_request
  $success
  $forbidden
);

use base qw(Catalyst::Controller::REST);

use Daedalus::Organizations::Manager;
use Daedalus::Users::Manager;

__PACKAGE__->config( default => 'application/json' );
__PACKAGE__->config( json_options => { relaxed => 1 } );

our $VERSION = '0.01';

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

Daedalus::Core::Controller::REST - Catalyst Controller

=head1 SYNOPSIS

Daedalus::Core REST Controller.


=head1 DESCRIPTION

Daedalus::Core REST Controller.

Here is where main requests validator resides.

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS

=cut

=head1 Common functions

Common functions

=cut

=head2 status_forbidden_entity

Returns forbidden status using custom response based on controller $response

=cut

sub status_forbidden_entity {
    my ( $self, $c, @params ) = @_;
    my %p = Params::Validate::validate( @params, { entity => 1, }, );

    $c->response->status($forbidden);
    $self->_set_entity( $c, $p{'entity'} );
    return 1;
}

=head2 status_bad_request_entity

Returns bad requests status using custom response based on controller $response

=cut

sub status_bad_request_entity {

    my ( $self, $c, @params ) = @_;
    my %p = Params::Validate::validate( @params, { entity => 1, }, );

    $c->response->status($bad_request);
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

    if ( exists $response->{message} ) {
        $response->{message} =~ s/^\s+|\s+$//smxg;
    }

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
        delete $response->{data};

        if ( $error_code == $forbidden ) {

            return $self->status_forbidden_entity( $c, entity => $response, );
        }
        else {    # 400
            return $self->status_bad_request_entity( $c, entity => $response, );
        }
    }
}

=head2 check_organization_token

Checks organization token

=cut

sub check_organization_token {
    my $response;

    $response->{message} = q{};
    $response->{status}  = 1;
    return;
}

=head2 manage_auth

Checks auth

=cut

sub manage_auth {

    my $c        = shift;
    my $auth     = shift;
    my $data     = shift;
    my $response = shift;

    my $user;
    my $check_organization_roles = 0;

    if ( $auth->{type} eq "user" or $auth->{type} eq "organization" ) {
        $user = Daedalus::Users::Manager::get_user_from_session_token($c);
        if ( $auth->{type} eq "organization" ) {
            $check_organization_roles = 1;
        }
    }
    else {    #elsif ( $auth->{type} eq "admin" ) {
        $user = Daedalus::Users::Manager::is_admin_from_session_token($c);
    }

    if ( $user->{status} == 0 ) {
        $response->{status} = 0;
        $response = $user;
    }
    else {    #elsif ( $user->{status} == 1 ) {
        $data->{user_data} = $user->{data};
    }
    return $response, $user, $check_organization_roles, $data;

}

=head2 check_organization_roles_valid

Checks if user roles are valid for given organization

=cut

sub check_organization_roles_valid {

    my $c        = shift;
    my $response = shift;
    my $auth     = shift;
    my $data     = shift;

    #Check if user is organization memeber
    my $organization_member = Daedalus::Users::Manager::is_organization_member(
        $c,
        $data->{user_data}->{_hidden_data}->{user}->{id},
        $data->{organization}->{_hidden_data}->{organization}->{id}
    );
    if ( $organization_member->{status} == 0 ) {
        $response->{status}     = 0;
        $response->{error_code} = $bad_request;
        $response->{message}    = "Invalid organization token.";
    }

    if ( $response->{status} == 1
        and exists( $auth->{organization_roles} ) )
    {
        my $user_match_role =
          Daedalus::OrganizationGroups::Manager::user_match_role(
            $c,
            $data->{user_data}->{data}->{user}->{'e-mail'},
            $data->{organization}->{_hidden_data}->{organization}->{id},
            $auth->{organization_roles}
          );
        if ( $user_match_role->{status} == 0 ) {

            my $prety_role_name =
              join( q{ }, @{ $auth->{organization_roles} } );
            $prety_role_name =~ s/_/ /smg;
            $response->{status}     = 0;
            $response->{error_code} = $forbidden;
            $response->{message} =
"Your organization roles does not match with the following roles: $prety_role_name.";
        }
        else {
            $data->{organization_groups} =
              $user_match_role->{'organization_groups'};
        }
    }

    return $response, $data;

}

=head2 check_user_token

  Checks if user token is valid .

=cut

sub check_user_token {

    my $c                    = shift;
    my $user_token_candidate = shift;
    my $data                 = shift;
    my $data_properties      = shift;
    my $required_data_name   = shift;

    my $response;

    $response->{message} = q{};
    $response->{status}  = 1;

    if (
        length($user_token_candidate) !=
        $c->config->{tokens}->{user_token_length} )
    {
        $response->{status}     = 0;
        $response->{error_code} = $bad_request;
        $response->{message} =
          $response->{message} . " $required_data_name is invalid.";
    }
    else {
        my $registered_user =
          Daedalus::Users::Manager::get_user_from_token( $c,
            $user_token_candidate );
        if ( !$registered_user ) {
            $response->{status}     = 0;
            $response->{error_code} = $bad_request;
            $response->{message}    = $response->{message}
              . "There is no registered user with that token.";
        }
        else {
            check_registered_user( $c, $data, $data_properties,
                $registered_user, $response );
        }
    }
    return $response;
}

=head2 check_registered_user

Checks registered user.

=cut

sub check_registered_user {

    my $c               = shift;
    my $data            = shift;
    my $data_properties = shift;
    my $registered_user = shift;
    my $response        = shift;

    if (
        (
               $data_properties->{type} eq "active_user_token"
            or $data_properties->{type} eq "organization_user"
        )
        and $registered_user->active == 0
      )
    {
        $response->{status}     = 0;
        $response->{error_code} = $bad_request;
        $response->{message} =
          $response->{message} . "Required user is not active.";
    }
    $data->{'registered_user_token'} =
      Daedalus::Users::Manager::get_user_data( $c, $registered_user );
    if (    ( $data_properties->{type} eq "organization_user" )
        and ( $response->{status} == 1 ) )
    {
        check_user_organization_member( $c, $data, $response );
    }

    return;
}

=head2 check_user_organization_member

Checks if given user is an organization member.

=cut

sub check_user_organization_member {
    my $c        = shift;
    my $data     = shift;
    my $response = shift;

    my $is_organization_member =
      Daedalus::Users::Manager::is_organization_member(
        $c,
        $data->{'registered_user_token'}->{_hidden_data}->{user}->{id},
        $data->{organization}->{_hidden_data}->{organization}->{id}
      );

    if ( $is_organization_member->{status} == 0 ) {
        $response->{status}     = 0;
        $response->{error_code} = $bad_request;
        $response->{message}    = "Invalid user.";
    }

    return;
}

=head2 check_required_data

Checks required data

=cut

sub check_required_data {

    my $c                  = shift;
    my $response           = shift;
    my $required_data      = shift;
    my $required_data_name = shift;
    my $data               = shift;

    my $value;

    my $data_properties = $required_data->{$required_data_name};

    if ( $data_properties->{given} == 1 ) {
        $value = $data_properties->{value};
    }
    else {
        $value = $c->{request}->{data}->{$required_data_name};
    }

    if (   defined($value)
        && $data_properties->{forbid_empty} == 1
        && length($value) == 0 )
    {
        $response->{status}     = 0;
        $response->{error_code} = $bad_request;
        $response->{message} =
          $response->{message} . " $required_data_name field is empty.";
    }
    else {
        if ( $data_properties->{required} == 1 ) {
            if ( !( defined $value ) ) {
                $response->{status}     = 0;
                $response->{error_code} = $bad_request;
                $response->{message} =
                  $response->{message} . " No $required_data_name provided.";
            }
        }
    }

    if ( $response->{status} == 1 ) {

        #Check Type
        if ( $data_properties->{type} eq "e-mail" ) {
            if ( !Daedalus::Users::Manager::check_email_valid($value) ) {
                $response->{status}     = 0;
                $response->{error_code} = $bad_request;
                $response->{message} =
                  $response->{message} . " $required_data_name is invalid.";
            }
        }

        elsif ($data_properties->{type} eq "registered_user_token"
            or $data_properties->{type} eq "active_user_token"
            or $data_properties->{type} eq "organization_user" )
        {
            # Check users token length
            $response =
              check_user_token( $c, $value, $data, $data_properties,
                $required_data_name );
        }

        elsif ( $data_properties->{type} eq "phone" ) {
            check_phone_number( $response, $value, $required_data_name );
        }

        if ( $response->{status} == 1 ) {
            $data->{required_data}->{$required_data_name} = $value;
        }
    }

    return $response, $data;
}

=head2 check_phone_number

Checks phone number.

=cut

sub check_phone_number {
    my $response           = shift;
    my $phone_candidate    = shift;
    my $required_data_name = shift;

    if ($phone_candidate) {
        my $phone       = Number::Phone->new($phone_candidate);
        my $valid_phone = 1;

        if ( !( defined $phone ) ) {
            $valid_phone = 0;
        }
        if ( $valid_phone == 0 ) {
            $response->{status}     = 0;
            $response->{error_code} = $bad_request;
            $response->{message}    = "Invalid $required_data_name.";
        }
    }
    return;
}

=head2 authorize_and_validate

Checks user or admin user, stops request processing if it is not valid.

Checks requested data, if they does not exists or have incorrect format (hashmaps too), stops request processing if it
is no valid.

=cut

sub authorize_and_validate {

    my ( $self, $c, $request_data ) = @_;

    # We expect auth and request parameters as arguments

    my $check_organization_roles = 0;

    my $response;
    my $data;

    $response->{message} = q{};
    $response->{status}  = 1;

    # Authorize
    my $auth          = delete $request_data->{auth};
    my $required_data = delete $request_data->{required_data};

    my $value;
    my $user;

    my $organization_token_check = { status => 1 };

    # If exists check organization token first. Code copied again.
    if ( exists $required_data->{organization_token} )

     #  and ( $required_data->{organization_token}->{type} eq "organization" ) )
    {
        check_organization_token();
        my $data_properties = $required_data->{organization_token};
        if ( $data_properties->{given} == 1 ) {
            $value = $data_properties->{value};
        }
        else {
            $value = $c->{request}->{data}->{organization_token};

#if ( $data_properties->{required} == 1 ) { for the time being this field is always required
            if ( !( defined $value ) ) {
                $response->{status}     = 0;
                $response->{error_code} = $bad_request;
                $response->{message} =
                  $response->{message} . " No organization_token provided.";
            }
            else {
                $data->{required_data}->{organization_token} = $value;
            }

            # }
        }
        if ( $response->{status} == 1 ) {

            delete $required_data->{organization_token};
            $organization_token_check =
              Daedalus::Organizations::Manager::get_organization_from_token( $c,
                $value );

            if ( $organization_token_check->{status} == 1 ) {
                $data->{organization} =
                  $organization_token_check->{organization};
            }

        }
    }

    if ($auth) {

        ( $response, $user, $check_organization_roles, $data ) =
          manage_auth( $c, $auth, $data, $response );
    }

    if (    $response->{status} == 1
        and $user->{data}->{_hidden_data}->{user}->{is_super_admin} == 0 )
    {

        # Check check_organization_roles
        if ( $check_organization_roles == 1 ) {
            ( $response, $data ) =
              check_organization_roles_valid( $c, $response, $auth, $data );
        }
    }

    if ( $response->{status} == 1 ) {

        # Auth passed, check required_data
        for my $required_data_name ( sort ( keys %{$required_data} ) ) {

            ( $response, $data ) =
              check_required_data( $c, $response, $required_data,
                $required_data_name, $data );
        }

        if ( $organization_token_check->{status} == 0 ) {
            $response = $organization_token_check;
        }

    }

    $response->{data} = $data;
    return $response;
}

__PACKAGE__->meta->make_immutable;

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

1;
