package Daedalus::OrganizationGroups::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::OrganizationGroups::Manager

=cut

use strict;
use warnings;
use Moose;

use Daedalus::Organizations::Manager;
use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::OrganizationGroups::Manager

=cut

=head1 DESCRIPTION

Daedalus Organization Groups Manager

=head1 METHODS

=cut

=head2 count_roles

Counts how many roles have "role_name" assigned

=cut

sub count_roles {

    my $c         = shift;
    my $groups    = shift;
    my $role_name = shift;

    my $count = 0;

    for my $group_name ( keys %{$groups} ) {
        if ( grep( /^$role_name$/, @{ $groups->{$group_name}->{roles} } ) ) {
            $count = $count + 1;
        }
    }

    return $count;
}

=head2 count_organization_admins

Counts how many users are admin user of given organization

=cut

sub count_organization_admins {

    my $c         = shift;
    my $groups    = shift;
    my $role_name = shift;

    my $count = 0;

    my @groups_with_selected_role;

    for my $group_name ( keys %{$groups} ) {
        if ( grep( /^$role_name$/, @{ $groups->{$group_name}->{roles} } ) ) {
            push @groups_with_selected_role, $group_name;
        }
    }

    for my $group_name (@groups_with_selected_role) {
        $count = $count + scalar @{ $groups->{$group_name}->{users} };
    }

    return $count;
}

=head2 remove_user_from_organization_group

Removes user from organization group

=cut

sub remove_user_from_organization_group {

    my $c        = shift;
    my $group_id = shift;
    my $user_id  = shift;

    my $response;

    my $user_group = $c->model('CoreRealms::OrgaizationUsersGroup')->find(
        {
            group_id => $group_id,
            user_id  => $user_id
        }
    )->delete();

    $response->{status}     = 1;
    $response->{error_code} = 400;
    $response->{message} =
      'Required user has been removed from organization group.';

    return $response;
}

=head2 user_match_role

Check if user has the following roles inside given organization

=cut

sub user_match_role {

    my $c                           = shift;
    my $user_email                  = shift;
    my $organization_id             = shift;
    my $required_organization_roles = shift;

    my $response;
    my $organization_roles;

    $response->{status} = 1;
    $response->{organization_groups} =
      Daedalus::Organizations::Manager::get_organization_groups( $c,
        $organization_id );

    for my $group_name ( keys %{ $response->{organization_groups}->{data} } ) {
        if (
            grep( /^$user_email$/,
                @{
                    $response->{organization_groups}->{data}->{$group_name}
                      ->{users}
                } )
          )
        {
            for my $role_name (
                @{
                    $response->{organization_groups}->{data}->{$group_name}
                      ->{roles}
                }
              )
            {
                $organization_roles->{$role_name} = 1;
            }
        }
    }
    for my $role_name ( @{$required_organization_roles} ) {
        if ( !exists( $organization_roles->{$role_name} ) ) {
            $response->{status} = 0;
        }
    }

    return $response;
}

=head2 remove_organization_group

Removes organization group.

=cut

sub remove_organization_group {
    my $c        = shift;
    my $group_id = shift;

    my $response;

    # Remove group roles

    my $roles_to_remove = $c->model('CoreRealms::OrganizationGroupRole')->find(
        {
            group_id => $group_id,
        }
    );

    $roles_to_remove->delete() if ($roles_to_remove);

    my $users_to_remove = $c->model('CoreRealms::OrgaizationUsersGroup')->find(
        {
            group_id => $group_id,
        }
    );

    $users_to_remove->delete() if ($users_to_remove);

    $c->model('CoreRealms::OrganizationGroup')->find(
        {
            id => $group_id,
        }
    )->delete();

    $response->{error_code} = 400;
    $response->{status}     = 1;
    $response->{message} = 'Selected group has been removed from organization.';

    return $response;
}

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;
1;
