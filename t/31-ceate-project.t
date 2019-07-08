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

my $endpoint = '/project';

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

my $failed_no_admin = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_name'       => 'megashopsblog',
        }
    )
);

is( $failed_no_admin->code(), 400, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, );
is(
    $failed_no_admin_json->{message},
    'Invalid organization token.',
    "Actually your are not an admin user but API is not going to tell you."
);

my $failed_no_project_name = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        { organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf' }
    ),
);

is( $failed_no_project_name->code(), 400, );
#
my $failed_no_project_name_json =
  decode_json( $failed_no_project_name->content );

is( $failed_no_project_name_json->{status},  0, );
is( $failed_no_project_name_json->{message}, 'No project_name provided.', );

my $failed_non_existent_organization_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942PAf',
            'project_name'       => 'megashopsblog',
        }
    )
);

is( $failed_non_existent_organization_token->code(), 400, );

my $failed_non_existent_organization_token_json =
  decode_json( $failed_non_existent_organization_token->content );

is( $failed_non_existent_organization_token_json->{status}, 0, );
is(
    $failed_non_existent_organization_token_json->{message},
    'Invalid organization token.',
    "Same error code and message, this time organization does not exist."
);

my $create_project_success = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_name'       => 'megashopsblog',
        }
    )
);

is( $create_project_success->code(), 200, );

my $create_project_success_json =
  decode_json( $create_project_success->content );

is( $create_project_success_json->{status}, 1, );
is( $create_project_success_json->{message}, 'Project Created.', "Success" );

my $failed_project_with_same_name = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_name'       => 'megashopsblog',
        }
    )
);

is( $failed_project_with_same_name->code(), 400, );

my $failed_project_with_same_name_json =
  decode_json( $failed_project_with_same_name->content );

is( $failed_non_existent_organization_token_json->{status}, 0, );
is(
    $failed_non_existent_organization_token_json->{message},
    'Invalid organization token.',
    "Same error code and message, this time organization does not exist."
);

my $failed_project_not_my_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            'project_name'       => 'megashopsshop',
        }
    )
);

is( $failed_project_with_same_name->code(), 400, );

my $failed_project_with_same_name_json =
  decode_json( $failed_project_with_same_name->content );

is( $failed_non_existent_organization_token_json->{status}, 0, );
is( $failed_non_existent_organization_token_json->{message},
    'Required project name already exists inside this organization.', "" );

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

my $superadmin_create_project_success = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',    # Daedalus Project Token
            'project_name' => 'DaedalusGorgon',
        }
    )
);

is( $superadmin_create_project_success->code(), 200, );

my $superadmin_create_project_success_json =
  decode_json( $superadmin_create_project_success->content );

is( $superadmin_create_project_success_json->{status}, 1, );
is( $superadmin_create_project_success_json->{message},
    'Project Created.', "Success" );

my $superadmin_create_duplicated_project_fail = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'project_name'       => 'megashopsshop',
        }
    )
);

is( $superadmin_create_duplicated_project_fail->code(), 400, );

my $superadmin_create_duplicated_project_fail_json =
  decode_json( $superadmin_create_duplicated_project_fail->content );

is( $superadmin_create_duplicated_project_fail_json->{status}, 0, );
is( $superadmin_create_duplicated_project_fail_json->{message},
    'Required project name already exists inside this organization.', "" );

my $superadmin_create_project_other_organization_success = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Daedalus Project Token
            'project_name' => 'megashopsshop2',
        }
    )
);

is( $superadmin_create_project_other_organization_success->code(), 200, );

my $superadmin_create_project_other_organization_success_json =
  decode_json( $superadmin_create_project_other_organization_success->content );

is( $superadmin_create_project_other_organization_success_json->{status}, 1, );
is( $superadmin_create_project_other_organization_success_json->{message},
    'Project Created.', "Success" );

done_testing();

DatabaseSetUpTearDown::delete_database();
