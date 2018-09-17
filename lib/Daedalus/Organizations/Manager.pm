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

        $user_id = $user_data->{data}->{_hidden_data}->{id};

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

=head2 getUserOrganizations

For a given user, show its organizations

=cut

sub getUserOrganizations {

    my $c         = shift;
    my $user_data = shift;

    my $response = {
        status => 1,
        data   => {
            organizations => [],
        },
        _hidden_data => {
            organizations => {}
        },
    };

    my $user_id;

    if ( exists( $user_data->{_hidden_data} ) ) {
        $user_id = $user_data->{_hidden_data}->{user}->{id};
    }
    else {
        $user_id = Daedalus::Users::Manager::getUserId($c);
    }

    my @user_organizations = $c->model('CoreRealms::UserOrganization')
      ->search( { user_id => $user_id } )->all();

    my @organizations_names;
    my %organizations;

    for my $user_organization (@user_organizations) {
        my $organization = $c->model('CoreRealms::Organization')
          ->find( { id => $user_organization->organization_id } );
        push @organizations_names, $organization->name;
        $organizations{ $organization->name } =
          { id => $organization->id, token => $organization->token };
    }

    $response->{data}->{organizations}         = \@organizations_names;
    $response->{_hidden_data}->{organizations} = \%organizations;

    if ( !( Daedalus::Users::Manager::isSuperAdminById( $c, $user_id ) ) ) {
        delete $response->{_hidden_data};
    }

    return $response;
}

=head2 showOrganizationUsers

For a given organization token, show its users

=cut

=head2 _getOrganizationFromToken

For a given organization token, return organization data

Private method

=cut

sub _getOrganizationFromToken {

    my $c = shift;

    my $response;
    $response->{status}  = 0;
    $response->{message} = 'Invalid Organization token.';

    my $organization_request_data = $c->{request}->{data}->{organization};
    if ($organization_request_data) {
        if ( $organization_request_data->{token} ) {

            my $organization = $c->model('CoreRealms::Organization')
              ->find( { token => $organization_request_data->{token} } );

            if ($organization) {
                $response->{status}       = 1;
                $response->{organization} = $organization;
            }

        }
    }

    return $response;
}

__PACKAGE__->meta->make_immutable;
1;
