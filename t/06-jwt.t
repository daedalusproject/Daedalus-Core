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

my $not_admin_authorization_basic_failed =
  MIME::Base64::encode( "session_toke:$not_admin_session_token", '' );

my $not_admin_no_session_token = request( GET '/user/imadmin',
    Authorization => "Basic $not_admin_authorization_basic_failed", );

is( $not_admin_no_session_token->code(), 400, );

my $not_admin_no_session_token_json =
  decode_json( $not_admin_no_session_token->content );

is( $not_admin_no_session_token_json->{status}, 0, );
is( $not_admin_no_session_token_json->{message}, 'No session token provided.',
);

my $not_admin_authorization_basic_broken =
  MIME::Base64::encode( "session_token:notoken", '' );

my $not_admin_invalid_session_token = request( GET '/user/imadmin',
    Authorization => "Basic $not_admin_authorization_basic_broken", );

is( $not_admin_invalid_session_token->code(), 400, );

my $not_admin_invalid_session_token_json =
  decode_json( $not_admin_invalid_session_token->content );

is( $not_admin_invalid_session_token_json->{status}, 0, );
is(
    $not_admin_invalid_session_token_json->{message},
    'Session token invalid.',
);

my $no_session_token_failed = MIME::Base64::encode( "session_token:", '' );

my $not_admin_no_session_token_povided = request( GET '/user/imadmin',
    Authorization => "Basic $no_session_token_failed", );

is( $not_admin_no_session_token_povided->code(), 400, );

my $not_admin_no_session_token_povided_json =
  decode_json( $not_admin_no_session_token_povided->content );

is( $not_admin_no_session_token_povided_json->{status}, 0, );
is(
    $not_admin_no_session_token_povided_json->{message},
    'No session token provided.',
);

$not_admin_no_session_token = request( GET '/user/imadmin',
    Authorization => "Basic $not_admin_authorization_basic_failed", );

is( $not_admin_no_session_token->code(), 400, );

$not_admin_no_session_token_json =
  decode_json( $not_admin_no_session_token->content );

is( $not_admin_no_session_token_json->{status}, 0, );
is( $not_admin_no_session_token_json->{message}, 'No session token provided.',
);

my $expired_admin_authorization_basic_failed =
  MIME::Base64::encode( "session_token:$not_admin_session_token", '' );

sleep 10;

my $not_admin_expired_session_token = request( GET '/user/imadmin',
    Authorization => "Basic $expired_admin_authorization_basic_failed", );

is( $not_admin_expired_session_token->code(), 400, );

my $not_admin_expired_session_token_json =
  decode_json( $not_admin_expired_session_token->content );

is( $not_admin_expired_session_token_json->{status}, 0, );
is(
    $not_admin_expired_session_token_json->{message},
    'Session token expired.',
);

done_testing();

DatabaseSetUpTearDown::delete_database();
