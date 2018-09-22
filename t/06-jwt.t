use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

# Check if User is admin

## GET

my $non_admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'notanadmin@daedalus-project.io',
                password => 'Test_is_th1s_123',
            }
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

is( $not_admin_no_session_token_json->{status},  0, );
is( $not_admin_no_session_token_json->{message}, 'No sesion token provided.', );

my $not_admin_authorization_basic_broken =
  MIME::Base64::encode( "session_toke:notoken", '' );

my $not_admin_invalid_session_token = request( GET '/user/imadmin',
    Authorization => "Basic $not_admin_authorization_basic_broken", );

is( $not_admin_invalid_session_token->code(), 400, );

my $not_admin_invalid_session_token_json =
  decode_json( $not_admin_invalid_session_token->content );

is( $not_admin_invalid_session_token_json->{status}, 0, );
is(
    $not_admin_invalid_session_token_json->{message},
    'No sesion token provided.',
);

my $expired_admin_authorization_basic_failed =
  MIME::Base64::encode( "session_token:$not_admin_session_token", '' );

sleep 30;

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
