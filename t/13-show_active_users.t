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

use Data::Dumper;
DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

my $endpoint = "/user/showactive";

my $show_inactive_users_GET_content = get($endpoint);
ok( $show_inactive_users_GET_content, qr /Method GET not implemented/ );

my $failed_because_no_auth = request(
    GET $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

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

# admin@daedalus-project.io has registered two users for the time being, one user confirmed its registration

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

my $admin_zero_users = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $admin_zero_users->code(), 200, );

my $admin_zero_users_json = decode_json( $admin_zero_users->content );

is( $admin_zero_users_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_zero_users_json->{data}->{active_users} },
    0, 'There are no active users' );

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

my $admin_still_zero_users = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $admin_still_zero_users->code(), 200, );

my $admin_still_zero_users_json =
  decode_json( $admin_still_zero_users->content );

is( $admin_still_zero_users_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_still_zero_users_json->{data}->{active_users} },
    0, 'There are noactive users yet' );

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

my $admin_one_user = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $admin_one_user->code(), 200, );

my $admin_one_user_json = decode_json( $admin_one_user->content );

is( $admin_one_user_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_one_user_json->{data}->{active_users} },
    1, 'There is one active user' );

my $other_admin_success = request(
    POST '/user/login',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'e-mail' => 'adminagain@daedalus-project.io',
            password => '__:___Password_1234',
        }
    )
);

is( $other_admin_success->code(), 200, );

my $other_admin_success_json = decode_json( $other_admin_success->content );

is( $other_admin_success_json->{status}, 1, );

my $other_admin_session_token =
  $other_admin_success_json->{data}->{session_token};

my $other_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$other_admin_session_token", '' );

my $anotheradmin_admin_zero_users = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $other_admin_authorization_basic",
);

is( $anotheradmin_admin_zero_users->code(), 200, );

my $anotheradmin_admin_zero_users_json =
  decode_json( $anotheradmin_admin_zero_users->content );

is( $anotheradmin_admin_zero_users_json->{status}, 1,
    'Status success, admin.' );
is( keys %{ $anotheradmin_admin_zero_users_json->{data}->{active_users} },
    0, 'adminagain@daedalus-project.io has 0 users active' );

is( $anotheradmin_admin_zero_users_json->{_hidden_data},
    undef, 'adminagain@daedalus-project.io is not super admin.' );

# Let's confirm one of admin@daedalus-project.io inactive users
# othernotanadmin@daedalus-project.io

# Register other new user

my $success_superadmin_register_other_user = request(
    POST '/user/register',
    Authorization => "Basic $superadmin_authorization_basic",
    Content_Type  => 'application/json',
    Content       => encode_json(
        {
            'e-mail' => 'othernotanadmin2@daedalus-project.io',
            name     => 'Other 2',
            surname  => 'Not Admin 2',
        }
    )
);

is( $success_superadmin_register_other_user->code(), 200, );

my $success_superadmin_register_other_user_json =
  decode_json( $success_superadmin_register_other_user->content );

is( $success_superadmin_register_other_user_json->{status},
    1, 'User has been created.' );
is(
    $success_superadmin_register_other_user_json->{message},
    'User has been registered.',
    'User registered.'
);
is(
    $success_superadmin_register_other_user_json->{_hidden_data}->{new_user}
      ->{'e-mail'},
    'othernotanadmin2@daedalus-project.io',
);

isnt( $success_superadmin_register_other_user_json->{data}->{new_user}->{token},
    undef, );

# This new user is inactive

my $admin_one_inactive_user = request(
    GET '/user/showinactive',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

#anotheradmin@daedalus-project.io
my $admin_one_inactive_user_json =
  decode_json( $admin_one_inactive_user->content );

is( $admin_one_inactive_user_json->{status}, 1, 'Status success, admin.' );

my $inactive_user_data_auth_token =
  $admin_one_inactive_user_json->{_hidden_data}->{inactive_users}
  ->{'othernotanadmin2@daedalus-project.io'}->{auth_token};

my $success_valid_auth_token_and_password = request(
    POST '/user/confirm',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth_token => $inactive_user_data_auth_token,
            password   => 'val1d_Pa55w0rd',
        }
    )
);

is( $success_valid_auth_token_and_password->code(), 200 );

# Check users

my $admin_two_users = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $admin_two_users->code(), 200, );

my $admin_two_users_json = decode_json( $admin_two_users->content );

is( $admin_two_users_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_two_users_json->{data}->{active_users} },
    2, 'Now, There are two active users' );

isnt( $admin_two_users_json->{_hidden_data},
    undef, 'admin@daedalus-project.io is super admin.' );

isnt(
    $admin_two_users_json->{data}->{active_users}
      ->{'othernotanadmin2@daedalus-project.io'}->{token},
    undef
);

done_testing();

DatabaseSetUpTearDown::delete_database();
