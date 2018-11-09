use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

my $endpoint = '/user/update';

my $failed_because_no_auth_token =
  request( DELETE $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_auth_token->code(), 400, );

my $failed_because_no_auth_token_json =
  decode_json( $failed_because_no_auth_token->content );

is( $failed_because_no_auth_token_json->{status}, 0, );
is(
    $failed_because_no_auth_token_json->{message},
    "No session token provided.",
);

my $marvin_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'marvin@megashops.com',
            password => '1_HAT3_MY_L1F3',
        }
    )
);

is( $marvin_login_success->code(), 200, );

my $marvin_login_success_json = decode_json( $marvin_login_success->content );

is( $marvin_login_success_json->{status}, 1, );

my $marvin_login_success_token =
  $marvin_login_success_json->{data}->{session_token};

my $marvin_authorization_basic =
  MIME::Base64::encode( "session_token:$marvin_login_success_token", '' );

my $failed_no_token =
  request( DELETE $endpoint, Content_Type => 'application/json', );

is( $failed_no_token->code(), 400, );

my $failed_no_token_json = decode_json( $failed_no_token->content );

my $success_no_data = request(
    PUT $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $marvin_authorization_basic",
);

is( $success_no_data->code(), 200, );

my $success_no_data_json = decode_json( $success_no_data->content );

is( $success_no_data_json->{status},  0, );
is( $success_no_data_json->{message}, 'Nothing changed.', );

done_testing();
