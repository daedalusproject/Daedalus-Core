use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

use Data::Dumper;

my $endpoint = '/organization/removerolefromgroup';

my $failed_because_no_auth_token_neither_data =
  request( DELETE $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_auth_token_neither_data->code(), 404, );

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

my $failed_no_token = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_token->code(), 404, );

my $failed_no_admin = request(
    DELETE "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/invalidtoken/clown",
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
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

my $failed_no_data = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_no_data->code(), 404, );
#
my $failed_no_group_data_no_role = request(
    DELETE "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_no_group_data_no_role->code(), 404, );
#

my $failed_no_organization_data_no_role_data = request(
    DELETE "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/fireman",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_no_organization_data_no_role_data->code(), 404, );

my $failed_invalid_organization_data = request(
    DELETE "$endpoint/ivalidorganizationtoken/non_existen_group/clowns",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_invalid_organization_data->code(), 400, );

my $failed_invalid_organization_data_json =
  decode_json( $failed_invalid_organization_data->content );

is( $failed_invalid_organization_data_json->{status}, 0, );
is(
    $failed_invalid_organization_data_json->{message},
    'Invalid organization token.',
);

my $failed_invalid_group_data = request(
    DELETE "$endpoint/ivalidorganizationtoken/non_existen_group/clowns",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_invalid_group_data->code(), 400, );

my $failed_invalid_group_data_json =
  decode_json( $failed_invalid_group_data->content );

is( $failed_invalid_group_data_json->{status}, 0, );
is( $failed_invalid_group_data_json->{message},
    'Invalid organization token.', );

my $failed_group_not_found = request(
    DELETE
      "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/non_existen_group/clowns",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_group_not_found->code(), 400, );

my $failed_group_not_found_json =
  decode_json( $failed_group_not_found->content );

is( $failed_group_not_found_json->{status}, 0, );
is( $failed_group_not_found_json->{message},
    'Required group does not exist.', );

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

my $superadminadmin_get_megashops_groups = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadminadmin_get_megashops_groups->code(), 200, );

my $superadminadmin_get_megashops_groups_json =
  decode_json( $superadminadmin_get_megashops_groups->content );

is( $superadminadmin_get_megashops_groups_json->{status}, 1,
    'Status success.' );

my $megashops_sysadmins_group_token =
  $superadminadmin_get_megashops_groups_json->{data}->{groups}
  ->{'Mega Shop Sysadmins'}->{token};

my $superadminadmin_get_daedalus_core_groups = request(
    GET "/organization/showallgroups/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO"
    ,    # Daedalus Core Token
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadminadmin_get_daedalus_core_groups->code(), 200, );

my $superadminadmin_get_daedalus_core_groups_json =
  decode_json( $superadminadmin_get_daedalus_core_groups->content );

is( $superadminadmin_get_daedalus_core_groups_json->{status},
    1, 'Status success.' );

my $daedalus_project_sysadmins_group_token =
  $superadminadmin_get_daedalus_core_groups_json->{data}->{groups}
  ->{'Daedalus Core Sysadmins'}->{token};

my $failed_role_not_found = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/clown",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_role_not_found->code(), 400, );

my $failed_role_not_found_json = decode_json( $failed_role_not_found->content );

is( $failed_role_not_found_json->{status},  0, );
is( $failed_role_not_found_json->{message}, 'Required role does not exist.', );

my $remove_role_from_group_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/fireman"
    ,    #ega Shops Administrators
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
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
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/fireman"
    ,    #ega Shops Administrators
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
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
    DELETE
"$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO/$daedalus_project_sysadmins_group_token/fireman",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
);

is( $failed_not_your_organization->code(), 400, );

my $failed_not_your_organization_json =
  decode_json( $failed_not_your_organization->content );

is( $failed_not_your_organization_json->{status}, 0, );
is(
    $failed_not_your_organization_json->{message},
    'Invalid organization token.',
);

my $failed_valid_organization_not_your_group = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$daedalus_project_sysadmins_group_token/fireman",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
);

is( $failed_valid_organization_not_your_group->code(), 400, );

my $failed_valid_organization_not_your_group_json =
  decode_json( $failed_valid_organization_not_your_group->content );

is( $failed_valid_organization_not_your_group_json->{status}, 0, );
is(
    $failed_valid_organization_not_your_group_json->{message},
    'Required group does not exist.',
);

my $failed_invalid_organization_valid_group = request(
    DELETE
"$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO/$megashops_sysadmins_group_token/fireman",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
);

is( $failed_invalid_organization_valid_group->code(), 400, );

my $failed_invalid_organization_valid_group_json =
  decode_json( $failed_invalid_organization_valid_group->content );

is( $failed_invalid_organization_valid_group_json->{status}, 0, );
is(
    $failed_invalid_organization_valid_group_json->{message},
    'Invalid organization token.',
);

my $superadmin_remove_role_success = request(
    DELETE
"$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO/$daedalus_project_sysadmins_group_token/fireman",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
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
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/fireman",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
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
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
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
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/health_watcher",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
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
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
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
    POST '/organization/addroletogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_sysadmins_group_token,
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

my $megashops_supersysadmins_group_token =
  $admin_user_mega_shop_zero_roles_json->{data}->{groups}
  ->{'Mega Shop SuperSysadmins'}->{token};

my $add_other_admin_role_to_group_success = request(
    POST '/organization/addroletogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_supersysadmins_group_token,
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
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_supersysadmins_group_token/organization_master",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
);

is( $remove_other_admin_role_to_group_success->code(), 200, );

my $remove_other_admin_role_to_group_success_json =
  decode_json( $remove_other_admin_role_to_group_success->content );

is( $remove_other_admin_role_to_group_success_json->{status}, 1, );
is(
    $remove_other_admin_role_to_group_success_json->{message},
    'Selected role has been removed from organization group.',
);

is( $remove_other_admin_role_to_group_success_json->{_hidden_data}, undef, );

my $superadmin_remove_role_organization_master_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/organization_master",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
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

# At this point there is only one group with organization_master role
# It can't be removed because Mega Shops won't have any admin users

my $remove_admin_role_from_group_failed = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/organization_master",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Administrators token
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
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/organization_master",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
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
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/organization_master",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
);

is( $remove_failed_no_admin->code(), 403, );

my $remove_failed_no_admin_json =
  decode_json( $remove_failed_no_admin->content );

is( $remove_failed_no_admin_json->{status}, 0, );
is(
    $remove_failed_no_admin_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

is( $remove_failed_no_admin_json->{_hidden_data}, undef, );

my $megashops_administrators_group_token =
  $admin_user_mega_shop_zero_roles_json->{data}->{groups}
  ->{'Mega Shops Administrators'}->{token};

my $make_admin_again = request(
    POST '/organization/addroletogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_administrators_group_token,
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

DatabaseSetUpTearDown::delete_database();
