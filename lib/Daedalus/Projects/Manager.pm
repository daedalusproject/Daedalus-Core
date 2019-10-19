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

=head2 check_shared_project_with_organization

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
          'This group has already been aded to this shared project.';
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
