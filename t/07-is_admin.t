use v5.26;
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

# Check if User is admin

## GET

my $non_admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'notanadmin@daedalus-project.io',
            password => 'Test_is_th1s_123',
        }
    )
);

is( $non_admin_success->code(), 200, );

my $non_admin_success_json = decode_json( $non_admin_success->content );

is( $non_admin_success_json->{status}, 1, );

my $not_admin_session_token = $non_admin_success_json->{data}->{session_token};

my $not_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$not_admin_session_token", '' );

my $not_admin_user_get = request( GET '/user/imadmin',
    Authorization => "Basic $not_admin_authorization_basic", );

is( $not_admin_user_get->code(), 403, );

my $not_admin_user_get_json = decode_json( $not_admin_user_get->content );

is( $not_admin_user_get_json->{status},  0, );
is( $not_admin_user_get_json->{message}, 'You are not an admin user.', );

my $admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $admin_success->code(), 200, );

my $admin_success_json = decode_json( $admin_success->content );

is( $admin_success_json->{status}, 1, );

my $admin_session_token = $admin_success_json->{data}->{session_token};

my $admin_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_session_token", '' );

my $admin_user_get = request( GET '/user/imadmin',
    Authorization => "Basic $admin_authorization_basic", );

is( $admin_user_get->code(), 200, );

my $admin_user_get_json = decode_json( $admin_user_get->content );

is( $admin_user_get_json->{status},  1, );
is( $admin_user_get_json->{message}, 'You are an admin user.', );

isnt(
    $admin_user_get_json->{_hidden_data},
    'Only super admin users receive hidden data'
);

my $super_admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'admin@daedalus-project.io',
            password => 'this_is_a_Test_1234',
        }
    )
);

is( $super_admin_success->code(), 200, );

my $super_admin_success_json = decode_json( $super_admin_success->content );

is( $super_admin_success_json->{status}, 1, );

my $super_admin_session_token =
  $super_admin_success_json->{data}->{session_token};

my $super_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$super_admin_session_token", '' );

my $super_admin_user_get = request( GET '/user/imadmin',
    Authorization => "Basic $super_admin_authorization_basic", );

is( $super_admin_user_get->code(), 200, );

my $super_admin_user_get_json = decode_json( $super_admin_user_get->content );

is( $super_admin_user_get_json->{status},  1, );
is( $super_admin_user_get_json->{message}, 'You are an admin user.', );

is( $super_admin_user_get_json->{_hidden_data},
    undef, "Super admin does not get extra data in this endpoint" );

done_testing();

DatabaseSetUpTearDown::delete_database();
