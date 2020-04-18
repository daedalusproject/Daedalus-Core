package Daedalus::Projects::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Projects::Manager

=cut

use 5.026_001;
use strict;
use warnings;
use Moose;

use Daedalus::Utils::Crypt;
use List::MoreUtils qw(any uniq);
use Daedalus::Roles::Manager;
use Daedalus::Utils::Constants qw(
  $bad_request
  $project_token_length
);

use Data::Dumper;

use namespace::clean -except => 'meta';

our $VERSION = '0.01';

=head1 SYNOPSIS

Daedalus Projects Manager


=head1 DESCRIPTION

Daedalus Projects Manager

=head1 METHODS

=cut

=head2 create_project

Creates a new Project

=cut

sub create_project {

    my $c               = shift;
    my $organization_id = shift;
    my $project_name    = shift;

    my $response = {
        status  => 0,
        message => q{},
    };

    my $project_token;

    my $pojects_rs =
      $c->model('CoreRealms::Project')
      ->find(
        { organization_owner => $organization_id, name => $project_name } );
    if ($pojects_rs) {
        $response->{error_code} = $bad_request;
        $response->{message} =
          "Required project name already exists inside this organization.";
    }
    else {
        $project_token =
          Daedalus::Utils::Crypt::generate_random_string($project_token_length);

        my $project = $c->model('CoreRealms::Project')->create(
            {
                name               => $project_name,
                organization_owner => $organization_id,
                token              => $project_token
            }
        );
        $response->{status}  = 1;
        $response->{message} = "Project Created.";
        $response->{data} =
          { project => { name => $project_name, token => $project_token } };
        $response->{_hidden_data} = {
            project => {
                id                 => $project->id,
                organization_owner => $organization_id
            }
        };
    }

    return $response;
}

=head2 get_project_from_token

For a given project token, return project data

=cut

sub get_project_from_token {

    my $c             = shift;
    my $project_token = shift;

    my $response;
    $response->{status}     = 0;
    $response->{error_code} = $bad_request;
    $response->{message}    = 'Invalid project token.';

    my $project =
      $c->model('CoreRealms::Project')->find( { token => $project_token } );

    if ($project) {
        $response->{status}  = 1;
        $response->{message} = 'Project token is valid.';
        $response->{project} = {
            data => {
                project => {
                    name  => $project->name,
                    token => $project->token,
                },
            },
            _hidden_data => {
                project => {
                    id                 => $project->id,
                    organization_owner => $project->organization_owner->id,
                }
            }
        };
    }

    return $response;
}

=head2 get_project_from_id

For a given project id, return project data
We assume project id always exists.
=cut

sub get_project_from_id {

    my $c          = shift;
    my $project_id = shift;

    my $response;
    $response->{status} = 1;

    my $project =
      $c->model('CoreRealms::Project')->find( { id => $project_id } );

    $response->{project} = {
        data => {
            project => {
                name  => $project->name,
                token => $project->token,
            },
        },
        _hidden_data => {
            project => {
                id                 => $project->id,
                organization_owner => $project->organization_owner->id,
            }
        }
    };

    return $response;
}

=head2 check_shared_project_with_organization_roles

Check if project is already shared with organization

=cut

sub check_shared_project_with_organization_roles {

    my $c                        = shift;
    my $organization_to_share_id = shift;
    my $project_id               = shift;

    my $response;
    $response->{status}             = 0;
    $response->{shared_project}     = [];
    $response->{shared_project_ids} = [];

    my @shared_project = $c->model('CoreRealms::SharedProject')->search(
        {
            organization_to_manage_id => $organization_to_share_id,
            project_id                => $project_id,
        }
    )->all();

    if ( scalar @shared_project > 0 ) {
        $response->{status} = 1;
        for my $sharing (@shared_project) {
            push @{ $response->{shared_project} },
              $sharing->organization_to_manage_role_id;
            push @{ $response->{shared_project_ids} }, $sharing->id;
        }
    }

    return $response;
}

=head2 check_shared_project

Check if project is already shared

=cut

sub check_shared_project {

    my $c                        = shift;
    my $organization_owner_id    = shift;
    my $organization_to_share_id = shift;
    my $project_id               = shift;
    my $role_id                  = shift;

    my $response;
    $response->{status} = 0;

    my $shared_project = $c->model('CoreRealms::SharedProject')->find(
        {
            organization_manager_id        => $organization_owner_id,
            organization_to_manage_id      => $organization_to_share_id,
            project_id                     => $project_id,
            organization_to_manage_role_id => $role_id
        }
    );

    if ($shared_project) {
        $response->{status} = 1;
        $response->{message} =
'This project has been already shared with this organization and this role.';
    }

    return $response;
}

=head2 share_project

Share a project between two organizations

=cut

sub share_project {

    my $c                        = shift;
    my $organization_owner_id    = shift;
    my $organization_to_share_id = shift;
    my $project_id               = shift;
    my $role_id                  = shift;

    my $response;

    my $share_project = $c->model('CoreRealms::SharedProject')->create(
        {
            organization_manager_id        => $organization_owner_id,
            organization_to_manage_id      => $organization_to_share_id,
            project_id                     => $project_id,
            organization_to_manage_role_id => $role_id
        }
    );

# There is no check for duplicated shares, if this relation is duplicated it is has been checked before.

    $response->{status}  = 1;
    $response->{message} = 'Project shared.';

    return $response;
}

=head2 add_group_to_shared_project

Add group to a shared project

=cut

sub add_group_to_shared_project {

    my $c                 = shift;
    my $shared_project_id = shift;
    my $group_id          = shift;

    my $response;

    # Check if already exists
    my $check_share_project =
      $c->model('CoreRealms::SharedProjectGroupAssignment')->find(
        {
            shared_project_id => $shared_project_id,
            group_id          => $group_id
        }
      );

    if ($check_share_project) {
        $response->{status} = 0;
        $response->{message} =
          'This group has already been added to this shared project.';
    }
    else {
        # Add group
        $check_share_project =
          $c->model('CoreRealms::SharedProjectGroupAssignment')->create(
            {
                shared_project_id => $shared_project_id,
                group_id          => $group_id
            }
          );
        $response->{status}  = 1;
        $response->{message} = 'Group added to shared project.';
    }

    return $response;
}

=head2 get_shared_project_info

Get all sharing relations of given project

=cut

sub get_shared_project_info {

    my $c          = shift;
    my $project_id = shift;

    my $response;
    $response->{status}     = 1;
    $response->{share_info} = {};

    my @shared_project = $c->model('CoreRealms::SharedProject')->search(
        {
            project_id => $project_id,
        }
    )->all();

    if ( scalar @shared_project > 0 ) {
        for my $sharing (@shared_project) {
            if ( !exists $response->{share_info}
                ->{ $sharing->organization_to_manage_id } )
            {
                $response->{share_info}->{ $sharing->organization_to_manage_id }
                  = [];
            }
            push @{ $response->{share_info}
                  ->{ $sharing->organization_to_manage_id } },
              $sharing->organization_to_manage_role_id;
        }
    }

    return $response;
}

=head2 get_organization_projects

Returns a list of Project ID's owned by organization

=cut

sub get_organization_projects {

    my $c               = shift;
    my $organization_id = shift;

    my $projects;
    my $knowed_organizations;
    my $available_roles;

    my $response = {
        data         => { projects => {} },
        _hidden_data => { projects => {} },
        status       => 1
    };

    # Check if already exists
    my @organization_projects = $c->model('CoreRealms::Project')->search(
        {
            organization_owner => $organization_id,
        }
    )->all;

    if ( scalar @organization_projects > 0 ) {

        $available_roles = Daedalus::Roles::Manager::list_roles_by_id($c);

        for my $organization_project (@organization_projects) {
            $projects->{data}->{ $organization_project->token } = {
                name  => $organization_project->name,
                token => $organization_project->token
            };
            $projects->{_hidden_data}->{ $organization_project->token } =
              { id => $organization_project->id, };
            $projects->{data}->{ $organization_project->token }->{shared_with}
              = {};
            $projects->{_hidden_data}->{ $organization_project->token }
              ->{shared_with} = {};
            my $sharing_info =
              get_shared_project_info( $c, $organization_project->id )
              ->{share_info};
            for my $organization_id ( keys %{$sharing_info} ) {
                if ( !exists $knowed_organizations->{$organization_id} ) {
                    $knowed_organizations->{$organization_id} =
                      Daedalus::Organizations::Manager::get_organization_from_id(
                        $c, $organization_id )->{organization};
                }
                $projects->{data}->{ $organization_project->token }
                  ->{shared_with}
                  ->{ $knowed_organizations->{$organization_id}->{data}
                      ->{organization}->{token} } = {
                    organization_name =>
                      $knowed_organizations->{$organization_id}->{data}
                      ->{organization}->{name},
                    token =>
                      $knowed_organizations->{$organization_id}->{data}
                      ->{organization}->{token},
                    shared_roles => [],
                      };
                $projects->{_hidden_data}->{ $organization_project->token }
                  ->{shared_with}
                  ->{ $knowed_organizations->{$organization_id}->{data}
                      ->{organization}->{token} } = {
                    id =>
                      $knowed_organizations->{$organization_id}->{_hidden_data}
                      ->{organization}->{id},
                    shared_roles => {},
                      };

                for
                  my $shared_role_id ( @{ $sharing_info->{$organization_id} } )
                {
                    push @{
                        $projects->{data}->{ $organization_project->token }
                          ->{shared_with}->{
                            $knowed_organizations->{$organization_id}->{data}
                              ->{organization}->{token}
                          }->{shared_roles}
                      },
                      $available_roles->{$shared_role_id};
                    $projects->{_hidden_data}->{ $organization_project->token }
                      ->{shared_with}
                      ->{ $knowed_organizations->{$organization_id}->{data}
                          ->{organization}->{token} }->{shared_roles}
                      ->{$shared_role_id} = $available_roles->{$shared_role_id};
                }
            }
        }
        $response->{data}->{projects}         = $projects->{data};
        $response->{_hidden_data}->{projects} = $projects->{_hidden_data};
    }
    return $response;
}

=head2 get_shared_projects_with_organization

Returns a list of Projects shared with given organization

=cut

sub get_shared_projects_with_organization {

    my $c               = shift;
    my $organization_id = shift;

    my $projects;
    my $knowed_organizations;
    my $knowed_projects;
    my $available_roles;
    my $response = {
        data         => { projects => {} },
        _hidden_data => { projects => {} },
        status       => 1
    };

    # Check if already exists
    my @projects_shared = $c->model('CoreRealms::SharedProject')->search(
        {
            organization_to_manage_id => $organization_id,
        }
    )->all;

    if ( scalar @projects_shared > 0 ) {
        $available_roles = Daedalus::Roles::Manager::list_roles_by_id($c);

        for my $shared_project (@projects_shared) {
            if ( !exists $knowed_organizations
                ->{ $shared_project->organization_manager_id } )
            {
                $knowed_organizations
                  ->{ $shared_project->organization_manager_id } =
                  Daedalus::Organizations::Manager::get_organization_from_id(
                    $c, $shared_project->organization_manager_id )
                  ->{organization};
            }
            if ( !exists $knowed_projects->{ $shared_project->project_id } ) {
                $knowed_projects->{ $shared_project->project_id } =
                  get_project_from_id( $c, $shared_project->project_id )
                  ->{project};
                $knowed_projects->{ $shared_project->project_id }
                  ->{_hidden_data}->{project}->{shared_groups} = [];
                $knowed_projects->{ $shared_project->project_id }
                  ->{_hidden_data}->{project}->{shared_groups_info} = {};

                $knowed_projects->{ $shared_project->project_id }->{data}
                  ->{project}->{organization_owner} =
                  $knowed_organizations
                  ->{ $shared_project->organization_manager_id }->{data}
                  ->{organization};
                $knowed_projects->{ $shared_project->project_id }
                  ->{_hidden_data}->{project}->{organization_owner} =
                  $knowed_organizations
                  ->{ $shared_project->organization_manager_id }
                  ->{_hidden_data}->{organization};

                $knowed_projects->{ $shared_project->project_id }
                  ->{_hidden_data}->{project}->{shared_roles} = {};
                $knowed_projects->{ $shared_project->project_id }->{data}
                  ->{project}->{shared_roles} = [];
            }

            # Add shared roles
            $knowed_projects->{ $shared_project->project_id }->{_hidden_data}
              ->{project}->{shared_roles}
              ->{ $shared_project->organization_to_manage_role_id } =
              $available_roles
              ->{ $shared_project->organization_to_manage_role_id };
            push @{ $knowed_projects->{ $shared_project->project_id }->{data}
                  ->{project}->{shared_roles} },
              $available_roles
              ->{ $shared_project->organization_to_manage_role_id };

            # get shared project's groups with

            my @shared_groups =
              $c->model('CoreRealms::SharedProjectGroupAssignment')
              ->search( { shared_project_id => $shared_project->project_id } )
              ->all;
            for my $group (@shared_groups) {
                my $group_id              = $group->group_id;
                my $group_organization_id = $group->group->organization_id;
                if (
                    !(
                        any { /^$group_id$/sxm }
                        uniq @{
                            $knowed_projects->{ $shared_project->project_id }
                              ->{_hidden_data}->{project}->{shared_groups}
                        }
                    )

                  )
                {
                    push @{ $knowed_projects->{ $shared_project->project_id }
                          ->{_hidden_data}->{project}->{shared_groups} },
                      $group->group_id;
                    my $group_data =
                      Daedalus::OrganizationGroups::Manager::get_organization_group_from_id(
                        $c, $group->group_id );
                    my $group_token =
                      ( keys %{ $group_data->{data} } )[0];

                    #my $group_users =
                    #$group_data->{data}->{$group_token}->{users};
                    #$group_data->{data}->{$group_token}->{users} =
                    #\@group_users;
                    $knowed_projects->{ $shared_project->project_id }
                      ->{_hidden_data}->{project}->{shared_groups_info}
                      ->{ $group->group_id } =
                      $group_data->{_hidden_data}->{$group_token};
                    $knowed_projects->{ $shared_project->project_id }->{data}
                      ->{project}->{shared_groups_info}->{$group_token} =
                      $group_data->{data}->{$group_token};
                }

            }

        }
        for my $knowed_project ( keys %{$knowed_projects} ) {
            $response->{data}->{projects}
              ->{ $knowed_projects->{$knowed_project}->{data}->{project}
                  ->{token} } =
              $knowed_projects->{$knowed_project}->{data}->{project};
            $response->{_hidden_data}->{projects}
              ->{ $knowed_projects->{$knowed_project}->{data}->{project}
                  ->{token} } =
              $knowed_projects->{$knowed_project}->{_hidden_data}->{project};

        }
    }
    return $response;
}

=head2 get_shared_projects_with_organization_filtered_by_user

Returns a list of Projects shared with given organization

=cut

sub get_shared_projects_with_organization_filtered_by_user {

    my $c                      = shift;
    my $organization_id        = shift;
    my $user_organizations_ids = shift;

    my $projects;
    my $knowed_organizations;
    my $knowed_projects;
    my $available_roles;

    my $response = {
        data         => { projects => {} },
        _hidden_data => { projects => {} },
        status       => 1
    };

    # Check if already exists
    my @projects_shared = $c->model('CoreRealms::SharedProject')->search(
        {
            organization_to_manage_id => $organization_id,
        }
    )->all;

    if ( scalar @projects_shared > 0 ) {
        $available_roles = Daedalus::Roles::Manager::list_roles_by_id($c);

        for my $shared_project (@projects_shared) {
            if ( !exists $knowed_organizations
                ->{ $shared_project->organization_manager_id } )
            {
                $knowed_organizations
                  ->{ $shared_project->organization_manager_id } =
                  Daedalus::Organizations::Manager::get_organization_from_id(
                    $c, $shared_project->organization_manager_id )
                  ->{organization};
            }
            if ( !exists $knowed_projects->{ $shared_project->project_id } ) {
                $knowed_projects->{ $shared_project->project_id } =
                  get_project_from_id( $c, $shared_project->project_id )
                  ->{project};
                $knowed_projects->{ $shared_project->project_id }
                  ->{_hidden_data}->{project}->{shared_groups} = [];
                $knowed_projects->{ $shared_project->project_id }
                  ->{_hidden_data}->{project}->{shared_groups_info} = {};

                $knowed_projects->{ $shared_project->project_id }->{data}
                  ->{project}->{organization_owner} =
                  $knowed_organizations
                  ->{ $shared_project->organization_manager_id }->{data}
                  ->{organization};
                $knowed_projects->{ $shared_project->project_id }
                  ->{_hidden_data}->{project}->{organization_owner} =
                  $knowed_organizations
                  ->{ $shared_project->organization_manager_id }
                  ->{_hidden_data}->{organization};
            }

            # get shared project's groups with

            my @shared_groups =
              $c->model('CoreRealms::SharedProjectGroupAssignment')
              ->search( { shared_project_id => $shared_project->project_id } )
              ->all;
            for my $group (@shared_groups) {
                my $group_id              = $group->group_id;
                my $group_organization_id = $group->group->organization_id;
                if (
                    !(
                        any { /^$group_id$/sxm }
                        uniq @{
                            $knowed_projects->{ $shared_project->project_id }
                              ->{_hidden_data}->{project}->{shared_groups}
                        }
                    )
                    &&

                    (
                        any { /^$group_organization_id$/sxm }
                        uniq @{$user_organizations_ids}
                    )

                  )
                {
                    push @{ $knowed_projects->{ $shared_project->project_id }
                          ->{_hidden_data}->{project}->{shared_groups} },
                      $group->group_id;
                    my $group_data =
                      Daedalus::OrganizationGroups::Manager::get_organization_group_from_id(
                        $c, $group->group_id );
                    my $group_token = ( keys %{ $group_data->{data} } )[0];
                    my @group_users =
                      keys %{ $group_data->{data}->{$group_token}->{users} };
                    $group_data->{data}->{$group_token}->{users} =
                      \@group_users;
                    $knowed_projects->{ $shared_project->project_id }
                      ->{_hidden_data}->{project}->{shared_groups_info}
                      ->{ $group->group_id } =
                      $group_data->{_hidden_data}->{$group_token};
                    $knowed_projects->{ $shared_project->project_id }->{data}
                      ->{project}->{shared_groups_info}->{$group_token} =
                      $group_data->{data}->{$group_token};
                }

            }

        }
        for my $knowed_project ( keys %{$knowed_projects} ) {
            $response->{data}->{projects}
              ->{ $knowed_projects->{$knowed_project}->{data}->{project}
                  ->{token} } =
              $knowed_projects->{$knowed_project}->{data}->{project};
            $response->{_hidden_data}->{projects}
              ->{ $knowed_projects->{$knowed_project}->{data}->{project}
                  ->{token} } =
              $knowed_projects->{$knowed_project}->{_hidden_data}->{project};

        }
    }
    return $response;
}

=head2 get_users_allowed_to_manage_project

Returns users allowed to manage project

=cut

sub get_users_allowed_to_manage_project {

    my $c                     = shift;
    my $organization_owner_id = shift;
    my $project_id            = shift;

    my $response;
    my $response = {
        data         => { users => {} },
        _hidden_data => { users => {} },
        status       => 1
    };

    my @shared_project_info = $c->model('CoreRealms::SharedProject')->search(
        {
            organization_manager_id => $organization_owner_id,
            project_id              => $project_id,
        }
    )->all();

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

If APP_TEST env is enabled, Core reads its configuration from t/ folder, by default config files we be read rom /etc/daedalus-core folder.

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
