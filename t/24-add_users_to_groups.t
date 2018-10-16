use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

my $endpoint = '/organization/addusertogroup';

my $failed_because_no_auth_token =
  request( POST $endpoint, Content_Type => 'application/json', );

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
'No group_name provided. No organization_token provided. No user_email provided.',
);

my $failed_no_group_data_no_user = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        { organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf' }
    ),
);

is( $failed_no_group_data_no_user->code(), 400, );
#
my $failed_no_group_data_no_user_json =
  decode_json( $failed_no_group_data_no_user->content );

is( $failed_no_group_data_no_user_json->{status}, 0, );
is(
    $failed_no_group_data_no_user_json->{message},
    'No group_name provided. No user_email provided.',
);

my $failed_no_organization_data_no_user = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { group_name => 'Some Group Name' } ),
);

is( $failed_no_organization_data_no_user->code(), 400, );
#
my $failed_no_organization_data_no_user_json =
  decode_json( $failed_no_organization_data_no_user->content );

is( $failed_no_organization_data_no_user_json->{status}, 0, );
is(
    $failed_no_organization_data_no_user_json->{message},
    'No organization_token provided. No user_email provided.',
);

my $failed_no_organization_data_no_group_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content => encode_json( { user_email => 'nonexistentuser@megashops.com' } ),
);

is( $failed_no_organization_data_no_group_data->code(), 400, );
#
my $failed_no_organization_data_no_group_data_json =
  decode_json( $failed_no_organization_data_no_group_data->content );

is( $failed_no_organization_data_no_group_data_json->{status}, 0, );
is(
    $failed_no_organization_data_no_group_data_json->{message},
    'No group_name provided. No organization_token provided.',
);

my $failed_no_organization_data_no_role_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_email         => 'nonexistentuser@megashops.com'
        }
    ),
);

is( $failed_no_organization_data_no_role_data->code(), 400, );

my $failed_no_organization_data_no_role_data_json =
  decode_json( $failed_no_organization_data_no_role_data->content );

is( $failed_no_organization_data_no_role_data_json->{status}, 0, );
is(
    $failed_no_organization_data_no_role_data_json->{message},
    'No group_name provided.',
);

my $failed_invalid_organization_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_name         => 'non existen group',
            user_email         => 'nonexistentuser@megashops.com'
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

my $failed_invalid_group_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_name         => 'non existen group',
            user_email => 'nonexistentuser@megashops.com'   # There is no clowns
        }
    ),
);

is( $failed_invalid_group_data->code(), 400, );

my $failed_invalid_group_data_json =
  decode_json( $failed_invalid_group_data->content );

is( $failed_invalid_group_data_json->{status}, 0, );
is( $failed_invalid_group_data_json->{message},
    'Invalid Organization token.', );

my $failed_group_not_found = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Clowns',
            user_email         => 'nonexistentuser@megashops.com'
        }
    ),
);

is( $failed_group_not_found->code(), 400, );

my $failed_group_not_found_json =
  decode_json( $failed_group_not_found->content );

is( $failed_group_not_found_json->{status}, 0, );
is( $failed_group_not_found_json->{message},
    'Required group does not exist.', );

my $failed_user_not_found = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
            user_email         => 'nonexistentuser@megashops.com'
        }
    ),
);

is( $failed_user_not_found->code(), 400, );

my $failed_user_not_found_json = decode_json( $failed_user_not_found->content );

is( $failed_user_not_found_json->{status},  0, );
is( $failed_user_not_found_json->{message}, 'Invalid user.', );

my $add_user_to_group_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
            user_email         => 'marvin@megashops.com'
        }
    ),
);

is( $add_user_to_group_success->code(), 200, );

my $add_user_to_group_success_json =
  decode_json( $add_user_to_group_success->content );

is( $add_user_to_group_success_json->{status}, 1, );
is(
    $add_user_to_group_success_json->{message},
    'Required user has been added to organization group.',
);

is( $add_user_to_group_success_json->{_hidden_data}, undef, );

my $failed_already_added = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
            user_email         => 'marvin@megashops.com'
        }
    ),
);

is( $failed_already_added->code(), 400, );

my $failed_already_added_json = decode_json( $failed_already_added->content );

is( $failed_already_added_json->{status}, 0, );
is(
    $failed_already_added_json->{message},
    'Required user is already assigned to this group.',
);

# Check group

my $admin_user_mega_shop_groups = request(
    GET "/organization/showoallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_groups->code(), 200, );

my $admin_user_mega_shop_groups_json =
  decode_json( $admin_user_mega_shop_groups->content );

is( $admin_user_mega_shop_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $admin_user_mega_shop_groups_json->{data}->{groups} },
    3, 'This response contains three groups' );

isnt( $admin_user_mega_shop_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

isnt(
    $admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shop Sysadmins'},
    undef, 'Now, Mega Shop Sysadmins exists'
);

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{groups}
          ->{'Mega Shop Sysadmins'}->{users}
    },
    1,
'For the time being Mega Shop Sysadmins group has marvin@megashops.com as user.'
);

my $failed_not_your_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',    #Dadeadlus Project token
            group_name => 'Daedalus Project Sysadmins',
            user_email => 'marvin@megashops.com'
        }
    ),
);

is( $failed_not_your_organization->code(), 400, );

my $failed_not_your_organization_json =
  decode_json( $failed_not_your_organization->content );

is( $failed_not_your_organization_json->{status}, 0, );
is(
    $failed_not_your_organization_json->{message},
    'Invalid organization token.',
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

my $superadmin_add_user_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            group_name         => 'Daedalus Core Sysadmins',
            user_email         => 'notanadmin@daedalus-project.io'
        }
    ),
);

is( $superadmin_add_user_success->code(), 200, );

my $superadmin_add_user_success_json =
  decode_json( $superadmin_add_user_success->content );

is( $superadmin_add_user_success_json->{status}, 1, );
is(
    $superadmin_add_user_success_json->{message},
    'Required user has been added to organization group.',
);

isnt( $superadmin_add_user_success_json->{_hidden_data}, undef, );

my $superadmin_add_inactive_user = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop Sysadmins',
            user_email => 'shirorobot@megashops.com'
        }
    ),
);

is( $superadmin_add_inactive_user->code(), 400, );

my $superadmin_add_inactive_user_json =
  decode_json( $superadmin_add_inactive_user->content );

is( $superadmin_add_inactive_user_json->{status},  0, );
is( $superadmin_add_inactive_user_json->{message}, 'Invalid user.', );

my $superadmin_add_user_from_other_organization = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop Sysadmins',
            user_email => 'othernotanadmin@daedalus-project.io'
        }
    ),
);

is( $superadmin_add_user_from_other_organization->code(), 400, );

my $superadmin_add_user_from_other_organization_json =
  decode_json( $superadmin_add_user_from_other_organization->content );

is( $superadmin_add_user_from_other_organization_json->{status}, 0, );
is(
    $superadmin_add_user_from_other_organization_json->{message},
    'Invalid user.',
);

my $superadmin_add_user_other_organization_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop Sysadmins',
            user_email => 'noadmin@megashops.com'
        }
    ),
);

is( $superadmin_add_user_other_organization_success->code(), 200, );

my $superadmin_add_user_other_organization_success_json =
  decode_json( $superadmin_add_user_other_organization_success->content );

is( $superadmin_add_user_other_organization_success_json->{status}, 1, );
is(
    $superadmin_add_user_other_organization_success_json->{message},
    'Required user has been added to organization group.',
);

isnt( $superadmin_add_user_other_organization_success_json->{_hidden_data},
    undef, );

my $admin_user_mega_shop_two_roles = request(
    GET "/organization/showoallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_two_roles->code(), 200, );

my $admin_user_mega_shop_two_roles_json =
  decode_json( $admin_user_mega_shop_two_roles->content );

is( $admin_user_mega_shop_two_roles_json->{status}, 1, 'Status success.' );

is(
    scalar @{
        $admin_user_mega_shop_two_roles_json->{data}->{groups}
          ->{'Mega Shop Sysadmins'}->{users}
    },
    2,
    'Mega Shop Sysadmins has two users'
);

done_testing();
