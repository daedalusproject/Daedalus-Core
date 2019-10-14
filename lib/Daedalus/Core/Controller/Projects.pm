package Daedalus::Core::Controller::Projects;

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

use Data::Dumper;

use base qw(Daedalus::Core::Controller::REST);

use Daedalus::Projects::Manager;

__PACKAGE__->config( default => 'application/json' );
__PACKAGE__->config( json_options => { relaxed => 1 } );

BEGIN { extends 'Daedalus::Core::Controller::REST'; return; }

our $VERSION = '0.01';

=head1 NAME

Daedalus::Core::Controller::Projects - Catalyst Controller

=head1 SYNOPSIS

Daedalus::Core Projects Controller.

=head1 DESCRIPTION

Daedalus::Core /project endpoint.

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

=head2 create_project

Create Projects.

Only admin users are allowed to perform this operation.

Required data:   - Organization token
                 - Project name

=cut

sub create_project : Path('/project/create') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 create_project_POST

/project/create is a POST request

=cut

sub create_project_POST {
    my ( $self, $c ) = @_;

    my $response;
    my $organization;
    my $user_data;
    my $project_name;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_master'],
            },
            required_data => {
                'name' => {
                    name                           => "string",
                    required                       => 1,
                    forbid_empty                   => 1,
                    associated_model               => "CoreRealms",
                    associated_model_source        => "Project",
                    associated_model_source_column => "name",
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
        $organization = $authorization_and_validatation->{data}->{organization};
        $user_data    = $authorization_and_validatation->{data}->{user_data};
        $project_name =
          $authorization_and_validatation->{data}->{required_data}->{name};

        $response =
          Daedalus::Projects::Manager::create_project( $c,
            $organization->{_hidden_data}->{organization}->{id},
            $project_name );
        $response->{_hidden_data}->{user} =
          $user_data->{_hidden_data}->{user};
    }
    return $self->return_response( $c, $response );
}

=head2 share_project

Share project between organizations, role level..

Only admin users are allowed to perform this operation.

Required data:   - Organization token
                 - Organization "to share wtih" token
                 - Project token
                 - Role name

Organization tokens can be the same. An organization has to choose if its own groups
have to manage or not its projects.

=cut

sub share_project : Path('/project/share') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 share_project_POST

/project/share is a POST request

=cut

sub share_project_POST {
    my ( $self, $c ) = @_;

    my $response;
    my $organization;
    my $user_data;
    my $project_name;
    my $is_super_admin;

    my $data;
    my $shared_project;
    my $share_project;

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
                organization_to_share_token => {
                    type     => "no_main_organization",
                    required => 1,
                },
                project_token => {
                    type     => "project",
                    required => 1,
                },
                role_name => {
                    type     => "role",
                    required => 1,
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        $response->{message} = "Project shared.";

        $data = $authorization_and_validatation->{data};
        $is_super_admin =
          $data->{user_data}->{_hidden_data}->{user}->{is_super_admin};

        # Check Project organization owner is organization
        if ( $data->{organization}->{_hidden_data}->{organization}->{id} ne
            $data->{project}->{_hidden_data}->{project}->{organization_owner} )
        {
            $response->{status}     = 0;
            $response->{error_code} = $bad_request;
            if ( $is_super_admin == 0 ) {
                $response->{message} = "Invalid project_token.";
            }
            else {
                $response->{message} =
                  'Project does not belong to this organization.';
            }
        }
        else {
# Check if organization_to_share already have this project shared with this role
            $shared_project = Daedalus::Projects::Manager::check_shared_project(
                $c,
                $data->{organization}->{_hidden_data}->{organization}->{id},
                $data->{organization_to_share_token}->{_hidden_data}
                  ->{organization}->{id},
                $data->{project}->{_hidden_data}->{project}->{id},
                $data->{role_name}->{_hidden_data}->{id}
            );
            if ( $shared_project->{status} ) {
                $response               = $shared_project;
                $response->{status}     = 0;
                $response->{error_code} = $bad_request;
            }
            else {
                $share_project = Daedalus::Projects::Manager::share_project(
                    $c,
                    $data->{organization}->{_hidden_data}->{organization}->{id},
                    $data->{organization_to_share_token}->{_hidden_data}
                      ->{organization}->{id},
                    $data->{project}->{_hidden_data}->{project}->{id},
                    $data->{role_name}->{_hidden_data}->{id}
                );
                $response = $share_project;
            }
        }
    }

    return $self->return_response( $c, $response );
}

=head2 add_group_to_share_project

Given a project shared with one organization. This organization is able to add groups with the same role as role level sharing.

Only admin users are allowed to perform this operation.

Required data:   - Organization token
                 - Shared project token
                 - Group token

=cut

sub add_group_to_share_project : Path('/project/share/group') : Args(0) :
  ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 add_group_to_share_project_POST

/project/share/group is a POST request

=cut

sub add_group_to_share_project_POST {
    my ( $self, $c ) = @_;

    my $response;
    my $organization;
    my $user_data;
    my $is_super_admin;

    my $data;
    my $required_data;

    my $shared_project_roles;
    my $match_roles = 0;

    my $group_id;
    my $shared_project_id;

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
                shared_project_token => {
                    type     => "project",
                    required => 1,
                },
                group_token => {
                    type     => "organization_group",
                    required => 1,
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
    else {
        # Check if project is shared
        $data          = $authorization_and_validatation->{data};
        $required_data = $data->{required_data};
        $is_super_admin =
          $data->{user_data}->{_hidden_data}->{user}->{is_super_admin};
        $shared_project_id = $data->{project}->{_hidden_data}->{project}->{id};
        $group_id          = $data->{group_token}->{_hidden_data}
          ->{ $required_data->{group_token} }->{id};

        $shared_project_roles =
          Daedalus::Projects::Manager::check_shared_project_with_organization_roles(
            $c, $data->{organization}->{_hidden_data}->{organization}->{id},
            $shared_project_id );

        if ( $shared_project_roles->{status} == 0 ) {
            $response->{status}  = 0;
            $response->{message} = "Invalid shared_project_token.";
        }
        else {
            my $group_roles = $data->{group_token}->{_hidden_data}
              ->{ $required_data->{group_token} }->{roles};

            for my $group_role ( keys %{$group_roles} ) {
                if (
                    any { /^$group_roles->{$group_role}$/sxm }
                    uniq @{ $shared_project_roles->{shared_project} }

                  )
                {
                    $match_roles = 1;
                }
            }
            if ( $match_roles == 0 ) {
                $response->{status} = 0;
                $response->{message} =
                  "Project not shared with any of the roles of this group.";
            }
            else {
                $response =
                  Daedalus::Projects::Manager::add_group_to_shared_project( $c,
                    $shared_project_id, $group_id );
            }

        }

    }

    return $self->return_response( $c, $response );
}

=head2 project

Get Project Info.

Admin projects also are able to view project

Required data:   - Organization token
                 - Project token

=cut

sub project : Path('/project') : Args(3) : ActionClass('REST') {
    my ( $self, $c ) = @_;
    return;
}

=head2 project_GET

/project is a GET request

=cut

sub project_GET {
    my ( $self, $c ) = @_;

    my $response;
    my $organization;
    my $user_data;
    my $project_name;

    my $authorization_and_validatation = $self->authorize_and_validate(
        $c,
        {
            auth => {
                type               => 'organization',
                organization_roles => ['organization_user'],
            },
            required_data => {
                organization_token => {
                    type         => 'organization',
                    given        => 1,
                    forbid_empty => 1,
                    value        => $c->{request}->{arguments}[0],
                },
                'project_token' => {
                    type         => "project",
                    given        => 1,
                    forbid_empty => 1,
                    value        => $c->{request}->{arguments}[1],
                },
            }
        }
    );

    if ( $authorization_and_validatation->{status} == 0 ) {
        $response = $authorization_and_validatation;
    }
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
