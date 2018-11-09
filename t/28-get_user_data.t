use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

my $endpoint = '/user';

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

my $not_admin_get_data = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $not_admin_get_data->code(), 200, );

my $not_admin_get_data_json = decode_json( $not_admin_get_data->content );

is( $not_admin_get_data_json->{status},  1, );
is( $not_admin_get_data_json->{message}, undef, );

is(
    $not_admin_get_data_json->{data}->{user}->{"e-mail"},
    'notanadmin@daedalus-project.io',
);
is( $not_admin_get_data_json->{data}->{user}->{name},    "NoAdmin", );
is( $not_admin_get_data_json->{data}->{user}->{surname}, "User", );
is(
    $not_admin_get_data_json->{data}->{user}->{api_key},
    "lTluauLErCtXhbBdyxfpVHpdodiBaJb",
);
is( $not_admin_get_data_json->{data}->{user}->{is_admin},   0, );
is( $not_admin_get_data_json->{data}->{user}->{active},     1, );
is( $not_admin_get_data_json->{data}->{user}->{phone},      "", );
is( $not_admin_get_data_json->{data}->{user}->{auth_token}, undef, );
is( $not_admin_get_data_json->{_hidden_data},               undef, );

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

my $admin_get_data = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_get_data->code(), 200, );

my $admin_get_data_json = decode_json( $admin_get_data->content );

is( $admin_get_data_json->{status},  1, );
is( $admin_get_data_json->{message}, undef, );

is(
    $admin_get_data_json->{data}->{user}->{"e-mail"},
    'otheradminagain@megashops.com',
);
is( $admin_get_data_json->{data}->{user}->{name},    "Admin", );
is( $admin_get_data_json->{data}->{user}->{surname}, "User", );
is(
    $admin_get_data_json->{data}->{user}->{api_key},
    "1TluauLErCtXhbBdyxfpVHpfifoBaJb",
);
is( $admin_get_data_json->{data}->{user}->{is_admin},   1, );
is( $admin_get_data_json->{data}->{user}->{active},     1, );
is( $admin_get_data_json->{data}->{user}->{phone},      "", );
is( $admin_get_data_json->{data}->{user}->{auth_token}, undef, );
is( $admin_get_data_json->{_hidden_data},               undef, );

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

my $super_admin_get_data = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $super_admin_authorization_basic",
);

is( $super_admin_get_data->code(), 200, );

my $super_admin_get_data_json = decode_json( $super_admin_get_data->content );

is( $super_admin_get_data_json->{status},  1, );
is( $super_admin_get_data_json->{message}, undef, );

is(
    $super_admin_get_data_json->{data}->{user}->{"e-mail"},
    'otheradminagain@megashops.com',
);
is( $super_admin_get_data_json->{data}->{user}->{name},    "Admin", );
is( $super_admin_get_data_json->{data}->{user}->{surname}, "User", );
is(
    $super_admin_get_data_json->{data}->{user}->{api_key},
    "1TluauLErCtXhbBdyxfpVHpfifoBaJb",
);
is( $super_admin_get_data_json->{data}->{user}->{is_admin},   1, );
is( $super_admin_get_data_json->{data}->{user}->{active},     1, );
is( $super_admin_get_data_json->{data}->{user}->{phone},      "", );
is( $super_admin_get_data_json->{data}->{user}->{auth_token}, undef, );
isnt( $super_admin_get_data_json->{_hidden_data}, undef, );
is( $super_admin_get_data_json->{_hidden_data}->{user}->{id},             1, );
is( $super_admin_get_data_json->{_hidden_data}->{user}->{is_super_admin}, 1, );

done_testing();
