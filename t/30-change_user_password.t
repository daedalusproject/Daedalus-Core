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

my $endpoint = '/user';

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

my $update_short_password = request(
    PUT $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            password => 'pass',
        }
      )

);

is( $update_short_password->code(), 400, );

my $update_short_password_json = decode_json( $update_short_password->content );

is( $update_short_password_json->{status}, 0, );
is(
    $update_short_password_json->{message},
    'Password is invalid.',
    'Password is too short.'
);

my $update_password_no_diverse = request(
    PUT $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            password => 'passwordddddddddddddd',
        }
      )

);

is( $update_password_no_diverse->code(), 400, );

my $update_password_no_diverse_json =
  decode_json( $update_password_no_diverse->content );

is( $update_password_no_diverse_json->{status}, 0, );
is(
    $update_password_no_diverse_json->{message},
    'Password is invalid.',
    'Password has no diverse characters.'
);

my $update_password_too_large = request(
    PUT $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            password =>
'val1d_Pa55w0rderaixei3ud1eew4Zee9ahch8ge5doomai2tewe1Chogh9aHaez5pa0queeng3Zeeweefeif9outeetuhie5exae3Ohtho4eesh2oow2reish2sheeph1ais6aedia4ee',
        }
      )

);

is( $update_password_too_large->code(), 400, );

my $update_password_too_large_json =
  decode_json( $update_password_too_large->content );

is( $update_password_too_large_json->{status}, 0, );
is(
    $update_password_too_large_json->{message},
    "'password' value is too large. Maximun number of characters is 128.",
);

my $update_password_success = request(
    PUT $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            password => 'val1d_Pa55w0rd',
        }
      )

);

is( $update_password_success->code(), 200, );

my $update_password_success_json =
  decode_json( $update_password_success->content );

is( $update_password_success_json->{status},  1, );
is( $update_password_success_json->{message}, 'Data updated: password.', );

my $get_data_now_fails = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $get_data_now_fails->code(), 400, );

my $get_data_now_fails_json = decode_json( $get_data_now_fails->content );

is( $get_data_now_fails_json->{status},  0, );
is( $get_data_now_fails_json->{message}, "Session token expired.", );

my $admin_login_now_fails = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $admin_login_now_fails->code(), 403, );

my $admin_login_now_fails_json = decode_json( $admin_login_now_fails->content );

is_deeply(
    $admin_login_now_fails_json,
    {
        'status'  => 0,
        'message' => 'Wrong e-mail or password.',
    }
);

# Session tokens uses seconds so it requests are done at the same second, token is invalid.

sleep 1;

my $admin_new_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => 'val1d_Pa55w0rd',
        }
    )
);

is( $admin_new_login_success->code(), 200, );

my $admin_new_login_success_json =
  decode_json( $admin_new_login_success->content );

is( $admin_new_login_success_json->{status}, 1, );

my $admin_new_login_success_token =
  $admin_new_login_success_json->{data}->{session_token};

my $admin_new_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_new_login_success_token", '' );

my $get_data_no_more_fails = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_new_authorization_basic",
);

is( $get_data_no_more_fails->code(), 200, );

done_testing();

DatabaseSetUpTearDown::delete_database();
