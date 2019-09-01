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

done_testing();

DatabaseSetUpTearDown::delete_database();
