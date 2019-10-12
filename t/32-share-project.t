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

my $endpoint = '/project/share';

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

my $failed_no_organization_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_no_organization_token->code(), 400, );

my $failed_no_organization_token_json =
  decode_json( $failed_no_organization_token->content );

is( $failed_no_organization_token_json->{status}, 0, );
is(
    $failed_no_organization_token_json->{message},
    'No organization_token provided.',
);

my $failed_admin_no_organization_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_admin_no_organization_token->code(), 400, );

my $failed_admin_no_organization_token_json =
  decode_json( $failed_admin_no_organization_token->content );

is( $failed_admin_no_organization_token_json->{status}, 0, );
is(
    $failed_admin_no_organization_token_json->{message},
    'No organization_token provided.',
);

my $failed_admin_no_project_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
        }
    )
);

is( $failed_admin_no_project_token->code(), 400, );

my $failed_admin_no_project_token_json =
  decode_json( $failed_admin_no_project_token->content );

is( $failed_admin_no_project_token_json->{status}, 0, );
is(
    $failed_admin_no_project_token_json->{message},
'No organization_to_share_token provided. No project_token provided. No role_name provided.',
);

my $failed_no_project_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
        }
    )
);

is( $failed_no_project_token->code(), 403, );

my $failed_no_project_token_json =
  decode_json( $failed_no_project_token->content );

is( $failed_no_project_token_json->{status}, 0, );
is(
    $failed_no_project_token_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

my $failed_admin_no_organization_to_share_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token'      => 'Quuph8Josahpeibeixeng7oth7phuP9b',
        }
    )
);

is( $failed_admin_no_organization_to_share_token->code(), 400, );

my $failed_admin_no_organization_to_share_token_json =
  decode_json( $failed_admin_no_organization_to_share_token->content );

is( $failed_admin_no_organization_to_share_token_json->{status}, 0, );
is(
    $failed_admin_no_organization_to_share_token_json->{message},
    'No organization_to_share_token provided. No role_name provided.',
);

my $failed_no_organization_to_share_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token'      => 'Quuph8Josahpeibeixeng7oth7phuP9b',
        }
    )
);

is( $failed_no_organization_to_share_token->code(), 403, );

my $failed_no_organization_to_share_token_json =
  decode_json( $failed_no_organization_to_share_token->content );

is( $failed_no_organization_to_share_token_json->{status}, 0, );
is(
    $failed_no_project_token_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

my $failed_admin_no_role_name = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token'               => 'oqu2eeCee2Amae6Aijo7tei5woh4jiet',
        }
    )
);

is( $failed_admin_no_role_name->code(), 400, );

my $failed_admin_no_role_name_json =
  decode_json( $failed_admin_no_role_name->content );

is( $failed_admin_no_role_name_json->{status},  0, );
is( $failed_admin_no_role_name_json->{message}, 'No role_name provided.', );

my $failed_no_role_name = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token'               => 'Quuph8Josahpeibeixeng7oth7phuP9b',
        }
    )
);

is( $failed_no_role_name->code(), 403, );

my $failed_no_role_name_json = decode_json( $failed_no_role_name->content );

is( $failed_no_role_name_json->{status}, 0, );
is(
    $failed_no_role_name_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

my $failed_admin_non_existent_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pua',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pua',
            'project_token'               => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'role_name'                   => 'firemann',
        }
    )
);

is( $failed_admin_non_existent_organization->code(), 400, );

my $failed_admin_non_existent_organization_json =
  decode_json( $failed_admin_non_existent_organization->content );

is( $failed_admin_non_existent_organization_json->{status}, 0, );
is(
    $failed_admin_non_existent_organization_json->{message},
    'Invalid organization token.',
);

my $failed_non_existent_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pua',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pua',
            'project_token'               => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'role_name'                   => 'firemann',
        }
    )
);

is( $failed_non_existent_organization->code(), 400, );

my $failed_non_existent_organization_json =
  decode_json( $failed_non_existent_organization->content );

is( $failed_non_existent_organization_json->{status}, 0, );
is(
    $failed_non_existent_organization_json->{message},
    'Invalid organization token.',
);

my $failed_admin_non_existent_organization_to_share = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pua',
            'project_token'               => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'role_name'                   => 'fireman',
        }
    )
);

is( $failed_admin_non_existent_organization_to_share->code(), 400, );

my $failed_admin_non_existent_organization_to_share_json =
  decode_json( $failed_admin_non_existent_organization_to_share->content );

is( $failed_admin_non_existent_organization_to_share_json->{status}, 0, );
is(
    $failed_admin_non_existent_organization_to_share_json->{message},
    'Invalid organization_to_share_token.',
);

my $failed_admin_too_short_organization_to_share = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMZQTbXsaXWA2kgSWzL942Pua',
            'project_token'               => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'role_name'                   => 'firemann',
        }
    )
);

is( $failed_admin_too_short_organization_to_share->code(), 400, );

my $failed_admin_too_short_organization_to_share_json =
  decode_json( $failed_admin_too_short_organization_to_share->content );

is( $failed_admin_too_short_organization_to_share_json->{status}, 0, );
is(
    $failed_admin_too_short_organization_to_share_json->{message},
    'Invalid organization_to_share_token.',
);

my $failed_admin_invalid_project_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token'               => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'role_name'                   => 'firemann',
        }
    )
);

is( $failed_admin_invalid_project_token->code(), 400, );

my $failed_admin_invalid_project_token_json =
  decode_json( $failed_admin_invalid_project_token->content );

is( $failed_admin_invalid_project_token_json->{status}, 0, );
is(
    $failed_admin_invalid_project_token_json->{message},
    'Invalid project_token.',
);

my $failed_admin_role_name = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'nonsense',
        }
    )
);

is( $failed_admin_role_name->code(), 400, );

my $failed_admin_role_name_json =
  decode_json( $failed_admin_role_name->content );

is( $failed_admin_role_name_json->{status},  0, );
is( $failed_admin_role_name_json->{message}, 'Invalid role_name.', );

my $failed_no_admin = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'health_watcher',
        }
    )
);

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, );
is(
    $failed_no_admin_json->{message},
'Your organization roles does not match with the following roles: organization master.',
    "You are not your organization admin"
);

my $failed_project_token_too_short = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token'               => 'eph3Aih4fohng1phawijae',
            'role_name'                   => 'health_watcher',
        }
    )
);

is( $failed_project_token_too_short->code(), 400, );

my $failed_project_token_too_short_json =
  decode_json( $failed_project_token_too_short->content );

is( $failed_project_token_too_short_json->{status}, 0, );
is(
    $failed_project_token_too_short_json->{message},
    'Invalid project_token.',
    "Because it is too short"
);

my $failed_project_token_too_long = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'eph3Aih4foifsfhhq87wat7qssmFGSD4t43serg5srrhng1phawijae',
            'role_name' => 'health_watcher',
        }
    )
);

is( $failed_project_token_too_long->code(), 400, );

my $failed_project_token_too_long_json =
  decode_json( $failed_project_token_too_long->content );

is( $failed_project_token_too_long_json->{status}, 0, );
is(
    $failed_project_token_too_long_json->{message},
    'Invalid project_token.',
    "Because it is too long"
);

my $failed_not_organization_project = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'eabi7ooph3Aih4fohc5aung1phawijae',    # Daedalus Core
            'role_name' => 'health_watcher',
        }
    )
);

is( $failed_not_organization_project->code(), 400, );

my $failed_not_organization_project_json =
  decode_json( $failed_not_organization_project->content );

is( $failed_not_organization_project_json->{status}, 0, );
is(
    $failed_not_organization_project_json->{message},
    'Invalid project_token.',
    "It exists but Core is not going to tell you."
);

my $success_admin = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'health_watcher',
        }
    )
);

is( $success_admin->code(), 200, );

my $success_admin_json = decode_json( $success_admin->content );

is( $success_admin_json->{status},  1, );
is( $success_admin_json->{message}, 'Project shared.', );

my $failed_organization_project_already_shared = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Daedalus Core
            'role_name' => 'health_watcher',
        }
    )
);

is( $failed_organization_project_already_shared->code(), 400, );

my $failed_organization_project_already_shared_json =
  decode_json( $failed_organization_project_already_shared->content );

is( $failed_organization_project_already_shared_json->{status}, 0, );
is(
    $failed_organization_project_already_shared_json->{message},
'This project has been already shared with this organization and this role.',
    ""
);

my $success_admin_other_role = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'expenses_watcher',
        }
    )
);

is( $success_admin_other_role->code(), 200, );

my $success_admin_other_role_json =
  decode_json( $success_admin_other_role->content );

is( $success_admin_other_role_json->{status},  1, );
is( $success_admin_other_role_json->{message}, 'Project shared.', );

my $success_admin_share_with_other_organization = request(
    POST $endpoint,
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

my $failed_admin_share_not_your_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' =>
              'cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW',    # Bugs Tech
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'expenses_watcher',
        }
    )
);

is( $failed_admin_share_not_your_organization->code(), 400, );

my $failed_admin_share_not_your_organization_json =
  decode_json( $failed_admin_share_not_your_organization->content );

is( $failed_admin_share_not_your_organization_json->{status}, 0, );
is(
    $failed_admin_share_not_your_organization_json->{message},
    'Invalid organization token.',
);

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

my $super_admin_share_not_your_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' =>
              'cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW',    # Bugs Tech
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'expenses_watcher',
        }
    )
);

is( $super_admin_share_not_your_organization->code(), 200, );

my $super_admin_share_not_your_organization_json =
  decode_json( $super_admin_share_not_your_organization->content );

is( $super_admin_share_not_your_organization_json->{status}, 1, );
is(
    $super_admin_share_not_your_organization_json->{message},
    'Invalid organization token.',
);

done_testing();

#DatabaseSetUpTearDown::delete_database();
