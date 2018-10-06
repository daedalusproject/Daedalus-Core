use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

my $endpoint = '/organization/adduser';

my $failed_because_no_auth_token =
  request( POST $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_auth_token->code(), 403, );

my $failed_because_no_auth_token_json =
  decode_json( $failed_because_no_auth_token->content );

is_deeply(
    $failed_because_no_auth_token_json,
    {
        'status'  => '0',
        'message' => 'No session token provided.',
    }
);

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

my $not_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$not_admin_session_token", '' );

my $failed_no_admin = request(
    POST $endpoint,
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
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            }
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

my $failed_no_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( {} )
);

is( $failed_no_data->code(), 400, );
#
my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status}, 0, );
is(
    $failed_no_data_json->{message},
    'No organization data neither user info provided.',
);

my $failed_no_user_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        { organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf' }
    ),
);

is( $failed_no_user_data->code(), 400, );
#
my $failed_no_user_data_json = decode_json( $failed_no_user_data->content );

is( $failed_no_user_data_json->{status},  0, );
is( $failed_no_user_data_json->{message}, 'No user e-mail provided.', );

my $failed_no_organization_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { user_email => 'someemail' } ),
);

is( $failed_no_organization_data->code(), 400, );
#
my $failed_no_organization_data_json =
  decode_json( $failed_no_organization_data->content );

is( $failed_no_organization_data_json->{status}, 0, );
is(
    $failed_no_organization_data_json->{message},
    'Invalid Organization token. User e-mail invalid.',
);

my $failed_invalid_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            user_email         => 'invalidemail'
        }
    ),
);

is( $failed_invalid_data->code(), 400, );
#
my $failed_invalid_data_json = decode_json( $failed_invalid_data->content );

is( $failed_invalid_data_json->{status}, 0, );
is(
    $failed_invalid_data_json->{message},
    'Invalid Organization token. User e-mail invalid.',
);

my $failed_invalid_organization_data_email_not_found = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            user_email         => 'notexistent@user.com'
        }
    ),
);

is( $failed_invalid_organization_data_email_not_found->code(), 400, );
#
my $failed_invalid_organization_data_email_not_found_json =
  decode_json( $failed_invalid_organization_data_email_not_found->content );

is( $failed_invalid_organization_data_email_not_found_json->{status}, 0, );
is(
    $failed_invalid_organization_data_email_not_found_json->{message},
'Invalid Organization token. There is not registered user with that e-mail address.',
);

my $failed_invalid_email = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_email         => 'invalidemail.com'
        }
    ),
);

is( $failed_invalid_email->code(), 400, );
#
my $failed_invalid_email_json = decode_json( $failed_invalid_email->content );

is( $failed_invalid_email_json->{status},  0, );
is( $failed_invalid_email_json->{message}, 'User e-mail invalid.', );

my $failed_email_not_found = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_email         => 'invalidemail.com'
        }
    ),
);

is( $failed_email_not_found->code(), 400, );
#
my $failed_email_not_found_json =
  decode_json( $failed_email_not_found->content );

is( $failed_email_not_found_json->{status},  0, );
is( $failed_email_not_found_json->{message}, 'User e-mail invalid.', );

my $failed_inactive_user = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_email         => 'shirorobot@megashops.com'
        }
    ),
);

is( $failed_inactive_user->code(), 400, );
#
my $failed_inactive_user_json = decode_json( $failed_inactive_user->content );

is( $failed_inactive_user_json->{status},  0, );
is( $failed_inactive_user_json->{message}, 'Required user is not active.', );

my $failed_not_my_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic", #Daedalus Project token
    Content       => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            user_email         => 'marvin@megashops.com'
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
    'Invalid Organization token.',
);

my $add_user_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_email         => 'marvin@megashops.com'
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
            user_email         => 'marvin@megashops.com'
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
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            }
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

my $add_user_success_superuser = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            user_email         => 'othernotanadmin2@daedalus-project.io',
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
