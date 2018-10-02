use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

my $endpoint = '/organization/addgroup';

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
    'No organization data neither group info provided.',
);

my $failed_no_group_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        { organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf' }
    ),
);

is( $failed_no_group_data->code(), 400, );
#
my $failed_no_group_data_json = decode_json( $failed_no_group_data->content );

is( $failed_no_group_data_json->{status},  0, );
is( $failed_no_group_data_json->{message}, 'No group name provided.', );

my $failed_no_organization_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { group_name => 'Some Group Name' } ),
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

my $failed_invalid_organization_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_name         => 'Some Group Name'
        }
    ),
);

is( $failed_invalid_organization_data->code(), 400, );

my $failed_invalid_organization_data_json =
  decode_json( $failed_invalid_organization_data->content );

is( $failed_invalid_organization_data_json->{status}, 0, );
is(
    $failed_invalid_organization_data_json->{message},
    'Invalid Organization token.',
);

my $create_group_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins'
        }
    ),
);

is( $add_user_success->code(), 200, );
#
my $add_user_success_json = decode_json( $add_user_success->content );

is( $add_user_success_json->{status},  1, );
is( $add_user_success_json->{message}, 'User group has been created.', );

is( $add_user_success_json->{_hidden_data}, undef, );

my $failed_already_created = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_email         => 'Mega Shop Sysadmins'
        }
    ),
);

is( $failed_already_registered->code(), 400, );

my $failed_already_registered_json =
  decode_json( $failed_already_registered->content );

is( $failed_already_registered_json->{status},  0, );
is( $failed_already_registered_json->{message}, 'Duplicated group name.', );

##### TO DO

done_testing();
