use v5.26;
use strict;
use warnings;
use Test::More;

use Data::Dumper;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

my $endpoint = "/user/showorphan";

my $failed_because_no_auth =
  request( GET $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_auth->code(), 400, );

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is( $failed_because_no_auth_json->{status},  0, );
is( $failed_because_no_auth_json->{message}, 'No session token provided.', );

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
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",

);

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'You are not an admin user.', );

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

my $admin_user_mega_shop_organization = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $admin_user_mega_shop_organization->code(), 200, );

my $megashops_admin_valid_token = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $megashops_admin_valid_token->code(), 200, );

my $megashops_admin_valid_token_json =
  decode_json( $megashops_admin_valid_token->content );

is( $megashops_admin_valid_token_json->{status}, 1, );

is( keys %{ $megashops_admin_valid_token_json->{data}->{users} },
    0, 'Mega Shops admin has no orphan users' );

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

my $success_superadmin_register = request(
    POST '/user/register',
    Authorization => "Basic $superadmin_authorization_basic",
    Content_Type  => 'application/json',
    Content       => encode_json(
        {
            'e-mail' => 'othernotanadmin@daedalus-project.io',
            name     => 'Other',
            surname  => 'Not Admin',
        }
    )
);

is( $success_superadmin_register->code(), 200, );

my $success_superadmin_register_json =
  decode_json( $success_superadmin_register->content );

is( $success_superadmin_register_json->{status}, 1, 'User has been created.' );
is(
    $success_superadmin_register_json->{message},
    'User has been registered.',
    'User registered.'
);
is(
    $success_superadmin_register_json->{_hidden_data}->{new_user}->{'e-mail'},
    'othernotanadmin@daedalus-project.io',
);

isnt( $success_superadmin_register_json->{data}->{new_user}->{token}, undef, );

my $othernotanadmin_auth_token =
  $success_superadmin_register_json->{_hidden_data}->{new_user}->{auth_token};

my $othernotanadmin_confirms_registration = request(
    POST '/user/confirm',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth_token => $othernotanadmin_auth_token,
            password   => 'val1d_Pa55w0rd',
        }
    )
);

is( $othernotanadmin_confirms_registration->code(), 200 );

my $othernotanadmin_confirms_registration_json =
  decode_json( $othernotanadmin_confirms_registration->content );

is( $othernotanadmin_confirms_registration_json->{status},
    1, 'Password changed, account is activated.' );
is(
    $othernotanadmin_confirms_registration_json->{message},
    'Account activated.',
    'Auth token has changed.'
);

my $daedalus_admin = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $daedalus_admin->code(), 200, );

my $daedalus_admin_json = decode_json( $daedalus_admin->content );

is( keys %{ $daedalus_admin_json->{data}->{orphan_users} },
    1, 'Daedalus Project has only one user so far' );

isnt( $daedalus_admin_json->{_hidden_data},
    undef, "Superadmin users see hidden_data" );

# marvin@megashops.com confirms its registration

request(
    POST '/user/confirm',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth_token =>
              '1qYyhZWMikdm9WK6q/2376cqSoRxO2222UBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l',
            password => '1_HAt3_mY_L1F3',
        }
    )
);

my $magashops_admin_one_new_user = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $magashops_admin_one_new_user->code(), 200, );

my $magashops_admin_one_new_user_json =
  decode_json( $magashops_admin_one_new_user->content );

is( keys %{ $magashops_admin_one_new_user_json->{data}->{orphan_users} },
    1, 'Marvin is orphan.' );

is( $magashops_admin_one_new_user_json->{_hidden_data},
    undef, "Non Superadmin users do not see hidden_data" );

isnt(
    $magashops_admin_one_new_user_json->{data}->{orphan_users}
      ->{'marvin@megashops.com'}->{token},
    undef
);

done_testing();

DatabaseSetUpTearDown::delete_database();
