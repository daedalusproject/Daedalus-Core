package Daedalus::Core::Controller::Organizations;

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

=head2 create_organization

Create Organization

=cut

sub create_organization : Path('/organization/create') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub create_organization_POST {
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
                'name' => {
                    name     => "string",
                    required => 1,
                },
            }
        }
    );

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};
        $required_data =
          $authorization_and_validatation->{data}->{required_data};
        $response =
          Daedalus::Organizations::Manager::create_organization( $c,
            $user_data, $required_data );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
    }
    $self->return_response( $c, $response );
}

=head2 show_organizations

Users are allowed to show their organizations

=cut

sub show_organizations : Path('/organization/show') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_organizations_GET {
    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'user'
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
          Daedalus::Organizations::Manager::get_organizations_from_user( $c,
            $user_data );
        $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    }

    $self->return_response( $c, $response );
}

sub show_organization_users : Path('/organization/showusers') : Args(1) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_organization_users_GET {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;
    my $organization_token;    # Token will be acquired only if user is an admin

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data          = $user->{data};
        $organization_token = $c->{request}->{arguments}[0]
          ;                    # I'm sure that there is only one argument
        my $organization_request =
          Daedalus::Organizations::Manager::get_organization_from_token( $c,
            $organization_token );
        if ( $organization_request->{status} == 0 ) {
            $response = $organization_request;
            $response->{error_code} = 400;
        }
        else {
            my $organization = $organization_request->{organization};

            #Check is user is admin of $oganization
            my $is_organization_admin =
              Daedalus::Users::Manager::is_organization_admin(
                $c,
                $user_data->{_hidden_data}->{user}->{id},
                $organization->{_hidden_data}->{organization}->{id}
              );

            if (   $is_organization_admin->{status} == 0
                && $user_data->{_hidden_data}->{user}->{is_super_admin} == 0 )
            {
                $response->{status} = 0;

                # Do not reveal if the token exists if the user is not an admin
                $response->{message}    = 'Invalid Organization token';
                $response->{error_code} = 400;
            }
            else {
                #Get users from organization
                $response = Daedalus::Users::Manager::get_organization_users(
                    $c,
                    $organization->{_hidden_data}->{organization}->{id},
                    $user_data->{_hidden_data}->{user}->{is_super_admin}
                );
            }

        }
    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );
}

sub add_user_to_organization : Path('/organization/adduser') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub add_user_to_organization_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;
    my $organization_token;    # Token will be acquired only if user is an admin
    my $organization_token_check;
    my $target_organization_data;
    my $target_user_email;    # e-mail will be acquired only if user is an admin
    my $target_user_email_check;
    my $target_user;
    my $target_user_data;

    my $is_organization_admin;
    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    $response->{message} = "";
    $response->{status}  = 1;

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {

        $user_data = $user->{data};

        $organization_token = $c->{request}->{data}->{organization_token};
        $target_user_email  = $c->{request}->{data}->{user_email};

        # Organization token
        if ( !$organization_token ) {
            $organization_token_check->{status} = 0;
        }
        else {
            $organization_token_check =
              Daedalus::Organizations::Manager::get_organization_from_token( $c,
                $organization_token );
            $target_organization_data =
              $organization_token_check->{organization};
            $is_organization_admin =
              Daedalus::Users::Manager::is_organization_admin(
                $c,
                $user_data->{_hidden_data}->{user}->{id},
                $target_organization_data->{_hidden_data}->{organization}->{id}
              );
            if ( !$is_organization_admin->{status} ) {
                $organization_token_check->{status} = 0;
            }
        }

        $response->{message} = "Invalid Organization token."
          unless ( $organization_token_check->{status} == 1 );

        if ( !$target_user_email ) {
            $target_user_email_check->{status}  = 0;
            $target_user_email_check->{message} = "No user e-mail provided.";
        }
        else {
            # Check if e-mail is valid
            if (
                !Daedalus::Users::Manager::check_email_valid(
                    $target_user_email)
              )
            {
                $target_user_email_check->{status}  = 0;
                $target_user_email_check->{message} = 'User e-mail invalid.';
            }
            else {
                # E-mail format is ok, check if it exists
                $target_user =
                  Daedalus::Users::Manager::get_user_from_email( $c,
                    $target_user_email );
                if ( !$target_user ) {
                    $target_user_email_check->{status} = 0;
                    $target_user_email_check->{message} =
                      "There is not registered user with that e-mail address.";
                }
                else {
                    # user_exists
                    $target_user_data =
                      Daedalus::Users::Manager::get_user_data( $c,
                        $target_user );
                    if ( !$target_user_data->{data}->{user}->{active} ) {
                        $target_user_email_check->{status} = 0;
                        $target_user_email_check->{message} =
                          "Required user is not active.";
                    }
                    else {
                        $target_user_email_check->{status} = 1;
                    }
                }
            }
        }

        $response->{message} =
          $response->{message} . " " . $target_user_email_check->{message}
          unless ( $target_user_email_check->{status} );

        if (    $organization_token_check->{status}
            and $target_user_email_check->{status} )
        {
            $response =
              Daedalus::Organizations::Manager::add_user_to_organization( $c,
                $target_user_data, $target_organization_data, );
        }
        else {
            $response->{status} = 0;
            if ( !$organization_token and !$target_user_email ) {
                $response->{message} =
                  "No organization data neither user info provided.";
            }
        }
        $response->{error_code} = 400;
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );
}

sub show_organizations_groups : Path('/organization/showusergroups') : Args(0)
  : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_organizations_groups_GET {

    my ( $self, $c ) = @_;
    my $response;
    my $user_data;

    my $user_groups;

    my $user = Daedalus::Users::Manager::get_user_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};
        $response =
          Daedalus::Organizations::Manager::get_user_organizations_groups( $c,
            $user_data );
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );
}

sub show_organization_groups : Path('/organization/showorganizationusergroups')
  : Args(1) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_organization_groups_GET {

    my ( $self, $c ) = @_;
    my $response;
    my $user_data;
    my $organization;
    my $organization_data;
    my $organization_member;

    my $user_groups;

    my $organization_token = $c->{request}->{arguments}[0];

    my $user = Daedalus::Users::Manager::get_user_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};
        $organization =
          Daedalus::Organizations::Manager::get_organization_from_token( $c,
            $organization_token );
        if ( $organization->{status} == 0 ) {
            $response = $organization;
            $response->{error_code} = 400;

        }
        else {
            $organization_data = $organization->{organization};
            $organization_member =
              Daedalus::Users::Manager::is_organization_member(
                $c,
                $user_data->{_hidden_data}->{user}->{id},
                $organization_data->{_hidden_data}->{organization}->{id}
              );
            if ( $organization_member->{status} == 0 ) {
                $response->{status}     = 0;
                $response->{message}    = "Invalid organization token.";
                $response->{error_code} = 400;
            }
            else {
                $response =
                  Daedalus::Organizations::Manager::get_user_organization_groups(
                    $c, $user_data, $organization_data );

                $response->{error_code} = 400;
                $response->{status}     = 1;

            }
        }
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );
}

sub show_all_organization_groups : Path('/organization/showoallgroups')
  : Args(1) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_all_organization_groups_GET {

    my ( $self, $c ) = @_;
    my $response;
    my $user_data;

    my $organization;
    my $organization_data;

    my $is_organization_admin;

    my $groups;

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    my $organization_token = $c->{request}->{arguments}[0];

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};
        $organization =
          Daedalus::Organizations::Manager::get_organization_from_token( $c,
            $organization_token );

        if ( $organization->{status} == 0 ) {
            $response = $organization;
            $response->{error_code} = 400;

        }
        else {
            $organization_data = $organization->{organization};
            $is_organization_admin =
              Daedalus::Users::Manager::is_organization_admin(
                $c,
                $user_data->{_hidden_data}->{user}->{id},
                $organization_data->{_hidden_data}->{organization}->{id}
              );
            if (   $is_organization_admin->{status} == 0
                && $user_data->{_hidden_data}->{user}->{is_super_admin} == 0 )

            {
                $response->{status}     = 0;
                $response->{message}    = "Invalid organization token.";
                $response->{error_code} = 400;

            }
            else {
                $groups =
                  Daedalus::Organizations::Manager::get_organization_groups( $c,
                    $organization_data->{_hidden_data}->{organization}->{id} );
                $response->{data}->{groups}         = $groups->{data};
                $response->{_hidden_data}->{groups} = $groups->{_hidden_data};
                $response->{status}                 = 1;
                $response->{error_code}             = 400;

            }
        }
    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );

}

sub create_organization_group : Path('/organization/creategroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub create_organization_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization_token;
    my $organization;
    my $organization_data;

    my $is_organization_admin;

    my $groups;
    my $group_name;

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};

        $organization_token = $c->{request}->{data}->{organization_token};
        $group_name         = $c->{request}->{data}->{group_name};

        $response->{message} = "";

        # Organization token and group name must be defined
        if ( !$organization_token ) {
            $response->{message} = "Organization token not provided.";
        }
        if ( !$group_name ) {
            $response->{message} =
              $response->{message} . " Group name not provided.";
        }

        if ( $response->{message} ne "" ) {
            $response->{error_code} = 400;
            $response->{status}     = 0;
        }
        else {

            $organization =
              Daedalus::Organizations::Manager::get_organization_from_token( $c,
                $organization_token );

            if ( $organization->{status} == 0 ) {
                $response = $organization;
                $response->{error_code} = 400;

            }
            else {
                $organization_data = $organization->{organization};
                $is_organization_admin =
                  Daedalus::Users::Manager::is_organization_admin(
                    $c,
                    $user_data->{_hidden_data}->{user}->{id},
                    $organization_data->{_hidden_data}->{organization}->{id}
                  );
                if (   $is_organization_admin->{status} == 0
                    && $user_data->{_hidden_data}->{user}->{is_super_admin} ==
                    0 )

                {
                    $response->{status}     = 0;
                    $response->{message}    = "Invalid organization token.";
                    $response->{error_code} = 400;

                }
                else {
                    $groups =
                      Daedalus::Organizations::Manager::get_organization_groups(
                        $c,
                        $organization_data->{_hidden_data}->{organization}->{id}
                      );

                    if ( exists $groups->{data}->{$group_name} ) {
                        $response->{status}     = 0;
                        $response->{message}    = "Duplicated group name.";
                        $response->{error_code} = 400;
                    }
                    else {
                        $response =
                          Daedalus::Organizations::Manager::create_organization_group(
                            $c,
                            $organization_data->{_hidden_data}->{organization}
                              ->{id},
                            $group_name
                          );
                    }
                }

            }

        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );

}

sub add_role_group : Path('/organization/addrolegroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub add_role_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization_token;
    my $organization;
    my $organization_data;

    my $is_organization_admin;

    my $groups;
    my $group_name;

    my $role_name;
    my $available_roles;

    my $user = Daedalus::Users::Manager::is_admin_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 403;
    }
    else {
        $user_data = $user->{data};

        $organization_token = $c->{request}->{data}->{organization_token};
        $group_name         = $c->{request}->{data}->{group_name};
        $role_name          = $c->{request}->{data}->{role_name};

        $response->{message} = "";

        # Organization token and group name must be defined
        if ( !$organization_token ) {
            $response->{message} = "Organization token not provided.";
        }
        if ( !$group_name ) {
            $response->{message} =
              $response->{message} . " Group name not provided.";
        }

        if ( !$role_name ) {
            $response->{message} =
              $response->{message} . " Role name not provided.";
        }

        if ( $response->{message} ne "" ) {
            $response->{error_code} = 400;
            $response->{status}     = 0;
        }
        else {

            $organization =
              Daedalus::Organizations::Manager::get_organization_from_token( $c,
                $organization_token );

            if ( $organization->{status} == 0 ) {
                $response = $organization;
                $response->{error_code} = 400;

            }
            else {
                $organization_data = $organization->{organization};
                $is_organization_admin =
                  Daedalus::Users::Manager::is_organization_admin(
                    $c,
                    $user_data->{_hidden_data}->{user}->{id},
                    $organization_data->{_hidden_data}->{organization}->{id}
                  );
                if (   $is_organization_admin->{status} == 0
                    && $user_data->{_hidden_data}->{user}->{is_super_admin} ==
                    0 )

                {
                    $response->{status}     = 0;
                    $response->{message}    = "Invalid organization token.";
                    $response->{error_code} = 400;

                }
                else {
                    $groups =
                      Daedalus::Organizations::Manager::get_organization_groups(
                        $c,
                        $organization_data->{_hidden_data}->{organization}->{id}
                      );

                    if ( !exists $groups->{data}->{$group_name} ) {
                        $response->{status}  = 0;
                        $response->{message} = "Required group does not exist.";
                        $response->{error_code} = 400;
                    }
                    else {
                        if (
                            grep( /^$role_name$/,
                                @{ $groups->{data}->{$group_name}->{roles} } )
                          )
                        {
                            $response->{status} = 0;
                            $response->{message} =
"Required role is already assigned to this group.";
                            $response->{error_code} = 400;
                        }
                        else {
                            # Check role, name
                            $available_roles =
                              Daedalus::Organizations::Manager::list_roles($c);
                            if ( !exists $available_roles->{_hidden_data}
                                ->{$role_name} )
                            {
                                $response->{status} = 0;
                                $response->{message} =
                                  "Required role does not exist.";
                                $response->{error_code} = 400;
                            }
                            else {
                                $response =
                                  Daedalus::Organizations::Manager::add_role_to_organization_group(
                                    $c,
                                    $groups->{_hidden_data}->{$group_name}
                                      ->{id},
                                    $available_roles->{_hidden_data}
                                      ->{$role_name}->{id}
                                  );
                            }
                        }
                    }
                }

            }

        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
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
