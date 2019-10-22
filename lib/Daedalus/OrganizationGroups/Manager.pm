package Daedalus::OrganizationGroups::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::OrganizationGroups::Manager

=cut

use 5.026_001;
use strict;
use warnings;
use Moose;
use List::MoreUtils qw(any uniq);

use Daedalus::Organizations::Manager;
use Daedalus::Utils::Constants qw(
  $bad_request
);

use namespace::clean -except => 'meta';

our $VERSION = '0.01';

=head1 SYNOPSIS

Daedalus Organization Groups Manager


=head1 DESCRIPTION

Daedalus Organization Groups Manager

=head1 SUBROUTINES/METHODS

=cut

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
        if (
            any { /^$role_name$/sxm }
            uniq @{ $groups->{$group_name}->{roles} }
          )
        {
            push @groups_with_selected_role, $group_name;
        }
    }

    for my $group_name (@groups_with_selected_role) {
        $count = $count + keys %{ $groups->{$group_name}->{users} };
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

    my $user_group = $c->model('CoreRealms::OrganizationUsersGroup')->find(
        {
            group_id => $group_id,
            user_id  => $user_id
        }
    )->delete();

    $response->{status}     = 1;
    $response->{error_code} = $bad_request;
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
            exists(
                $response->{organization_groups}->{data}->{$group_name}
                  ->{users}->{$user_email}
            )
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

    if ($roles_to_remove) {
        $roles_to_remove->delete();
    }

    my $users_to_remove =
      $c->model('CoreRealms::OrganizationUsersGroup')->find(
        {
            group_id => $group_id,
        }
      );

    if ($users_to_remove) {
        $users_to_remove->delete();
    }

    $c->model('CoreRealms::OrganizationGroup')->find(
        {
            id => $group_id,
        }
    )->delete();

    $response->{error_code} = $bad_request;
    $response->{status}     = 1;
    $response->{message} = 'Selected group has been removed from organization.';

    return $response;
}

=head2 get_organization_group_from_token

For a given organization group token, return organization group data

=cut

sub get_organization_group_from_token {

    my $c                        = shift;
    my $organization_group_token = shift;

    my $response;
    $response->{status}     = 0;
    $response->{error_code} = $bad_request;
    $response->{message}    = 'Invalid organization group token.';

    my $organization_group = $c->model('CoreRealms::OrganizationGroup')
      ->find( { token => $organization_group_token } );

    if ($organization_group) {
        my $organization_group_data =
          render_organization_group_data( $c, $organization_group );
        $response->{data}         = $organization_group_data->{data};
        $response->{_hidden_data} = $organization_group_data->{_hidden_data};
    }

    return $response;
}

=head2 get_organization_group_from_id

For a given organization group id, return organization group data

=cut

sub get_organization_group_from_id {

    my $c                     = shift;
    my $organization_group_id = shift;

    my $response;
    $response->{status}     = 1;
    $response->{error_code} = $bad_request;
    $response->{message}    = 'Invalid organization group id.';

    my $organization_group = $c->model('CoreRealms::OrganizationGroup')
      ->find( { id => $organization_group_id } );

    if ($organization_group) {
        my $organization_group_data =
          render_organization_group_data( $c, $organization_group );
        $response->{data}         = $organization_group_data->{data};
        $response->{_hidden_data} = $organization_group_data->{_hidden_data};
    }

    return $response;
}

=head2 render_organization_group_data

For a given organization, render its data

=cut

sub render_organization_group_data {

    my $c                  = shift;
    my $organization_group = shift;

    my $response;
    my $roles =
      Daedalus::Organizations::Manager::get_organization_group_roles( $c,
        $organization_group->id );
    my $users =
      Daedalus::Organizations::Manager::get_organization_group_users( $c,
        $organization_group->id );
    $response->{status}  = 1;
    $response->{message} = 'Organization group token is valid.';
    $response->{data}    = {
        $organization_group->token => {
            token      => $organization_group->token,
            group_name => $organization_group->group_name,
        },
    };
    $response->{_hidden_data} = {
        $organization_group->token => {
            id              => $organization_group->id,
            organization_id => $organization_group->organization_id
        }
    };
    $response->{data}->{ $organization_group->token }->{roles} =
      $roles->{data};
    $response->{_hidden_data}->{ $organization_group->token }->{roles} =
      $roles->{_hidden_data};
    $response->{data}->{ $organization_group->token }->{users} =
      $users->{data};
    $response->{_hidden_data}->{ $organization_group->token }->{users} =
      $users->{_hidden_data};

    return $response;
}

=encoding utf8

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS
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
