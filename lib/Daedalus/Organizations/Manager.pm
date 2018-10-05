package Daedalus::Organizations::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Organizations::Manager

=cut

use strict;
use warnings;
use Moose;

use Daedalus::Utils::Crypt;
use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::Organizations::Manager

=cut

=head1 DESCRIPTION

Daedalus Organizations Manager

=head1 METHODS

=cut

=head2 create_organization

Creates a new Organization

=cut

sub create_organization {

    my $c         = shift;
    my $user_data = shift;

    my $response;
    my $user_id;

    my $organization_data = $c->{request}->{data}->{organization_data};

    my $request_organization_name = $organization_data->{name};
    if ( !$request_organization_name ) {
        $response->{status}     = 0;
        $response->{message}    = "Invalid organization data.";
        $response->{error_code} = 400;
    }
    else {
        chomp $request_organization_name;

        $user_id = $user_data->{_hidden_data}->{user}->{id};

        my @user_organizations_rs = $c->model('CoreRealms::UserOrganization')
          ->search( { user_id => $user_id } )->all;

        my @organization_names;

        for my $user_organization (@user_organizations_rs) {
            push @organization_names, $user_organization->organization()->name;
        }

        if ( grep( /^$request_organization_name$/, @organization_names ) ) {
            $response = {
                status     => 0,
                error_code => 400,
                message    => 'Duplicated organization name.',
            };

        }
        else {

            # Get organization_master role id

            my $organization_master_role_id = $c->model('CoreRealms::Role')
              ->find( { 'role_name' => 'organization_master' } )->id;

            # Create Organization

            my $organization_token =
              Daedalus::Utils::Crypt::generateRandomString(32);
            my $organization = $c->model('CoreRealms::Organization')->create(
                {
                    name  => $request_organization_name,
                    token => $organization_token
                }
            );

            # Add user to Organization
            my $user_organization =
              $c->model('CoreRealms::UserOrganization')->create(
                {
                    organization_id => $organization->id,
                    user_id         => $user_id,
                }
              );

            # Create an organization admin group

            my $organization_group =
              $c->model('CoreRealms::OrganizationGroup')->create(
                {
                    organization_id => $organization->id,
                    group_name      => "$request_organization_name"
                      . " Administrators",
                }
              );

            # This group has orgaization_master role
            my $organization_group_role =
              $c->model('CoreRealms::OrganizationGroupRole')->create(
                {
                    group_id => $organization_group->id,
                    role_id  => $organization_master_role_id,
                }
              );

            $response = {
                status  => 1,
                message => 'Organization created.',
                data    => {
                    organization => {
                        organization_token => $organization->token,
                    },
                },
                _hidden_data => {
                    organization => {
                        organization_id => $organization->id,
                    },
                },
            };

        }
    }
    return $response;
}

=head2 get_organizations_from_user

For a given user, show its organizations

=cut

sub get_organizations_from_user {

    my $c         = shift;
    my $user_data = shift;
    my $short_key = shift;

    my $response = {
        status => 1,
        data   => {
            organizations => {},
        },
        _hidden_data => {
            organizations => {}
        },
    };

    my $user_id = $user_data->{_hidden_data}->{user}->{id};

    my @user_organizations = $c->model('CoreRealms::UserOrganization')
      ->search( { user_id => $user_id } )->all();

    my @organizations_names;
    my %organizations;

    if ( $short_key eq 'token' ) {
        for my $user_organization (@user_organizations) {
            my $organization = $c->model('CoreRealms::Organization')
              ->find( { id => $user_organization->organization_id } );
            $response->{data}->{organizations}->{ $organization->token } =
              { name => $organization->name, token => $organization->token };
            $response->{_hidden_data}->{organizations}->{ $organization->token }
              = { id => $organization->id };
        }

    }
    else {
        for my $user_organization (@user_organizations) {
            my $organization = $c->model('CoreRealms::Organization')
              ->find( { id => $user_organization->organization_id } );
            $response->{data}->{organizations}->{ $organization->name } =
              { name => $organization->name, token => $organization->token };
            $response->{_hidden_data}->{organizations}->{ $organization->name }
              = { id => $organization->id };
        }
    }

    return $response;
}

=head2 get_organization_from_token

For a given organization token, return organization data

=cut

sub get_organization_from_token {

    my $c                  = shift;
    my $organization_token = shift;

    my $response;
    $response->{status}  = 0;
    $response->{message} = 'Invalid Organization token.';

    my $organization = $c->model('CoreRealms::Organization')
      ->find( { token => $organization_token } );

    if ($organization) {
        $response->{status}       = 1;
        $response->{message}      = 'Organization token is valid.';
        $response->{organization} = {
            data => {
                organization => {
                    name  => $organization->name,
                    token => $organization->token,
                },
            },
            _hidden_data => { organization => { id => $organization->id } }
        };
    }

    return $response;
}

=head2 add_user_to_organization_group

Adds user to organization token

=cut

sub add_user_to_organization {

    my $c                = shift;
    my $user_data        = shift;
    my $organizaion_data = shift;

    my $response;

    my $user_organizations =
      get_organizations_from_user( $c, $user_data, 'token' );

    my $organization_token = $organizaion_data->{data}->{organization}->{token};

    if ( $user_organizations->{data}->{organizations}->{$organization_token} ) {
        $response->{status}  = 0;
        $response->{message} = "User already belongs to this organization.";
    }
    else {
        # Add user to Organization
        $c->model('CoreRealms::UserOrganization')->create(
            {
                organization_id =>
                  $organizaion_data->{_hidden_data}->{organization}->{id},
                user_id => $user_data->{_hidden_data}->{user}->{id},
            }
        );

        $response->{status}  = 1;
        $response->{message} = "User has been registered.";
    }

    return $response;
}

=head2 get_organization_group_roles

Get organization group roles using organization_group id

=cut

sub get_organization_group_roles {

    my $c                     = shift;
    my $organization_group_id = shift;

    my $response = { data => [], _hidden_data => {} };

    my @roles = $c->model('CoreRealms::OrganizationGroupRole')
      ->search( { group_id => $organization_group_id } )->all;

    for my $role (@roles) {
        my $role_info =
          $c->model('CoreRealms::Role')->find( { id => $role->id } );
        push @{ $response->{data} }, $role_info->role_name;
        $response->{_hidden_data}->{ $role_info->role_name } = $role_info->id;
    }

    return $response;
}

=head2 get_organization_groups

Get organization groups using organization id

=cut

sub get_organization_groups {

    my $c               = shift;
    my $organization_id = shift;

    my $response = { data => {}, _hidden_data => {} };

    my @organization_groups = $c->model('CoreRealms::OrganizationGroup')
      ->search( { organization_id => $organization_id } )->all;

    for my $organization_group (@organization_groups) {
        my $roles = get_organization_group_roles( $c, $organization_group->id );
        $response->{data}->{ $organization_group->group_name } =
          { roles => $roles->{data} };
        $response->{_hidden_data}->{ $organization_group->group_name } =
          { id => $organization_group->id, roles => $roles->{_hidden_data} };
    }

    return $response;
}

=head2 get_user_organization_groups

Get user groups for each organization

=cut

sub get_user_organizations_groups {

    my $c         = shift;
    my $user_data = shift;

    my $user_organizations = get_organizations_from_user( $c, $user_data );

    for my $organization_name (
        keys %{ $user_organizations->{data}->{organizations} } )
    {
        my $organization_id =
          $user_organizations->{_hidden_data}->{organizations}
          ->{$organization_name}->{id};
        my $organization_groups =
          get_organization_groups( $c, $organization_id );
        $user_organizations->{data}->{organizations}->{$organization_name}
          ->{groups} = $organization_groups->{data};
        $user_organizations->{_hidden_data}->{organizations}
          ->{$organization_name}->{groups} =
          $organization_groups->{_hidden_data};

    }

    return $user_organizations;
}

=head2 get_user_organization_groups

Get user groups for given organization

=cut

sub get_user_organization_groups {

    my $c                 = shift;
    my $user_data         = shift;
    my $organization_data = shift;

    my $user_organization_groups;
    my $organization_id =
      $organization_data->{_hidden_data}->{organization}->{id};

    my $organization_groups = get_organization_groups( $c,
        $organization_data->{_hidden_data}->{organization}->{id} );
    $user_organization_groups->{data}->{groups} = $organization_groups->{data};
    $user_organization_groups->{_hidden_data}->{groups} =
      $organization_groups->{_hidden_data};

    return $user_organization_groups;
}

=head2 create_organization_group

Creates new organization group

=cut

sub create_organization_group {
    my $c               = shift;
    my $organization_id = shift;
    my $group_name      = shift;

    my $response;
    my $organization_group;

    $organization_group = $c->model('CoreRealms::OrganizationGroup')->create(
        {
            organization_id => $organization_id,
            group_name      => $group_name
        }
    );

    $response->{status} = 1;
    $response->{data}->{organization_groups} =
      { "group_name" => $organization_group->group_name };
    $response->{_hidden_data}->{organization_groups} =
      { "id" => $organization_group->id };
    $response->{message} = "Organization group has been created.";

    return $response;
}

=head2 list_roles

Lists available roles

=cut

sub list_roles {
    my $c = shift;

    my $roles = { data => [], _hidden_data => {} };

    my @available_roles = $c->model('CoreRealms::Role')
      ->search( { role_name => { 'not in' => ['daedalus_manager'] } } )->all;

    for my $role (@available_roles) {
        push @{ $roles->{data} }, $role->role_name;
        $roles->{_hidden_data}->{ $role->role_name } = { id => $role->id };
    }
    return $roles;
}

__PACKAGE__->meta->make_immutable;
1;
