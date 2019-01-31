use strict;
use warnings;
use Test::More;

use Data::Dumper;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;

my $endpoint = '/organization/showusers';

my $failed_because_no_organization_token =
  request( GET $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_organization_token->code(), 404, );

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

my $failed_no_admin_no_organization_token = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin_no_organization_token->code(), 404, );

my $failed_no_admin = request(
    GET "$endpoint/sometoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 400, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'Invalid organization token.', );

my $admin_megashops_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $admin_megashops_success->code(), 200, );

my $admin_megashops_success_json =
  decode_json( $admin_megashops_success->content );

is( $admin_megashops_success_json->{status}, 1, );

my $admin_megashops_session_token =
  $admin_megashops_success_json->{data}->{session_token};

my $admin_megashops_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_megashops_session_token", '' );

my $megashops_admin_invalid_short_token = request(
    GET "$endpoint/somefailedtoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $megashops_admin_invalid_short_token->code(), 400, );

my $megashops_admin_invalid_short_token_json =
  decode_json( $megashops_admin_invalid_short_token->content );

is( $megashops_admin_invalid_short_token_json->{status}, 0, );
is(
    $megashops_admin_invalid_short_token_json->{message},
    'Invalid organization token.',
);

my $megashops_admin_invalid_token = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Pof",    #Almost the same token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $megashops_admin_invalid_token->code(), 400, );

my $megashops_admin_invalid_token_json =
  decode_json( $megashops_admin_invalid_token->content );

is( $megashops_admin_invalid_token_json->{status}, 0, );
is(
    $megashops_admin_invalid_token_json->{message},
    'Invalid organization token.',
);

my $megashops_admin_daedalus_token = request(
    GET
      "$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO", #Daedalus Organization token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $megashops_admin_daedalus_token->code(), 400, );

my $megashops_admin_daedalus_token_json =
  decode_json( $megashops_admin_invalid_token->content );

is( $megashops_admin_daedalus_token_json->{status}, 0, );
is(
    $megashops_admin_daedalus_token_json->{message},
    'Invalid organization token.',
);

my $megashops_admin_valid_token = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $megashops_admin_valid_token->code(), 200, );

my $megashops_admin_valid_token_json =
  decode_json( $megashops_admin_valid_token->content );

is( $megashops_admin_valid_token_json->{status}, 1, );

is( keys %{ $megashops_admin_valid_token_json->{data}->{users} },
    2, 'Mega Shops has two  users' );

is( $megashops_admin_valid_token_json->{_hidden_data},
    undef, 'Non Super admin users do no receive hidden data' );

my $superadmin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'admin@daedalus-project.io',
            password => 'this_is_a_Test_1234',
        }
    )
);

is( $superadmin_success->code(), 200, );

my $superadmin_success_json = decode_json( $superadmin_success->content );

is( $superadmin_success_json->{status}, 1, );

my $superadmin_session_token =
  $superadmin_success_json->{data}->{session_token};

my $superadmin_authorization_basic =
  MIME::Base64::encode( "session_token:$superadmin_session_token", '' );

my $superadmin_token = request(
    GET "$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_token->code(), 200, );

my $superadmin_token_json = decode_json( $superadmin_token->content );

is( keys %{ $superadmin_token_json->{data}->{users} },
    2, 'Daedalus Project has only two users so far' );

isnt( $superadmin_token_json->{_hidden_data},
    undef, 'Super admin users receive hidden data' );

my $superadmin_megashops_token = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    #Megashops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_megashops_token->code(), 200, );

my $superadmin_megashops_token_json =
  decode_json( $superadmin_megashops_token->content );

is( keys %{ $superadmin_megashops_token_json->{data}->{users} },
    2, 'Mega Shops has two  users' );

isnt( $superadmin_megashops_token_json->{_hidden_data},
    undef, 'Super admin users receive hidden data' );

isnt(
    $superadmin_megashops_token_json->{data}->{users}
      ->{'otheradminagain@megashops.com'},
    undef, 'otheradminagain@megashops.com belongs to megashops'
);

isnt(
    $superadmin_megashops_token_json->{data}->{users}
      ->{'otheradminagain@megashops.com'}->{token},
    undef, 'otheradminagain@megashops.com has a token'
);

sleep 10;

my $superadmin_expired_token = request(
    GET "$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_expired_token->code(), 400, );

my $superadmin_expired_token_json =
  decode_json( $superadmin_expired_token->content );

is( $superadmin_expired_token_json->{status},  0, );
is( $superadmin_expired_token_json->{message}, 'Session token expired.', );

done_testing();
