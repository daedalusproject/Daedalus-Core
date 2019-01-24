package Daedalus::Core::Controller::Organizations;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON::XS;
use Data::Dumper;

use base qw(Daedalus::Core::Controller::REST);

use Daedalus::Users::Manager;
use Daedalus::OrganizationGroups::Manager;

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
    my $organization;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type  => "organization",
                    given => 1,
                    value => $c->{request}->{arguments}[0],
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};

        $response = Daedalus::Users::Manager::get_organization_users(
            $c,
            $organization->{_hidden_data}->{organization}->{id},
            $user_data->{_hidden_data}->{user}->{is_super_admin}
        );

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
    my $organization;
    my $target_user;

    $response->{message} = "";
    $response->{status}  = 1;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                user_email => {
                    type     => "active_user_e-mail",
                    required => 1,
                },
                organization_token => {
                    type     => "organization",
                    required => 1,
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};
        $target_user =
          $authorization_and_validatation->{data}->{'registered_user_e-mail'};

        $response =
          Daedalus::Organizations::Manager::add_user_to_organization( $c,
            $target_user, $organization, );
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

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'user',
            },
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data = $authorization_and_validatation->{data}->{user_data};

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

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type => 'organization'
            },
            required_data => {
                organization_token => {
                    type  => "organization",
                    given => 1,
                    value => $c->{request}->{arguments}[0],
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};

        $response =
          Daedalus::Organizations::Manager::get_user_organization_groups( $c,
            $user_data, $organization );

        $response->{error_code} = 400;
        $response->{status}     = 1;
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );
}

sub show_all_organization_groups : Path('/organization/showallgroups')
  : Args(1) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub show_all_organization_groups_GET {

    my ( $self, $c ) = @_;
    my $response;
    my $user_data;

    my $organization;

    my $groups;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,

        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type  => "organization",
                    given => 1,
                    value => $c->{request}->{arguments}[0],

                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};

        $groups =
          Daedalus::Organizations::Manager::get_organization_groups( $c,
            $organization->{_hidden_data}->{organization}->{id} );
        $response->{data}->{groups}         = $groups->{data};
        $response->{_hidden_data}->{groups} = $groups->{_hidden_data};
        $response->{status}                 = 1;
        $response->{error_code}             = 400;

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

    my $organization;

    my $groups;
    my $group_name;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type     => "organization",
                    required => 1,
                },
                group_name => {
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
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};
        $group_name   = $authorization_and_validatation->{data}->{required_data}
          ->{group_name};

        $groups =
          Daedalus::Organizations::Manager::get_organization_groups( $c,
            $organization->{_hidden_data}->{organization}->{id} );

        $response->{error_code} = 400;
        if ( exists $groups->{data}->{$group_name} ) {
            $response->{status}  = 0;
            $response->{message} = "Duplicated group name.";
        }
        else {
            $response =
              Daedalus::Organizations::Manager::create_organization_group( $c,
                $organization->{_hidden_data}->{organization}->{id},
                $group_name );
        }
    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );

}

sub add_role_to_group : Path('/organization/addroletogroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub add_role_to_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $group;
    my $group_token;

    my $role_name;
    my $available_roles;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type     => "organization",
                    required => 1,
                },
                group_token => {
                    type     => "string",
                    required => 1,
                },
                role_name => {
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
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};
        $group_token  = $authorization_and_validatation->{data}->{required_data}
          ->{group_token};
        $role_name =
          $authorization_and_validatation->{data}->{required_data}->{role_name};

        $group =
          Daedalus::OrganizationGroups::Manager::get_organization_group_from_token(
            $c, $group_token );

        if ( !exists $group->{data}->{$group_token} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = 400;
        }

        else {
            if ( $group->{_hidden_data}->{$group_token}->{organization_id} !=
                    $organization->{_hidden_data}->{organization}->{id}
                and $user_data->{_hidden_data}->{user}->{is_super_admin} == 0 )
            {
                $response->{status}     = 0;
                $response->{message}    = "Required group does not exist.";
                $response->{error_code} = 400;
            }
            else {
                if (
                    grep( /^$role_name$/,
                        @{ $group->{data}->{$group_token}->{roles} } )
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
                    if (
                        !exists $available_roles->{_hidden_data}->{$role_name} )
                    {
                        $response->{status}  = 0;
                        $response->{message} = "Required role does not exist.";
                        $response->{error_code} = 400;
                    }
                    else {
                        $response =
                          Daedalus::Organizations::Manager::add_role_to_organization_group(
                            $c,
                            $group->{_hidden_data}->{$group_token}->{id},
                            $available_roles->{_hidden_data}->{$role_name}->{id}
                          );
                    }
                }
            }
        }

    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );

}

sub remove_role_group : Path('/organization/removerolegroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub remove_role_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $groups;
    my $group_name;

    my $role_name;
    my $available_roles;

    my $removal_allowed = 1;
    my $count_roles;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type     => 'organization',
                    required => 1,
                },
                group_name => {
                    type     => "string",
                    required => 1,
                },
                role_name => {
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
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};

        $group_name = $authorization_and_validatation->{data}->{required_data}
          ->{group_name};
        $role_name =
          $authorization_and_validatation->{data}->{required_data}->{role_name};

        $groups =
          Daedalus::Organizations::Manager::get_organization_groups( $c,
            $organization->{_hidden_data}->{organization}->{id} );
        if ( !exists $groups->{data}->{$group_name} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = 400;
        }
        else {
            $available_roles = Daedalus::Organizations::Manager::list_roles($c);

            if ( !exists $available_roles->{_hidden_data}->{$role_name} ) {
                $response->{status}     = 0;
                $response->{message}    = "Required role does not exist.";
                $response->{error_code} = 400;
            }

            else {
                if (
                    grep( /^$role_name$/,
                        @{ $groups->{data}->{$group_name}->{roles} } )
                  )
                {

                    if (   $role_name eq 'organization_master'
                        && $user_data->{_hidden_data}->{user}->{is_super_admin}
                        == 0 )
                    {
                        $count_roles =
                          Daedalus::OrganizationGroups::Manager::count_roles(
                            $c, $groups->{data}, 'organization_master' );
                        if ( $count_roles lt 2 ) {
                            $removal_allowed        = 0;
                            $response->{status}     = 0;
                            $response->{error_code} = 400;
                            $response->{message} =
'Cannot remove this role, no more admin roles will left in this organization.';
                        }
                    }
                    if ($removal_allowed) {
                        $response =
                          Daedalus::Organizations::Manager::remove_role_from_organization_group(
                            $c,
                            $groups->{_hidden_data}->{$group_name}->{id},
                            $available_roles->{_hidden_data}->{$role_name}->{id}
                          );
                        $response->{error_code} = 400;

                    }
                }
                else {
                    $response->{status} = 0;
                    $response->{message} =
                      "Required role is not assigned to this group.";
                    $response->{error_code} = 400;

                }
            }

        }
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );

}

sub add_user_to_group : Path('/organization/addusertogroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub add_user_to_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $groups;
    my $group_name;

    my $required_user;
    my $required_user_data;

    my $user_email;
    my $target_user;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type     => 'organization',
                    required => 1,
                },
                group_name => {
                    type     => "string",
                    required => 1,
                },
                user_email => {
                    type     => "organization_user",
                    required => 1,
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};
        $target_user =
          $authorization_and_validatation->{data}->{'registered_user_e-mail'};
        $group_name = $authorization_and_validatation->{data}->{required_data}
          ->{group_name};

        $user_email = $target_user->{data}->{user}->{'e-mail'};
        $groups =
          Daedalus::Organizations::Manager::get_organization_groups( $c,
            $organization->{_hidden_data}->{organization}->{id} );

        if ( !exists $groups->{data}->{$group_name} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = 400;
        }
        else {
            if (
                grep( /^$user_email$/,
                    @{ $groups->{data}->{$group_name}->{users} } )
              )
            {
                $response->{status} = 0;
                $response->{message} =
                  "Required user is already assigned to this group.";
                $response->{error_code} = 400;
            }
            else {
                $response =
                  Daedalus::Organizations::Manager::add_user_to_organization_group(
                    $c,
                    $groups->{_hidden_data}->{$group_name}->{id},
                    $target_user->{_hidden_data}->{user}->{id}
                  );
            }
        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );

}

sub remove_user_group : Path('/organization/removeuserfromgroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub remove_user_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $groups;
    my $group_name;

    my $user_email;

    my $removal_allowed = 1;
    my $count_organization_admins;

    my $target_user;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type     => 'organization',
                    required => 1,
                },
                group_name => {
                    type     => "string",
                    required => 1,
                },
                user_email => {
                    type     => "organization_user",
                    required => 1,
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};
        $target_user =
          $authorization_and_validatation->{data}->{'registered_user_e-mail'};
        $group_name = $authorization_and_validatation->{data}->{required_data}
          ->{group_name};
        $user_email = $target_user->{data}->{user}->{'e-mail'};

        $groups =
          Daedalus::Organizations::Manager::get_organization_groups( $c,
            $organization->{_hidden_data}->{organization}->{id} );
        if ( !exists $groups->{data}->{$group_name} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = 400;
        }
        else {
            if (

                grep( /^$user_email$/,
                    @{ $groups->{data}->{$group_name}->{users} } )
              )
            {
                if (
                    grep ( /^organization_master$/,
                        @{ $groups->{data}->{$group_name}->{roles} } )
                  )
                {
                    $count_organization_admins =
                      Daedalus::OrganizationGroups::Manager::count_organization_admins(
                        $c, $groups->{data}, 'organization_master' );
                    if (   $count_organization_admins lt 2
                        && $user_data->{_hidden_data}->{user}->{is_super_admin}
                        == 0 )
                    {
                        $removal_allowed = 0;
                    }
                }
                if ($removal_allowed) {

                    $response =
                      Daedalus::OrganizationGroups::Manager::remove_user_from_organization_group(
                        $c,
                        $groups->{_hidden_data}->{$group_name}->{id},
                        $target_user->{_hidden_data}->{user}->{id}
                      );
                    $response->{error_code} = 400;
                }
                else {
                    $response->{status}     = 0;
                    $response->{error_code} = 400;
                    $response->{message} =
'Cannot remove this user, no more admin users will left in this organization.';

                }
            }
            else {
                $response->{status} = 0;
                $response->{message} =
                  'Required user does not belong to this group.';
                $response->{error_code} = 400;

            }
        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );
}

sub remove_organization_group : Path('/organization/removeorganizationgroup') :
  Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub remove_organization_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $groups;
    my $group_name;

    my $removal_allowed = 1;
    my $count_organization_admins;

    my $target_user;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                organization_token => {
                    type     => 'organization',
                    required => 1,
                },
                group_name => {
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
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $organization = $authorization_and_validatation->{data}->{organization};
        $group_name   = $authorization_and_validatation->{data}->{required_data}
          ->{group_name};

        $groups =
          Daedalus::Organizations::Manager::get_organization_groups( $c,
            $organization->{_hidden_data}->{organization}->{id} );
        if ( !exists $groups->{data}->{$group_name} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = 400;
        }
        else {
            if (
                grep ( /^organization_master$/,
                    @{ $groups->{data}->{$group_name}->{roles} } )
              )
            {
                $count_organization_admins =
                  Daedalus::OrganizationGroups::Manager::count_organization_admins(
                    $c, $groups->{data}, 'organization_master' );
                if (   $count_organization_admins lt 2
                    && $user_data->{_hidden_data}->{user}->{is_super_admin} ==
                    0 )
                {
                    $removal_allowed = 0;
                }
            }
            if ($removal_allowed) {

                $response =
                  Daedalus::OrganizationGroups::Manager::remove_organization_group(
                    $c, $groups->{_hidden_data}->{$group_name}->{id},
                  );
                $response->{error_code} = 400;
            }
            else {
                $response->{status}     = 0;
                $response->{error_code} = 400;
                $response->{message} =
'Cannot remove this group, no more admin users will left in this organization.';
            }
        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    $self->return_response( $c, $response );

}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;

1;
