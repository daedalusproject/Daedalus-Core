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

my $endpoint = '/project/share/group';

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
    'No group_token provided. No shared_project_token provided.',
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

my $failed_admin_no_group_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'   => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' => 'Quuph8Josahpeibeixeng7oth7phuP9b',
        }
    )
);

is( $failed_admin_no_group_token->code(), 400, );

my $failed_admin_no_group_token_json =
  decode_json( $failed_admin_no_group_token->content );

is( $failed_admin_no_group_token_json->{status},  0, );
is( $failed_admin_no_group_token_json->{message}, 'No group_token provided.', );

my $failed_no_group_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'   => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' => 'Quuph8Josahpeibeixeng7oth7phuP9b',
        }
    )
);

is( $failed_no_group_token->code(), 403, );

my $failed_no_group_token_json = decode_json( $failed_no_group_token->content );

is( $failed_no_group_token_json->{status}, 0, );
is(
    $failed_no_group_token_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

my $failed_admin_non_existent_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'   => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pua',
            'shared_project_token' => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'group_token'          => '8B8hl0RNItqemT2d4v4mJgYo6GssPzG8g',
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
            'organization_token'   => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pua',
            'shared_project_token' => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'group_token'          => '8B8hl0RNItqemT2d4v4mJgYo6GssPzG8g',
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

my $failed_admin_too_short_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'   => 'ljMPXvVHZZQWA2kgSWzL942Puf',
            'shared_project_token' => 'Quuph8Josahpeibeixeng7oth7phuP9a',
            'group_token'          => '8B8hl0RNItqemT2d4v4mJgYo6GssPzG8g',
        }
    )
);

is( $failed_admin_too_short_organization->code(), 400, );

my $failed_admin_too_short_organization_json =
  decode_json( $failed_admin_too_short_organization->content );

is( $failed_admin_too_short_organization_json->{status}, 0, );
is(
    $failed_admin_too_short_organization_json->{message},
    'Invalid organization token.',
);

my $failed_admin_invalid_project_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'   => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' => 'duuph8Josahpeibeixeng7oth7phuP9a',
            'group_token'          => 'EC78R91DADJowsNogz16pHnAcEBiQHWBF',
        }
    )
);

is( $failed_admin_invalid_project_token->code(), 400, );

my $failed_admin_invalid_project_token_json =
  decode_json( $failed_admin_invalid_project_token->content );

is( $failed_admin_invalid_project_token_json->{status}, 0, );
is(
    $failed_admin_invalid_project_token_json->{message},
    'Invalid shared_project_token.',
);

my $failed_admin_invalid_group_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' => '1qB8hl0RNItqemT2d4v4mJgYo6GssPzG8g',
        }
    )
);

is( $failed_admin_invalid_group_token->code(), 400, );

my $failed_admin_invalid_group_token_json =
  decode_json( $failed_admin_invalid_group_token->content );

is( $failed_admin_invalid_group_token_json->{status}, 0, );
is( $failed_admin_invalid_group_token_json->{message}, 'Invalid group_token.',
);

my $failed_no_admin = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' => '8B8hl0RNItqemT2d4v4mJgYo6GssPzG8g',
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
            'organization_token'   => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' => 'eph3Aih4fohng1phawijae',
            'group_token'          => 'EC78R91DADJowsNogz16pHnAcEBiQHWBF',
        }
    )
);

is( $failed_project_token_too_short->code(), 400, );

my $failed_project_token_too_short_json =
  decode_json( $failed_project_token_too_short->content );

is( $failed_project_token_too_short_json->{status}, 0, );
is(
    $failed_project_token_too_short_json->{message},
    'Invalid shared_project_token.',
    "Because it is too short"
);

my $failed_project_token_too_long = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'eph3Aih4foifsfhhq87wat7qssmFGSD4t43serg5srrhng1phawijae',
            'group_token' => 'EC78R91DADJowsNogz16pHnAcEBiQHWBF',
        }
    )
);

is( $failed_project_token_too_long->code(), 400, );

my $failed_project_token_too_long_json =
  decode_json( $failed_project_token_too_long->content );

is( $failed_project_token_too_long_json->{status}, 0, );
is(
    $failed_project_token_too_long_json->{message},
    'Invalid shared_project_token.',
    "Because it is too long"
);

my $failed_not_project_not_shared_with_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'eabi7ooph3Aih4fohc5aung1phawijae',    # Daedalus Core
            'group_token' => 'EC78R91DADJowsNogz16pHnAcEBiQHWBF',
        }
    )
);

is( $failed_not_project_not_shared_with_organization->code(), 400, );

my $failed_not_project_not_shared_with_organization_json =
  decode_json( $failed_not_project_not_shared_with_organization->content );

is( $failed_not_project_not_shared_with_organization_json->{status}, 0, );
is(
    $failed_not_project_not_shared_with_organization_json->{message},
    'Invalid shared_project_token.',
    "It exists but Core is not going to tell you."
);

my $failed_group_token_too_long = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' =>
              '8B8hl0sdajdhajhgdskhjagdajshgdRNItqemT2d4v4mJgYo6GssPzG8g',
        }
    )
);

is( $failed_group_token_too_long->code(), 400, );

my $failed_group_token_too_long_json =
  decode_json( $failed_group_token_too_long->content );

is( $failed_group_token_too_long_json->{status}, 0, );
is(
    $failed_group_token_too_long_json->{message},
    'Invalid group_token.',
    "Because it is too long"
);

my $failed_not_valid_group_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' => '8B8hl0RNItqemTqYmv4mJgYo6GssPzG8g'
            ,    # Daedalus Super Administrators
        }
    )
);

is( $failed_not_valid_group_token->code(), 400, );

my $failed_not_valid_group_token_json =
  decode_json( $failed_not_valid_group_token->content );

is( $failed_not_valid_group_token_json->{status}, 0, );
is(
    $failed_not_valid_group_token_json->{message},
    'Invalid group_token.',
    "It exists but Core is not going to tell you."
);

my $failed_project_not_shared = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',   # Mega Shops Administrators
        }
    )
);

is( $failed_project_not_shared->code(), 400, );

my $failed_project_not_shared_json =
  decode_json( $failed_project_not_shared->content );

is( $failed_project_not_shared_json->{status}, 0, );
is(
    $failed_project_not_shared_json->{message},
    'Invalid shared_project_token.',
    "Project is not shared, yet."
);

my $share_project = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'health_watcher'
        }
    )
);

is( $share_project->code(), 200, );

my $share_project_json = decode_json( $share_project->content );

is( $share_project_json->{status},  1, );
is( $share_project_json->{message}, 'Project shared.', );

my $failed_not_shared_at_this_role = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',   # Mega Shops Administrators
        }
    )
);

is( $failed_not_shared_at_this_role->code(), 400, );

my $failed_not_shared_at_this_role_json =
  decode_json( $failed_not_shared_at_this_role->content );

is( $failed_not_shared_at_this_role_json->{status}, 0, );
is(
    $failed_not_shared_at_this_role_json->{message},
    'Project not shared with any of the roles of this group.',
);

my $share_project_other_role = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'          => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'fireman'
        }
    )
);

is( $share_project_other_role->code(), 200, );

my $share_project_other_role_json =
  decode_json( $share_project_other_role->content );

is( $share_project_other_role_json->{status},  1, );
is( $share_project_other_role_json->{message}, 'Project shared.', );

my $success_admin = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',   # Mega Shops Administrators
        }
    )
);

is( $success_admin->code(), 200, );

my $success_admin_json = decode_json( $success_admin->content );

is( $success_admin_json->{status},  1, );
is( $success_admin_json->{message}, 'Group added to shared project.', );

my $failed_group_token_already_added = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',   # Mega Shops Administrators
        }
    )
);

is( $failed_group_token_already_added->code(), 400, );

my $failed_group_token_already_added_json =
  decode_json( $failed_group_token_already_added->content );

is( $failed_group_token_already_added_json->{status}, 0, );
is( $failed_group_token_already_added_json->{message},
    'This group has already been added to this shared project.', "" );

my $superadmin_add_bugs_project = request(
    POST "/project/share",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' =>
              'cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW',    # Bugs Tech
            'organization_to_share_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_token' =>
              'igcSJAryn0ZoK7tns9StDJwU4mi1Wcpj',    # Bugs e-commerce
            'role_name' => 'fireman',
        }
    )
);

is( $superadmin_add_bugs_project->code(), 200, );

my $superadmin_add_bugs_project_json =
  decode_json( $superadmin_add_bugs_project->content );

is( $superadmin_add_bugs_project_json->{status},  1, );
is( $superadmin_add_bugs_project_json->{message}, 'Project shared.', );

my $superadmin_failed_not_project = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',   # Mega Shops Administrators
        }
    )
);

is( $superadmin_failed_not_project->code(), 400, );

my $superadmin_failed_not_project_json =
  decode_json( $superadmin_failed_not_project->content );

is( $superadmin_failed_not_project_json->{status},  0, );
is( $superadmin_failed_not_project_json->{message}, 'Invalid group_token.', );

my $superadmin_bugs_project = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'igcSJAryn0ZoK7tns9StDJwU4mi1Wcpj',    # Bugs e-commerce
            'group_token' =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',    # Bugs tech Administrators
        }
    )
);

is( $superadmin_bugs_project->code(), 200, );

my $superadmin_bugs_project_json =
  decode_json( $superadmin_bugs_project->content );

is( $superadmin_bugs_project_json->{status}, 1, );
is(
    $superadmin_bugs_project_json->{message},
    'Group added to shared project.',
);

done_testing();

DatabaseSetUpTearDown::delete_database();
