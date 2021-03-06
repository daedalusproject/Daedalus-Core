package Daedalus::Core::Controller::Organizations;

use 5.026_001;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use JSON::XS;
use List::MoreUtils qw(any uniq);
use Daedalus::Utils::Constants qw(
  $bad_request
);

use base qw(Daedalus::Core::Controller::REST);

use Daedalus::Users::Manager;
use Daedalus::OrganizationGroups::Manager;
use Daedalus::Roles::Manager;

__PACKAGE__->config( default => 'application/json' );
__PACKAGE__->config( json_options => { relaxed => 1 } );

BEGIN { extends 'Daedalus::Core::Controller::REST'; return; }

our $VERSION = '0.01';

=head1 NAME

Daedalus::Core::Controller::Organizations - Catalyst Controller

=head1 SYNOPSIS

Daedalus::Core Organizations Controller.

=head1 DESCRIPTION

Daedalus::Core /organization endpoint.

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS

=head2 begin

Begin function

=cut

sub begin : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    return;
}

=head2 create_organization

Create Organization.

Only admin users are allowed to perform this operation.

Required data:   - Organization name

=cut

sub create_organization : Path('/organization/create') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 create_organization_POST

/organization/create is a POST request

=cut

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
                    name                           => "string",
                    required                       => 1,
                    forbid_empty                   => 1,
                    associated_model               => "CoreRealms",
                    associated_model_source        => "Organization",
                    associated_model_source_column => "name",
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
          Daedalus::Organizations::Manager::create_organization( $c,
            $user_data, $required_data );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
    }
    return $self->return_response( $c, $response );
}

=head2 show_organizations

Users are allowed to show their organizations

=cut

sub show_organizations : Path('/organization/show') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 show_organizations_GET

/organization/show is a GET request

=cut

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

    return $self->return_response( $c, $response );
}

=head2 show_organization_users

Admin users are allowed to view its organization users.

Required data:   - Organation token as request argument

=cut

sub show_organization_users : Path('/organization/showusers') : Args(1) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 show_organization_users_GET

/organization/showusers is a GET request

=cut

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
    return $self->return_response( $c, $response );
}

=head2 add_user_to_organization

Adds (registered and active) User Organization.

Admin users are allowed to add its registered users to their organizations.

Required data:   - User Token   - Organation token

=cut

sub add_user_to_organization : Path('/organization/adduser') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 add_user_to_organization_POST

/organization/adduser is a POST request

=cut

sub add_user_to_organization_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;
    my $organization;
    my $target_user;

    $response->{message} = q{};
    $response->{status}  = 1;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                user_token => {
                    type     => "active_user_token",
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
          $authorization_and_validatation->{data}->{'registered_user_token'};

        $response =
          Daedalus::Organizations::Manager::add_user_to_organization( $c,
            $target_user, $organization, );
        $response->{error_code} = $bad_request;
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    return $self->return_response( $c, $response );

}

=head2 show_organizations_groups

Users are allowed to view the organization group they belong.

Data is separated by organization.

=cut

sub show_organizations_groups : Path('/organization/showusergroups') : Args(0)
  : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 show_organizations_groups_GET

/organization/showusergroups is a GET request

=cut

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
    return $self->return_response( $c, $response );
}

=head2 show_organization_groups

Same behaviour than show_organizations_groups but this function only show groups from required organization.

=cut

sub show_organization_groups : Path('/organization/showorganizationusergroups')
  : Args(1) : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 show_organization_groups_GET

/organization/showorganizationusergroups/{OrganizationToken} is a GET request

=cut

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

        $response->{error_code} = $bad_request;
        $response->{status}     = 1;
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    return $self->return_response( $c, $response );
}

=head2 show_all_organization_groups

Admin users are allowed to view all their organization groups.

For each group, their users and roles are shown.

OrganizationToken is required

=cut

sub show_all_organization_groups : Path('/organization/showallgroups')
  : Args(1) : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 show_all_organization_groups_GET

/organization/showallgroups/{OrganizationToken} is a GET request

=cut

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
        $response->{error_code}             = $bad_request;

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    return $self->return_response( $c, $response );
}

=head2 create_organization_group

Create Organization group.

Only admin users are allowed to perform this operation.

Required data:   - Organation token   - Unique group name

=cut

sub create_organization_group : Path('/organization/creategroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 create_organization_group_POST

/organization/creategroup is a POST request

=cut

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
                    type                           => "string",
                    required                       => 1,
                    forbid_empty                   => 1,
                    associated_model               => "CoreRealms",
                    associated_model_source        => "OrganizationGroup",
                    associated_model_source_column => "group_name",
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

        $response->{error_code} = $bad_request;
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
    return $self->return_response( $c, $response );
}

=head2 add_role_to_group

Adds role to Organization group.

Only admin users are allowed to perform this operation.

Required data:   - Organation token   - Group token   - Role name

=cut

sub add_role_to_group : Path('/organization/addroletogroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 add_role_to_group_POST

/organization/addroletogroup is a POST request

=cut

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
            $response->{error_code} = $bad_request;
        }

        else {
            if ( $group->{_hidden_data}->{$group_token}->{organization_id} !=
                $organization->{_hidden_data}->{organization}->{id} )
            {
                $response->{status}     = 0;
                $response->{message}    = "Required group does not exist.";
                $response->{error_code} = $bad_request;
            }
            else {
                if (
                    any { /^$role_name$/sxm }
                    uniq @{ $group->{data}->{$group_token}->{roles} }
                  )

                {
                    $response->{status} = 0;
                    $response->{message} =
                      "Required role is already assigned to this group.";
                    $response->{error_code} = $bad_request;
                }
                else {
                    # Check role, name
                    $available_roles = Daedalus::Roles::Manager::list_roles($c);
                    if (
                        !exists $available_roles->{_hidden_data}->{$role_name} )
                    {
                        $response->{status}  = 0;
                        $response->{message} = "Required role does not exist.";
                        $response->{error_code} = $bad_request;
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
    return $self->return_response( $c, $response );

}

=head2 remove_role_group

Removes role from Organization group.

Only admin users are allowed to perform this operation.

Required data:   - Organation token   - Group token   - Role name

If removing this group causes the absence of admins in this organization, the operation is not allowed, Super Admins
are still allowed to perform this action.

=cut

sub remove_role_group : Path('/organization/removerolefromgroup') : Args(3)
  : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 remove_existent_role

Removes existent role from group

=cut

sub remove_existent_role {

    my $c    = shift;
    my $data = shift;

    my $group_token     = $data->{group_token};
    my $available_roles = $data->{available_roles};
    my $groups          = $data->{groups};
    my $group           = $data->{group};
    my $organization    = $data->{organization};
    my $role_name       = $data->{role_name};
    my $user_data       = $data->{user_data};

    my $count_roles;
    my $removal_allowed = 1;

    my $response;
    $response->{status}  = 1;
    $response->{message} = q{};

    if ( $group->{_hidden_data}->{$group_token}->{organization_id} !=
        $organization->{_hidden_data}->{organization}->{id} )
    {
        $response->{status}     = 0;
        $response->{message}    = "Required group does not exist.";
        $response->{error_code} = $bad_request;
    }
    else {
        $available_roles = Daedalus::Roles::Manager::list_roles($c);

        if ( !exists $available_roles->{_hidden_data}->{$role_name} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required role does not exist.";
            $response->{error_code} = $bad_request;
        }
        else {
            if (
                any { /^$role_name$/sxm }
                uniq @{ $group->{data}->{$group_token}->{roles} }
              )
            {

                if (   $role_name eq 'organization_master'
                    && $user_data->{_hidden_data}->{user}->{is_super_admin} ==
                    0 )
                {
                    $groups =
                      Daedalus::Organizations::Manager::get_organization_groups(
                        $c,
                        $organization->{_hidden_data}->{organization}->{id} );

                    $count_roles =
                      Daedalus::Roles::Manager::count_roles( $c,
                        $groups->{data}, 'organization_master' );
                    if ( $count_roles < 2 ) {
                        $removal_allowed        = 0;
                        $response->{status}     = 0;
                        $response->{error_code} = $bad_request;
                        $response->{message} =
'Cannot remove this role, no more admin roles will left in this organization.';
                    }
                }
                if ($removal_allowed) {
                    $response =
                      Daedalus::Organizations::Manager::remove_role_from_organization_group(
                        $c,
                        $group->{_hidden_data}->{$group_token}->{id},
                        $available_roles->{_hidden_data}->{$role_name}->{id}
                      );
                    $response->{error_code} = $bad_request;
                }
            }
            else {
                $response->{status} = 0;
                $response->{message} =
                  "Required role is not assigned to this group.";
                $response->{error_code} = $bad_request;

            }
        }

    }
    return $response;
}

=head2 remove_role_group_DELETE

/organization/removerolefromgroup/{OrganizationToken}/{GroupToken}/{role_name} is a DELETE request

=cut

sub remove_role_group_DELETE {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $group;
    my $groups;
    my $group_token;

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
                    type  => 'organization',
                    given => 1,
                    value => $c->{request}->{arguments}[0],
                },
                group_token => {
                    type  => "string",
                    given => 1,
                    value => $c->{request}->{arguments}[1],
                },
                role_name => {
                    type  => "string",
                    given => 1,
                    value => $c->{request}->{arguments}[2],
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

        $group_token =
          $authorization_and_validatation->{data}->{required_data}
          ->{group_token};
        $role_name =
          $authorization_and_validatation->{data}->{required_data}->{role_name};

        $group =
          Daedalus::OrganizationGroups::Manager::get_organization_group_from_token(
            $c, $group_token );
        if ( !exists $group->{data}->{$group_token} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = $bad_request;
        }
        else {
            $response = remove_existent_role(
                $c,
                {
                    'group_token'     => $group_token,
                    'available_roles' => $available_roles,
                    'group_token'     => $group_token,
                    'groups'          => $groups,
                    'group'           => $group,
                    'organization'    => $organization,
                    'role_name'       => $role_name,
                    'user_data'       => $user_data,
                }
            );
        }
    }
    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    return $self->return_response( $c, $response );

}

=head2 add_user_to_group

Adds Organization user to Organization group.

Only admin users are allowed to perform this operation.

Required data:   - Organation token   - Group token   - User Token

=cut

sub add_user_to_group : Path('/organization/addusertogroup') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 add_user_to_group_POST

/organization/addusertogroup is a POST request.

=cut

sub add_user_to_group_POST {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $group;
    my $group_token;

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
                group_token => {
                    type     => "string",
                    required => 1,
                },
                user_token => {
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
          $authorization_and_validatation->{data}->{'registered_user_token'};
        $group_token =
          $authorization_and_validatation->{data}->{required_data}
          ->{group_token};

        $user_email = $target_user->{data}->{user}->{'e-mail'};

        $group =
          Daedalus::OrganizationGroups::Manager::get_organization_group_from_token(
            $c, $group_token );

        if ( !exists $group->{data}->{$group_token} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = $bad_request;
        }
        else {
            if ( $group->{_hidden_data}->{$group_token}->{organization_id} !=
                $organization->{_hidden_data}->{organization}->{id} )
            {
                $response->{status}     = 0;
                $response->{message}    = "Required group does not exist.";
                $response->{error_code} = $bad_request;
            }
            else {

                if (
                    exists(
                        $group->{data}->{$group_token}->{users}->{$user_email}
                    )
                  )
                {
                    $response->{status} = 0;
                    $response->{message} =
                      "Required user is already assigned to this group.";
                    $response->{error_code} = $bad_request;
                }
                else {
                    $response =
                      Daedalus::Organizations::Manager::add_user_to_organization_group(
                        $c,
                        $group->{_hidden_data}->{$group_token}->{id},
                        $target_user->{_hidden_data}->{user}->{id}
                      );
                }
            }
        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    return $self->return_response( $c, $response );

}

=head2 remove_user_group

Removes Organization user from Organization group.

Only admin users are allowed to perform this operation.

Required data:   - Organation token   - Group token   - UserToken

If removing this user causes the absence of admins in this organization, the operation is not allowed, Super Admins are
still allowed to perform this action.

=cut

sub remove_user_group : Path('/organization/removeuserfromgroup') : Args(3)
  : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 remove_user_group_DELETE

/organization/removerolefromgroup/{OrganizationToken}/{UserToken}/{role_name} is a DELETE request

=cut

sub remove_user_group_DELETE {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $group;
    my $groups;
    my $group_token;

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
                    type  => 'organization',
                    given => 1,
                    value => $c->{request}->{arguments}[0],
                },
                group_token => {
                    type  => "string",
                    given => 1,
                    value => $c->{request}->{arguments}[1],
                },
                user_token => {
                    type  => "organization_user",
                    given => 1,
                    value => $c->{request}->{arguments}[2],
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
          $authorization_and_validatation->{data}->{'registered_user_token'};
        $group_token =
          $authorization_and_validatation->{data}->{required_data}
          ->{group_token};
        $user_email = $target_user->{data}->{user}->{'e-mail'};

        $group =
          Daedalus::OrganizationGroups::Manager::get_organization_group_from_token(
            $c, $group_token );

        if ( !exists $group->{data}->{$group_token} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = $bad_request;
        }
        else {
            if (
                exists(
                    $group->{data}->{$group_token}->{users}->{$user_email}
                )
              )
            {
                if (
                    any { /^organization_master$/sxm }
                    uniq @{ $group->{data}->{$group_token}->{roles} }
                  )
                {
                    $groups =
                      Daedalus::Organizations::Manager::get_organization_groups(
                        $c,
                        $organization->{_hidden_data}->{organization}->{id} );
                    $count_organization_admins =
                      Daedalus::OrganizationGroups::Manager::count_organization_admins(
                        $c, $groups->{data}, 'organization_master' );
                    if (   $count_organization_admins < 2
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
                        $group->{_hidden_data}->{$group_token}->{id},
                        $target_user->{_hidden_data}->{user}->{id}
                      );
                    $response->{error_code} = $bad_request;
                }
                else {
                    $response->{status}     = 0;
                    $response->{error_code} = $bad_request;
                    $response->{message} =
'Cannot remove this user, no more admin users will left in this organization.';

                }
            }
            else {
                $response->{status} = 0;
                $response->{message} =
                  'Required user does not belong to this group.';
                $response->{error_code} = $bad_request;

            }
        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    return $self->return_response( $c, $response );
}

=head2 remove_organization_group

Removes Organization group.

Only admin users are allowed to perform this operation.

Required data:   - Organation token   - Group token

If removing this group causes the absence of admins in this organization, the operation is not allowed, Super Admins
are still allowed to perform this action.

=cut

sub remove_organization_group :
  Path('/organization/removeorganizationgroup') : Args(2) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 remove_organization_group_DELETE

/organization/removerolefromgroup/{OrganizationToken}/{GroupToken} is a DELETE request

=cut

sub remove_organization_group_DELETE {

    my ( $self, $c ) = @_;

    my $response;
    my $user_data;

    my $organization;

    my $group;
    my $groups;
    my $group_token;

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
                    type  => 'organization',
                    given => 1,
                    value => $c->{request}->{arguments}[0],
                },
                group_token => {
                    type  => "string",
                    given => 1,
                    value => $c->{request}->{arguments}[1],
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
        $group_token =
          $authorization_and_validatation->{data}->{required_data}
          ->{group_token};

        $group =
          Daedalus::OrganizationGroups::Manager::get_organization_group_from_token(
            $c, $group_token );

        if ( !exists $group->{data}->{$group_token} ) {
            $response->{status}     = 0;
            $response->{message}    = "Required group does not exist.";
            $response->{error_code} = $bad_request;
        }
        else {
            if ( $group->{_hidden_data}->{$group_token}->{organization_id} !=
                $organization->{_hidden_data}->{organization}->{id} )
            {
                $response->{status}     = 0;
                $response->{message}    = "Required group does not exist.";
                $response->{error_code} = $bad_request;
            }
            else {
                if (
                    any { /^organization_master$/sxm }
                    uniq @{ $group->{data}->{$group_token}->{roles} }
                  )
                {
                    $groups =
                      Daedalus::Organizations::Manager::get_organization_groups(
                        $c,
                        $organization->{_hidden_data}->{organization}->{id} );

                    $count_organization_admins =
                      Daedalus::OrganizationGroups::Manager::count_organization_admins(
                        $c, $groups->{data}, 'organization_master' );
                    if (   $count_organization_admins < 2
                        && $user_data->{_hidden_data}->{user}->{is_super_admin}
                        == 0 )
                    {
                        $removal_allowed = 0;
                    }
                }
                if ($removal_allowed) {

                    $response =
                      Daedalus::OrganizationGroups::Manager::remove_organization_group(
                        $c, $group->{_hidden_data}->{$group_token}->{id},
                      );
                    $response->{error_code} = $bad_request;
                }
                else {
                    $response->{status}     = 0;
                    $response->{error_code} = $bad_request;
                    $response->{message} =
'Cannot remove this group, no more admin users will left in this organization.';
                }
            }
        }

    }

    $response->{_hidden_data}->{user} = $user_data->{_hidden_data}->{user};
    return $self->return_response( $c, $response );
}

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

__PACKAGE__->meta->make_immutable;

1;
