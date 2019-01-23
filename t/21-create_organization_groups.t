use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

my $endpoint = '/organization/creategroup';

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

my $failed_no_organization_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_organization_token->code(), 400, );

my $failed_no_organization_token_json =
  decode_json( $failed_no_organization_token->content );

is( $failed_no_organization_token_json->{status}, 0, );
is(
    $failed_no_organization_token_json->{message},
    'No organization_token provided.',
);

my $failed_no_admin = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
        }
    )
);

is( $failed_no_admin->code(), 400, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, );
is(
    $failed_no_admin_json->{message},
    'Invalid organization token.',
    "Actually your aer not and admin user but API is not going to tell you."
);

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

is( $failed_no_data_json->{status},  0, );
is( $failed_no_data_json->{message}, 'No organization_token provided.', );

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
is( $failed_no_group_data_json->{message}, 'No group_name provided.', );

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
    'No organization_token provided.',
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
    'Invalid organization token.',
);

my $create_group_success = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins'
        }
    ),
);

is( $create_group_success->code(), 200, );

my $create_group_success_json = decode_json( $create_group_success->content );

is( $create_group_success_json->{status}, 1, );
is(
    $create_group_success_json->{message},
    'Organization group has been created.',
);

is( $create_group_success_json->{_hidden_data}, undef, );

isnt( $create_group_success_json->{data}, undef, );
is(
    $create_group_success_json->{data}->{organization_groups}->{group_name},
    'Mega Shop Sysadmins',
);
isnt( $create_group_success_json->{data}->{organization_groups}->{group_token},
    undef, );

my $failed_already_created = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins'
        }
    ),
);

is( $failed_already_created->code(), 400, );

my $failed_already_created_json =
  decode_json( $failed_already_created->content );

is( $failed_already_created_json->{status},  0, );
is( $failed_already_created_json->{message}, 'Duplicated group name.', );

# Check group

my $admin_user_mega_shop_groups = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_groups->code(), 200, );

my $admin_user_mega_shop_groups_json =
  decode_json( $admin_user_mega_shop_groups->content );

is( $admin_user_mega_shop_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $admin_user_mega_shop_groups_json->{data}->{groups} },
    2, 'This response contains two group' );

isnt( $admin_user_mega_shop_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

isnt(
    $admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shop Sysadmins'},
    undef, 'Now, Mega Shop Sysadmins exists'
);

isnt(
    $admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shop Sysadmins'}->{token},
    undef, 'Mega Shop Sysadmins has a token'
);

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{groups}
          ->{'Mega Shop Sysadmins'}->{roles}
    },
    0,
    'For the time being Mega Shop Sysadmins has no roles'
);

my $failed_not_your_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',    #Dadeadlus Project token
            group_name => 'Daedalus Project Sysadmins'
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

my $superadmin_create_group_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            group_name         => 'Daedalus Core Sysadmins'
        }
    ),
);

is( $superadmin_create_group_success->code(), 200, );

my $superadmin_create_group_success_json =
  decode_json( $superadmin_create_group_success->content );

is( $superadmin_create_group_success_json->{status}, 1, );
is(
    $superadmin_create_group_success_json->{message},
    'Organization group has been created.',
);

isnt( $superadmin_create_group_success_json->{_hidden_data}, undef, );

isnt( $superadmin_create_group_success_json->{data}, undef, );
is(
    $superadmin_create_group_success_json->{data}->{organization_groups}
      ->{group_name},
    'Daedalus Core Sysadmins',
);
isnt(
    $superadmin_create_group_success_json->{data}->{organization_groups}
      ->{group_token},
    undef,
);

my $superadmin_create_group_other_organization_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop SuperSysadmins'
        }
    ),
);

is( $superadmin_create_group_other_organization_success->code(), 200, );

my $superadmin_create_group_other_organization_success_json =
  decode_json( $superadmin_create_group_other_organization_success->content );

is( $superadmin_create_group_other_organization_success_json->{status}, 1, );
is(
    $superadmin_create_group_other_organization_success_json->{message},
    'Organization group has been created.',
);

isnt( $superadmin_create_group_other_organization_success_json->{_hidden_data},
    undef, );

isnt( $superadmin_create_group_other_organization_success_json->{data}, undef,
);
is(
    $superadmin_create_group_other_organization_success_json->{data}
      ->{organization_groups}->{group_name},
    'Mega Shop SuperSysadmins',
);
isnt(
    $superadmin_create_group_other_organization_success_json->{data}
      ->{organization_groups}->{group_token},
    undef,
);

my $admin_user_mega_shop_three_groups = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_three_groups->code(), 200, );

my $admin_user_mega_shop_three_groups_json =
  decode_json( $admin_user_mega_shop_three_groups->content );

is( $admin_user_mega_shop_three_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $admin_user_mega_shop_three_groups_json->{data}->{groups} },
    3, 'This response contains three groups' );

isnt( $admin_user_mega_shop_three_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

isnt(
    $admin_user_mega_shop_three_groups_json->{data}->{groups}
      ->{'Mega Shop SuperSysadmins'},
    undef, 'Now, Mega Shop SuperSysadmins exists'
);

isnt(
    $admin_user_mega_shop_three_groups_json->{data}->{groups}
      ->{'Mega Shop SuperSysadmins'}->{token},
    undef, 'Mega Shop SuperSysadmins has a token'
);

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{groups}
          ->{'Mega Shop SuperSysadmins'}->{roles}
    },
    0,
    'For the time being Mega Shop SuperSysadmins has no roles'
);

# Check groups

done_testing();
