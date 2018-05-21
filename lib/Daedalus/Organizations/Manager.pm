package Daedalus::Organizations::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Organizations::Manager

=cut

use strict;
use warnings;
use Moose;

use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::Organizations::Manager

=cut

=head1 DESCRIPTION

Daedalus Organizations Manager

=head1 METHODS

=cut

=head2 createOrganization

Creates a new Organization

=cut

sub createOrganization {

    my $request         = shift;
    my $admin_user_data = shift;

    my $response;

    my $organization_data = $request->{request}->{data}->{organization_data};

    # Get organization_master role id

    my $organization_master_role_id = $request->model('CoreRealms::Role')
      ->find( { 'role_name' => 'organization_master' } )->id;

    # Create Organization

    my $organization = $request->model('CoreRealms::Organization')
      ->create( { name => $organization_data->{name} } );

    # Add user to Organization
    my $user_organization =
      $request->model('CoreRealms::UserOrganization')->create(
        {
            organization_id => $organization->id,
            user_id         => $admin_user_data->{id}
        }
      );

    # Create an organization admin group
    my $organization_group =
      $request->model('CoreRealms::OrganizationGroup')->create(
        {
            organization_id => $organization->id,
            group_name      => "$organization_data->{name}" . "_administrators",
        }
      );

    # This group has orgaization_master role
    my $organization_group_role =
      $request->model('CoreRealms::OrganizationGroupRole')->create(
        {
            group_id => $organization_group->id,
            role_id  => $organization_master_role_id,
        }
      );

    $response = {
        status       => 'Success',
        message      => 'Organization created.',
        _hidden_data => {
            organization_id            => $organization->id,
            user_organization_id       => $user_organization->id,
            organization_group_id      => $organization_group->id,
            organization_group_role_id => $organization_group_role->id,
        },
    };

    return $response;
}
__PACKAGE__->meta->make_immutable;
1;
