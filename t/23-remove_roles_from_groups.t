use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

my $endpoint = '/organization/removerolegroup';

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

my $failed_no_admin = request(
    DELETE $endpoint,
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
    DELETE $endpoint,
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
'No group_name provided. No organization_token provided. No role_name provided.',
);

my $failed_no_group_data_no_role = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        { organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf' }
    ),
);

is( $failed_no_group_data_no_role->code(), 400, );
#
my $failed_no_group_data_no_role_json =
  decode_json( $failed_no_group_data_no_role->content );

is( $failed_no_group_data_no_role_json->{status}, 0, );
is(
    $failed_no_group_data_no_role_json->{message},
    'No group_name provided. No role_name provided.',
);

my $failed_no_organization_data_no_role = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { group_name => 'Some Group Name' } ),
);

is( $failed_no_organization_data_no_role->code(), 400, );
#
my $failed_no_organization_data_no_role_json =
  decode_json( $failed_no_organization_data_no_role->content );

is( $failed_no_organization_data_no_role_json->{status}, 0, );
is(
    $failed_no_organization_data_no_role_json->{message},
    'No organization_token provided. No role_name provided.',
);

my $failed_no_organization_data_no_group_data = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { role_name => 'fireman' } ),
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            role_name          => 'fireman'
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_name         => 'non existen group',
            role_name          => 'clowns'                  # There is no clowns
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_name         => 'non existen group',
            role_name          => 'clowns'                  # There is no clowns
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Clowns',
            role_name          => 'clown'
        }
    ),
);

is( $failed_group_not_found->code(), 400, );

my $failed_group_not_found_json =
  decode_json( $failed_group_not_found->content );

is( $failed_group_not_found_json->{status}, 0, );
is( $failed_group_not_found_json->{message},
    'Required group does not exist.', );

my $failed_role_not_found = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
            role_name          => 'clown'
        }
    ),
);

is( $failed_role_not_found->code(), 400, );

my $failed_role_not_found_json = decode_json( $failed_role_not_found->content );

is( $failed_role_not_found_json->{status},  0, );
is( $failed_role_not_found_json->{message}, 'Required role does not exist.', );

my $remove_role_from_group_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
            role_name          => 'fireman'
        }
    ),
);

is( $remove_role_from_group_success->code(), 200, );

my $remove_role_from_group_success_json =
  decode_json( $remove_role_from_group_success->content );

is( $remove_role_from_group_success_json->{status}, 1, );
is(
    $remove_role_from_group_success_json->{message},
    'Selected role has been removed from organization group.',
);

is( $remove_role_from_group_success_json->{_hidden_data}, undef, );

my $failed_already_removed = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
            role_name          => 'fireman'
        }
    ),
);

is( $failed_already_removed->code(), 400, );

my $failed_already_removed_json =
  decode_json( $failed_already_removed->content );

is( $failed_already_removed_json->{status}, 0, );
is(
    $failed_already_removed_json->{message},
    'Required role is not assigned to this group.',
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

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{groups}
          ->{'Mega Shops Administrators'}->{roles}
    },
    1,
'Mega Shops Administrators has only organization_manager as role, fireman has been removed'
);

my $failed_not_your_organization = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',    #Dadeadlus Project token
            group_name => 'Daedalus Project Sysadmins',
            role_name  => 'fireman'
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

my $superadmin_remove_role_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            group_name         => 'Daedalus Core Sysadmins',
            role_name          => 'fireman'
        }
    ),
);

is( $superadmin_remove_role_success->code(), 200, );

my $superadmin_remove_role_success_json =
  decode_json( $superadmin_remove_role_success->content );

is( $superadmin_remove_role_success_json->{status}, 1, );
is(
    $superadmin_remove_role_success_json->{message},
    'Selected role has been removed from organization group.',
);

isnt( $superadmin_remove_role_success_json->{_hidden_data}, undef, );

my $superadmin_remove_role_other_organization_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop Sysadmins',
            role_name  => 'fireman'
        }
    ),
);

is( $superadmin_remove_role_other_organization_success->code(), 200, );

my $superadmin_remove_role_other_organization_success_json =
  decode_json( $superadmin_remove_role_other_organization_success->content );

is( $superadmin_remove_role_other_organization_success_json->{status}, 1, );
is(
    $superadmin_remove_role_other_organization_success_json->{message},
    'Selected role has been removed from organization group.',
);

isnt( $superadmin_remove_role_other_organization_success_json->{_hidden_data},
    undef, );

my $admin_user_mega_shop_one_role = request(
    GET "/organization/showoallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_one_role->code(), 200, );

my $admin_user_mega_shop_one_role_json =
  decode_json( $admin_user_mega_shop_one_role->content );

is( $admin_user_mega_shop_one_role_json->{status}, 1, 'Status success.' );

is(
    scalar @{
        $admin_user_mega_shop_one_role_json->{data}->{groups}
          ->{'Mega Shop Sysadmins'}->{roles}
    },
    1,
    'Mega Shop Sysadmins has only health_watcher role'
);

my $superadmin_remove_role_health_watcher_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop Sysadmins',
            role_name  => 'health_watcher'
        }
    ),
);

is( $superadmin_remove_role_health_watcher_success->code(), 200, );

my $superadmin_remove_role_health_watcher_success_json =
  decode_json( $superadmin_remove_role_health_watcher_success->content );

is( $superadmin_remove_role_health_watcher_success_json->{status}, 1, );
is(
    $superadmin_remove_role_health_watcher_success_json->{message},
    'Selected role has been removed from organization group.',
);

isnt( $superadmin_remove_role_health_watcher_success_json->{_hidden_data},
    undef, );

my $admin_user_mega_shop_zero_roles = request(
    GET "/organization/showoallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_zero_roles->code(), 200, );

my $admin_user_mega_shop_zero_roles_json =
  decode_json( $admin_user_mega_shop_zero_roles->content );

is( $admin_user_mega_shop_zero_roles_json->{status}, 1, 'Status success.' );

is(
    scalar @{
        $admin_user_mega_shop_zero_roles_json->{data}->{groups}
          ->{'Mega Shop Sysadmins'}->{roles}
    },
    0,
    'Mega Shop Sysadmins has no roles'
);

my $add_role_to_group_success = request(
    POST '/organization/addrolegroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
            role_name          => 'organization_master'
        }
    ),
);

is( $add_role_to_group_success->code(), 200, );

my $add_role_to_group_success_json =
  decode_json( $add_role_to_group_success->content );

is( $add_role_to_group_success_json->{status}, 1, );
is(
    $add_role_to_group_success_json->{message},
    'Selected role has been added to organization group.',
);

is( $add_role_to_group_success_json->{_hidden_data}, undef, );

my $add_other_admin_role_to_group_success = request(
    POST '/organization/addrolegroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop SuperSysadmins',
            role_name          => 'organization_master'
        }
    ),
);

is( $add_other_admin_role_to_group_success->code(), 200, );

my $add_other_admin_role_to_group_success_json =
  decode_json( $add_other_admin_role_to_group_success->content );

is( $add_other_admin_role_to_group_success_json->{status}, 1, );
is(
    $add_other_admin_role_to_group_success_json->{message},
    'Selected role has been added to organization group.',
);

is( $add_other_admin_role_to_group_success_json->{_hidden_data}, undef, );

my $remove_other_admin_role_to_group_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop SuperSysadmins',
            role_name          => 'organization_master'
        }
    ),
);

is( $remove_other_admin_role_to_group_success->code(), 200, );

my $remove_other_admin_role_to_group_success_json =
  decode_json( $add_other_admin_role_to_group_success->content );

is( $remove_other_admin_role_to_group_success_json->{status}, 1, );
is(
    $remove_other_admin_role_to_group_success_json->{message},
    'Selected role has been added to organization group.',
);

is( $remove_other_admin_role_to_group_success_json->{_hidden_data}, undef, );

my $superadmin_remove_role_organization_master_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop Sysadmins',
            role_name  => 'organization_master'
        }
    ),
);

is( $superadmin_remove_role_organization_master_success->code(), 200, );

my $superadmin_remove_role_organization_master_success_json =
  decode_json( $superadmin_remove_role_organization_master_success->content );

is( $superadmin_remove_role_organization_master_success_json->{status}, 1, );
is(
    $superadmin_remove_role_organization_master_success_json->{message},
    'Selected role has been removed from organization group.',
);

isnt( $superadmin_remove_role_organization_master_success_json->{_hidden_data},
    undef, );

# At this point there is only one group with organization_master
# It can't be removed because Mega Shops won't have any admin users

my $remove_admin_role_from_group_failed = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
            role_name          => 'organization_master'
        }
    ),
);

is( $remove_admin_role_from_group_failed->code(), 400, );

my $remove_admin_role_from_group_failed_json =
  decode_json( $remove_admin_role_from_group_failed->content );

is( $remove_admin_role_from_group_failed_json->{status}, 0, );
is(
    $remove_admin_role_from_group_failed_json->{message},
'Cannot remove this role, no more admin roles will left in this organization.',
);

is( $remove_admin_role_from_group_failed_json->{_hidden_data}, undef, );

my $superadmin_remove_admin_role_from_group_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
            role_name          => 'organization_master'
        }
    ),
);

is( $superadmin_remove_admin_role_from_group_success->code(), 200, );

my $superadmin_remove_admin_role_from_group_success_json =
  decode_json( $superadmin_remove_admin_role_from_group_success->content );

is( $superadmin_remove_admin_role_from_group_success_json->{status}, 1, );
is(
    $superadmin_remove_admin_role_from_group_success_json->{message},
    'Selected role has been removed from organization group.',
    "Super admin users are allowed to do this"
);

isnt( $superadmin_remove_admin_role_from_group_success_json->{_hidden_data},
    undef, );

my $remove_failed_no_admin = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
            role_name          => 'organization_master'
        }
    ),
);

is( $remove_failed_no_admin->code(), 400, );

my $remove_failed_no_admin_json =
  decode_json( $remove_failed_no_admin->content );

is( $remove_failed_no_admin_json->{status}, 0, );
is(
    $remove_failed_no_admin_json->{message},
    'You are not an admin user of this organization.',
);

is( $remove_failed_no_admin_json->{_hidden_data}, undef, );

my $make_admin_again = request(
    POST '/organization/addrolegroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
            role_name          => 'organization_master'
        }
    ),
);

is( $make_admin_again->code(), 200, );

my $make_admin_again_json = decode_json( $make_admin_again->content );

is( $make_admin_again_json->{status}, 1, );
is(
    $make_admin_again_json->{message},
    'Selected role has been added to organization group.',
);

isnt( $make_admin_again_json->{_hidden_data}, undef, );

done_testing();
