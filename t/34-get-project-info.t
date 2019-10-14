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

my $failed_no_organization_token_no_project_token = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_no_organization_token_no_project_token->code(), 404, );

my $failed_admin_no_organization_token_no_project_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_admin_no_organization_token_no_project_token->code(), 404, );

my $failed_invalid_organization_token = request(
    POST "$endpoint/someorganizationtoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_invalid_organization_token->code(), 404, );

my $failed_admin_invalid_organization_token = request(
    POST "$endpoint/someorganizationtoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_admin_invalid_organization_token->code(), 404, );

my $failed_not_your_organization = request(
    POST "$endpoint/cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW",    # Bugs Techs
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_authorization_basic",
);

is( $failed_not_your_organization->code(), 404, );

my $failed_admin_not_your_organization = request(
    POST "$endpoint/cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW",    # Bugs Techs
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_admin_not_your_organization->code(), 404, );

done_testing();

#DatabaseSetUpTearDown::delete_database();
