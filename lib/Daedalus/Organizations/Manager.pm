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

    my $c               = shift;
    my $admin_user_data = shift;

    my $response;

    my $organization_data = $c->{request}->{data}->{organization_data};

    my $request_organization_name = "$organization_data->{name}";
    chomp $request_organization_name;

    # Check if user has already created and organization with the same name

    my $user_id;

    if ( exists( $admin_user_data->{_hidden_data} ) ) {
        $user_id = $admin_user_data->{_hidden_data}->{user}->{id};
    }
    else {
        $user_id = Daedalus::Users::Manager::getUserId($c);
    }

    my @user_organizations_rs = $c->model('CoreRealms::UserOrganization')
      ->search( { user_id => $user_id } )->all;

    my @organization_names;

    for my $user_organization (@user_organizations_rs) {
        push @organization_names, $user_organization->organization()->name;
    }

    if ( grep( /^$request_organization_name$/, @organization_names ) ) {
        $response = {
            status  => 0,
            message => 'Duplicated organization name.',
          }

    }
    else {

        # Get organization_master role id

        my $organization_master_role_id = $c->model('CoreRealms::Role')
          ->find( { 'role_name' => 'organization_master' } )->id;

        # Create Organization

        my $organization = $c->model('CoreRealms::Organization')
          ->create( { name => $request_organization_name } );

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
                group_name => "$request_organization_name" . " Administrators",
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
            status       => 1,
            message      => 'Organization created.',
            _hidden_data => {
                organization_id            => $organization->id,
                user_organization_id       => $user_organization->id,
                organization_group_id      => $organization_group->id,
                organization_group_role_id => $organization_group_role->id,
            },
        };

        # Remove _hidden_data if user is not superadmin
        if ( !( Daedalus::Users::Manager::isSuperAdminById( $c, $user_id ) ) ) {
            delete $response->{_hidden_data};
        }
    }
    return $response;
}
__PACKAGE__->meta->make_immutable;
1;
