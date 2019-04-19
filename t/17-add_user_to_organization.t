use v5.26;
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

my $endpoint = '/organization/adduser';

my $failed_because_no_auth_token =
  request( POST $endpoint, Content_Type => 'application/json', );

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
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token         => 'invalidusertoken'
        }
    ),
);

is( $failed_no_admin->code(), 400, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'Invalid organization token.', );

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

my $success_register_megashops_user = request(
    POST '/user/register',
    Authorization => "Basic $admin_authorization_basic",
    Content_Type  => 'application/json',
    Content       => encode_json(
        {
            'e-mail' => 'shirorobot@megashops.com',
            name     => 'Shiro',
            surname  => 'Robot',
        }
    )
);

is( $success_register_megashops_user->code(), 200, );

my $success_register_megashops_user_json =
  decode_json( $success_register_megashops_user->content );

my $shirorobot_user_token =
  $success_register_megashops_user_json->{data}->{new_user}->{token};

my $failed_no_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( {} )
);

is( $failed_no_data->code(), 400, );
#
my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status},  0, );
is( $failed_no_data_json->{message}, 'No organization_token provided.', );

my $failed_no_user_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        { organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf' }
    ),
);

is( $failed_no_user_data->code(), 400, );

my $failed_no_user_data_json = decode_json( $failed_no_user_data->content );

is( $failed_no_user_data_json->{status},  0, );
is( $failed_no_user_data_json->{message}, 'No user_token provided.', );

my $failed_no_organization_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { user_token => 'sometoken' } ),
);

is( $failed_no_organization_data->code(), 400, );
#
my $failed_no_organization_data_json =
  decode_json( $failed_no_organization_data->content );

is( $failed_no_organization_data_json->{status}, 0, );
is(
    $failed_no_organization_data_json->{message},
    'No organization_token provided.',
);

my $failed_invalid_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token         => 'invalidtoken'
        }
    ),
);

is( $failed_invalid_data->code(), 400, );
#
my $failed_invalid_data_json = decode_json( $failed_invalid_data->content );

is( $failed_invalid_data_json->{status}, 0, );
is(
    $failed_invalid_data_json->{message},
    'user_token is invalid.',
    "token is checked first"
);

my $failed_user_token_not_found = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token         => '03QimYFYtn2O2c0WvkOhUuN4c8gJKOkv'
        }
    ),
);

is( $failed_user_token_not_found->code(), 400, );

my $failed_user_token_not_found_json =
  decode_json( $failed_user_token_not_found->content );

is( $failed_user_token_not_found_json->{status}, 0, );
is(
    $failed_user_token_not_found_json->{message},
    'There is no registered user with that token.',
);

my $failed_invalid_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token         => 'tooshort'
        }
    ),
);

is( $failed_invalid_token->code(), 400, );

my $failed_invalid_token_json = decode_json( $failed_invalid_token->content );

is( $failed_invalid_token_json->{status},  0, );
is( $failed_invalid_token_json->{message}, 'user_token is invalid.', );

my $failed_inactive_user = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token         => $shirorobot_user_token,
        }
    ),
);

is( $failed_inactive_user->code(), 400, );

my $failed_inactive_user_json = decode_json( $failed_inactive_user->content );

is( $failed_inactive_user_json->{status},  0, );
is( $failed_inactive_user_json->{message}, 'Required user is not active.', );

my $failed_non_existent_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic", #Daedalus Project token
    Content       => encode_json(
        {
            organization_token => 'nonexistentorganization',
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',        # marvin@megashops.com
        }
    ),
);

is( $failed_non_existent_organization->code(), 400, );
#
my $failed_non_existent_organization_json =
  decode_json( $failed_non_existent_organization->content );

is( $failed_non_existent_organization_json->{status}, 0, );
is(
    $failed_non_existent_organization_json->{message},
    'Invalid organization token.',
);

my $failed_not_my_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic", #Daedalus Project token
    Content       => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',        # marvin@megashops.com
        }
    ),
);

is( $failed_not_my_organization->code(), 400, );
#
my $failed_not_my_organization_json =
  decode_json( $failed_not_my_organization->content );

is( $failed_not_my_organization_json->{status}, 0, );
is(
    $failed_not_my_organization_json->{message},
    'Invalid organization token.',
);

my $add_user_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);

is( $add_user_success->code(), 200, );
#
my $add_user_success_json = decode_json( $add_user_success->content );

is( $add_user_success_json->{status},  1, );
is( $add_user_success_json->{message}, 'User has been registered.', );

is( $add_user_success_json->{_hidden_data}, undef, );

my $failed_already_registered = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);

is( $failed_already_registered->code(), 400, );

my $failed_already_registered_json =
  decode_json( $failed_already_registered->content );

is( $failed_already_registered_json->{status}, 0, );
is(
    $failed_already_registered_json->{message},
    'User already belongs to this organization.',
);

my $confirm_marvin_is_registered = request(
    GET "/organization/showusers/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $confirm_marvin_is_registered->code(), 200, );

my $confirm_marvin_is_registered_json =
  decode_json( $confirm_marvin_is_registered->content );

isnt(
    $confirm_marvin_is_registered_json->{data}->{users}
      ->{'marvin@megashops.com'},
    undef, 'Marvin has been registered'
);

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

my $superadmin_failed_non_existent_organization = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Daedalus Project token
    Content => encode_json(
        {
            organization_token => 'nonexistentorganization',
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);

is( $superadmin_failed_non_existent_organization->code(), 400, );
#
my $superadmin_failed_non_existent_organization_json =
  decode_json( $superadmin_failed_non_existent_organization->content );

is( $superadmin_failed_non_existent_organization_json->{status}, 0, );
is(
    $superadmin_failed_non_existent_organization_json->{message},
    'Invalid organization token.',
);

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

my $superadmin_get_active_users = request(
    GET "user/showactive",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

my $superadmin_get_active_users_json =
  decode_json( $superadmin_get_active_users->content );

is( $superadmin_get_active_users_json->{status}, 1, );

my $othernotanadmin2_user_token =
  $superadmin_get_active_users_json->{data}->{active_users}
  ->{'othernotanadmin2@daedalus-project.io'}->{token};

my $add_user_success_superuser = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            user_token         => $othernotanadmin2_user_token,
        }
    ),
);

is( $add_user_success_superuser->code(), 200, );
my $add_user_success_superuser_json =
  decode_json( $add_user_success_superuser->content );

is( $add_user_success_superuser_json->{status},  1, );
is( $add_user_success_superuser_json->{message}, 'User has been registered.', );

isnt( $add_user_success_superuser_json->{_hidden_data}, undef, );

done_testing();

DatabaseSetUpTearDown::delete_database();
