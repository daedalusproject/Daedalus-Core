use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

my $failed_because_no_auth_token =
  request( POST '/organization/create', Content_Type => 'application/json', );

is( $failed_because_no_auth_token->code(), 400, );

my $failed_because_no_auth_token_json =
  decode_json( $failed_because_no_auth_token->content );

is( $failed_because_no_auth_token_json->{status}, 0, );
is(
    $failed_because_no_auth_token_json->{message},
    'No session token provided.',
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

my $failed_no_admin = request(
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'You are not an admin user.', );

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

my $failed_no_name = request(
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( {} ),
);

is( $failed_no_name->code(), 400, );
#
my $failed_no_name_json = decode_json( $failed_no_name->content );

is( $failed_no_name_json->{status},  0, );
is( $failed_no_name_json->{message}, 'No name provided.', );

my $success = request(
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { name => "Supershops" } ),
);

is( $success->code(), 200, );
#
my $success_json = decode_json( $success->content );

is( $success_json->{status},  1, );
is( $success_json->{message}, 'Organization created.', );

is( $success_json->{_hidden_data}, undef, );

my $duplicated_name_fails = request(
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { name => "Supershops" } ),
);

is( $duplicated_name_fails->code(), 400, );
#
my $duplicated_name_fails_json = decode_json( $duplicated_name_fails->content );

is( $duplicated_name_fails_json->{status},  0, );
is( $duplicated_name_fails_json->{message}, 'Duplicated organization name.', );

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

my $superadmin_success = request(
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json( { name => "Ultrashops" } ),
);

is( $superadmin_success->code(), 200, );
#
my $superadmin_success_json = decode_json( $superadmin_success->content );

is( $superadmin_success_json->{status},  1, );
is( $superadmin_success_json->{message}, 'Organization created.', );

isnt( $superadmin_success_json->{_hidden_data}, undef, );

my $superadmin_failed_duplicated_name = request(
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json( { name => "Ultrashops" } ),    #Repeated name
);

is( $superadmin_failed_duplicated_name->code(), 400, );
#
my $superadmin_failed_duplicated_name_json =
  decode_json( $superadmin_failed_duplicated_name->content );

is( $superadmin_failed_duplicated_name_json->{status}, 0, );
is(
    $superadmin_failed_duplicated_name_json->{message},
    'Duplicated organization name.',
);

is( $superadmin_failed_duplicated_name_json->{_hidden_data},
    undef, 'If response code is not 2xx there is no hidden_data' );

done_testing();
