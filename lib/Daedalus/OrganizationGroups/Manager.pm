package Daedalus::OrganizationGroups::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::OrganizationGroups::Manager

=cut

use strict;
use warnings;
use Moose;

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

Removes user from organization groupd

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

__PACKAGE__->meta->make_immutable;
1;
