use v5.26;
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

my $endpoint = '/organization/projects';

my $non_admin_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'noadmin@megashops.com',
            password => '__;;_12__Password_34',
        }
    )
);

is( $non_admin_login_success->code(), 200, );

my $non_admin_login_success_json =
  decode_json( $non_admin_login_success->content );

is( $non_admin_login_success_json->{status}, 1, );

my $non_admin_login_success_token =
  $non_admin_login_success_json->{data}->{session_token};

my $non_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$non_admin_login_success_token", '' );

my $hank_scorpio_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'hscorpio@globex.com',
            password => '::::Sc0rP10___:::;;;;;',
        }
    )
);

is( $hank_scorpio_login_success->code(), 200, );

my $hank_scorpio_login_success_json =
  decode_json( $hank_scorpio_login_success->content );

is( $hank_scorpio_login_success_json->{status}, 1, );

my $hank_scorpio_login_success_token =
  $hank_scorpio_login_success_json->{data}->{session_token};

my $hank_scorpio_authorization_basic =
  MIME::Base64::encode( "session_token:$hank_scorpio_login_success_token", '' );

my $admin_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $admin_login_success->code(), 200, );

my $admin_login_success_json = decode_json( $admin_login_success->content );

is( $admin_login_success_json->{status}, 1, );

my $admin_login_success_token =
  $admin_login_success_json->{data}->{session_token};

my $admin_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_login_success_token", '' );

my $superadmin_login = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'admin@daedalus-project.io',
            password => 'this_is_a_Test_1234',
        }
    )
);

is( $superadmin_login->code(), 200, );

my $superadmin_login_json = decode_json( $superadmin_login->content );

is( $superadmin_login_json->{status}, 1, );

my $superadmin_session_token = $superadmin_login_json->{data}->{session_token};

my $superadmin_authorization_basic =
  MIME::Base64::encode( "session_token:$superadmin_session_token", '' );

my $failed_no_organization_token = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_no_organization_token->code(), 404, );

my $failed_admin_no_organization_token = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_admin_no_organization_token->code(), 404, );

my $failed_invalid_organization_token = request(
    GET "$endpoint/someorganizationtoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_invalid_organization_token->code(), 400, );

my $failed_invalid_organization_token_json =
  decode_json( $failed_invalid_organization_token->content );

is( $failed_invalid_organization_token_json->{status}, 0, );
is(
    $failed_invalid_organization_token_json->{message},
    'Invalid organization token.',
);

my $failed_admin_invalid_organization_token = request(
    GET "$endpoint/someorganizationtoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_admin_invalid_organization_token->code(), 400, );

my $failed_admin_invalid_organization_token_json =
  decode_json( $failed_admin_invalid_organization_token->content );

is( $failed_admin_invalid_organization_token_json->{status}, 0, );
is(
    $failed_admin_invalid_organization_token_json->{message},
    'Invalid organization token.',
);

my $failed_not_your_organization = request(
    GET "$endpoint/cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW",    # Bugs Techs
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_not_your_organization->code(), 400, );

my $failed_not_your_organization_json =
  decode_json( $failed_not_your_organization->content );

is( $failed_not_your_organization_json->{status}, 0, );
is(
    $failed_not_your_organization_json->{message},
    'Invalid organization token.',
);

my $failed_admin_not_your_organization = request(
    GET "$endpoint/cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW",    # Bugs Techs
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_admin_not_your_organization->code(), 400, );

my $failed_admin_not_your_organization_json =
  decode_json( $failed_admin_not_your_organization->content );

is( $failed_admin_not_your_organization_json->{status}, 0, );
is(
    $failed_admin_not_your_organization_json->{message},
    'Invalid organization token.',
);

my $failed_not_organization_admin = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega shops
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_not_organization_admin->code(), 403, );

my $failed_not_organization_admin_json =
  decode_json( $failed_not_organization_admin->content );

is( $failed_not_organization_admin_json->{status}, 0, );
is(
    $failed_not_organization_admin_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

is( $failed_not_organization_admin_json->{_hidden_data}, undef, );

my $success_admin_with_no_projects = request(
    GET "$endpoint/AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3",    # Globex
    Content_Type  => 'application/json',
    Authorization => "Basic $hank_scorpio_authorization_basic",
);

is( $success_admin_with_no_projects->code(), 200, );

my $success_admin_with_no_projects_json =
  decode_json( $success_admin_with_no_projects->content );

is( $success_admin_with_no_projects_json->{status}, 1, );

is( $success_admin_with_no_projects_json->{_hidden_data}, undef, );

isnt( $success_admin_with_no_projects_json->{data},             undef, );
isnt( $success_admin_with_no_projects_json->{data}->{projects}, undef, );

is( keys %{ $success_admin_with_no_projects_json->{data}->{projects} },
    0, 'For the time being this organization has no projects.' );

my $success_admin = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega shops
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $success_admin->code(), 200, );

my $success_admin_json = decode_json( $success_admin->content );

is( $success_admin_json->{status}, 1, );

is( $success_admin_json->{_hidden_data}, undef, );

isnt( $success_admin_json->{data},             undef, );
isnt( $success_admin_json->{data}->{projects}, undef, );

is( keys %{ $success_admin_json->{data}->{projects} },
    1, 'For the time being this organization has only one project.' );

is(
    $success_admin_json->{data}->{projects}->{oqu2eeCee2Amae6Aijo7tei5woh4jiet}
      ->{name},
    "Mega Shops e-commerce",
);

isnt(
    $success_admin_json->{data}->{projects}->{oqu2eeCee2Amae6Aijo7tei5woh4jiet}
      ->{shared_with},
    undef,
);

my $success_admin_share_with_other_organization = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' =>
              'cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW',    # Bugs Tech
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'expenses_watcher',
        }
    )
);

is( $success_admin_share_with_other_organization->code(), 200, );

my $success_admin_share_with_other_organization_json =
  decode_json( $success_admin_share_with_other_organization->content );

is( $success_admin_share_with_other_organization_json->{status}, 1, );
is(
    $success_admin_share_with_other_organization_json->{message},
    'Project shared.',
);

$success_admin_share_with_other_organization = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' =>
              'cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW',    # Bugs Tech
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'fireman',
        }
    )
);

is( $success_admin_share_with_other_organization->code(), 200, );

$success_admin_share_with_other_organization_json =
  decode_json( $success_admin_share_with_other_organization->content );

is( $success_admin_share_with_other_organization_json->{status}, 1, );
is(
    $success_admin_share_with_other_organization_json->{message},
    'Project shared.',
);

$success_admin_share_with_other_organization = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' =>
              'AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3',    # Globex
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'fireman',
        }
    )
);

is( $success_admin_share_with_other_organization->code(), 200, );

$success_admin_share_with_other_organization_json =
  decode_json( $success_admin_share_with_other_organization->content );

is( $success_admin_share_with_other_organization_json->{status}, 1, );
is(
    $success_admin_share_with_other_organization_json->{message},
    'Project shared.',
);

my $success_admin_more_projects_shared = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega shops
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

my $success_admin_more_projects_shared_json =
  decode_json( $success_admin_more_projects_shared->content );

is( $success_admin_more_projects_shared_json->{status}, 1, );

is( $success_admin_more_projects_shared_json->{_hidden_data}, undef, );

isnt( $success_admin_more_projects_shared_json->{data},             undef, );
isnt( $success_admin_more_projects_shared_json->{data}->{projects}, undef, );

is( keys %{ $success_admin_more_projects_shared_json->{data}->{projects} },
    1, 'For the time being this organization has only one project.' );

is(
    $success_admin_more_projects_shared_json->{data}->{projects}
      ->{oqu2eeCee2Amae6Aijo7tei5woh4jiet}->{name},
    "Mega Shops e-commerce",
);

isnt(
    $success_admin_more_projects_shared_json->{data}->{projects}
      ->{oqu2eeCee2Amae6Aijo7tei5woh4jiet}->{shared_with},
    undef,
);

isnt(
    $success_admin_more_projects_shared_json->{data}->{projects}
      ->{oqu2eeCee2Amae6Aijo7tei5woh4jiet}->{shared_with}
      ->{cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW},
    undef,
);

is(
    $success_admin_more_projects_shared_json->{data}->{projects}
      ->{oqu2eeCee2Amae6Aijo7tei5woh4jiet}->{shared_with}
      ->{cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW}->{organization_name},
    'Bugs Tech',
);

is(
    scalar @{
        $success_admin_more_projects_shared_json->{data}->{projects}
          ->{oqu2eeCee2Amae6Aijo7tei5woh4jiet}->{shared_with}
          ->{cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW}->{shared_roles}
    },
    2,
    "expenses_watcher and fireman"
);

my $create_project_success = request(
    POST "project/create",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'name'               => 'Mega Shops blog',
        }
    )
);

is( $create_project_success->code(), 200, );

my $create_project_success_json =
  decode_json( $create_project_success->content );

is( $create_project_success_json->{status}, 1, );
is( $create_project_success_json->{message}, 'Project Created.', "Success" );

my $new_project_token =
  $create_project_success_json->{data}->{project}->{token};

my $success_admin_new_project_not_shared_yet = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega shops
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

my $success_admin_new_project_not_shared_yet_json =
  decode_json( $success_admin_new_project_not_shared_yet->content );

is( $success_admin_new_project_not_shared_yet_json->{status}, 1, );

is( $success_admin_new_project_not_shared_yet_json->{_hidden_data}, undef, );

isnt( $success_admin_new_project_not_shared_yet_json->{data}, undef, );
isnt( $success_admin_new_project_not_shared_yet_json->{data}->{projects},
    undef, );

is(
    keys %{ $success_admin_new_project_not_shared_yet_json->{data}->{projects}
    },
    2,
    'There are two projects now.'
);

is(
    $success_admin_new_project_not_shared_yet_json->{data}->{projects}
      ->{$new_project_token}->{name},
    "Mega Shops blog",

);

is(
    $success_admin_more_projects_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with},
    undef, "Not shared yet"
);

my $success_admin_share_other_project = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' =>
              'AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3',    # Globex
            'project_token' => $new_project_token,
            'role_name'     => 'fireman',
        }
    )
);

is( $success_admin_share_other_project->code(), 200, );

my $success_admin_share_other_project_json =
  decode_json( $success_admin_share_other_project->content );

is( $success_admin_share_other_project_json->{status},  1, );
is( $success_admin_share_other_project_json->{message}, 'Project shared.', );

my $success_admin_share_other_project_other_organization = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',    # Daedalus Project
            'project_token' => $new_project_token,
            'role_name'     => 'maze_master',
        }
    )
);

is( $success_admin_share_other_project_other_organization->code(), 200, );

my $success_admin_share_other_project_other_organization_json =
  decode_json( $success_admin_share_other_project_other_organization->content );

is( $success_admin_share_other_project_other_organization_json->{status}, 1, );
is(
    $success_admin_share_other_project_other_organization_json->{message},
    'Project shared.',
);

my $success_admin_new_project_shared = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega shops
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

my $success_admin_new_project_shared_json =
  decode_json( $success_admin_new_project_shared->content );

is( $success_admin_new_project_shared_json->{status}, 1, );

is( $success_admin_new_project_shared_json->{_hidden_data}, undef, );

isnt( $success_admin_new_project_shared_json->{data},             undef, );
isnt( $success_admin_new_project_shared_json->{data}->{projects}, undef, );

is( keys %{ $success_admin_new_project_shared_json->{data}->{projects} },
    2, 'There are two projects now.' );

is(
    $success_admin_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{name},
    "Mega Shops blog",

);

isnt(
    $success_admin_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with},
    undef, "Not shared yet"
);

is(
    $success_admin_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW},
    undef, "Not shared with this organization"
);

isnt(
    $success_admin_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3},
    undef,
);

is(
    $success_admin_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3}
      ->{organization_name},
    "Globex",
);

is(
    $success_admin_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO}
      ->{organization_name},
    "Daedalus Project",
);

is(
    @{
        $success_admin_new_project_shared_json->{data}->{projects}
          ->{$new_project_token}->{shared_with}
          ->{FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO}->{shared_roles}
    }[0],
    'maze_master',
);

my $success_superadmin_check_new_project_shared = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega shops
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

my $success_superadmin_check_new_project_shared_json =
  decode_json( $success_superadmin_check_new_project_shared->content );

is( $success_superadmin_check_new_project_shared_json->{status}, 1, );

isnt( $success_superadmin_check_new_project_shared_json->{_hidden_data}, undef,
);

isnt( $success_superadmin_check_new_project_shared_json->{data}, undef, );
isnt( $success_superadmin_check_new_project_shared_json->{data}->{projects},
    undef, );

is(
    keys
      %{ $success_superadmin_check_new_project_shared_json->{data}->{projects}
      },
    2,
    'There are two projects now.'
);

is(
    $success_superadmin_check_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{name},
    "Mega Shops blog",

);

isnt(
    $success_superadmin_check_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with},
    undef, "Not shared yet"
);

is(
    $success_superadmin_check_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW},
    undef, "Not shared with this organization"
);

isnt(
    $success_superadmin_check_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3},
    undef,
);

is(
    $success_superadmin_check_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3}
      ->{organization_name},
    "Globex",
);

is(
    $success_superadmin_check_new_project_shared_json->{data}->{projects}
      ->{$new_project_token}->{shared_with}->{FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO}
      ->{organization_name},
    "Daedalus Project",
);

is(
    @{
        $success_superadmin_check_new_project_shared_json->{data}->{projects}
          ->{$new_project_token}->{shared_with}
          ->{FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO}->{shared_roles}
    }[0],
    'maze_master',
);

isnt( $success_superadmin_check_new_project_shared_json->{_hidden_data}->{user},
    undef, );

is(
    $success_superadmin_check_new_project_shared_json->{_hidden_data}
      ->{projects}->{$new_project_token}->{shared_with}
      ->{FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO}->{id},
    1, "Daedalus project organization id"
);

done_testing();

DatabaseSetUpTearDown::delete_database();
