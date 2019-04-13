use v5.26;
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

my $endpoint = '/organization/removeorganizationgroup';

my $failed_because_no_tokens =
  request( DELETE $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_tokens->code(), 404, );

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

my $get_megashops_sysadmins_group_token = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $get_megashops_sysadmins_group_token->code(), 200, );

my $get_megashops_sysadmins_group_token_json =
  decode_json( $get_megashops_sysadmins_group_token->content );

is( $get_megashops_sysadmins_group_token_json->{status}, 1, 'Status success.' );

my $megashops_sysadmins_group_token =
  $get_megashops_sysadmins_group_token_json->{data}->{groups}
  ->{'Mega Shop Sysadmins'}->{token};

# group -> Mega Shop Sysadmins

my $failed_no_admin = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 400, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'Invalid organization token.', );

# populate SuperShops groups

my $show_organizations = request(
    GET '/organization/show',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $show_organizations->code(), 200, );

my $show_organizations_json = decode_json( $show_organizations->content );

is( $show_organizations_json->{status}, 1, 'Status success.' );
is( keys %{ $show_organizations_json->{data}->{organizations} },
    2, 'This user belongs to Mega Shops and Supershops' );

my $supershops_token =
  $show_organizations_json->{data}->{organizations}->{'Supershops'}->{token};

my $failed_no_data = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_no_data->code(), 404, );

my $failed_no_group_data = request(
    DELETE "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_no_group_data->code(), 404, );

my $failed_invalid_organization_data = request(
    DELETE "$endpoint/ivalidorganizationtoken/nonexistentgrouptoken",
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

my $failed_group_not_found = request(
    DELETE "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/nonexistentgrouptoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_group_not_found->code(), 400, );

my $failed_group_not_found_json =
  decode_json( $failed_group_not_found->content );

is( $failed_group_not_found_json->{status}, 0, );
is( $failed_group_not_found_json->{message},
    'Required group does not exist.', );

my $remove_group_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
);

is( $remove_group_success->code(), 200, );

my $remove_group_success_json = decode_json( $remove_group_success->content );

is( $remove_group_success_json->{status}, 1, );
is(
    $remove_group_success_json->{message},
    'Selected group has been removed from organization.',
);

is( $remove_group_success_json->{_hidden_data}, undef, );

my $failed_already_removed = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
);

is( $failed_already_removed->code(), 400, );

my $failed_already_removed_json =
  decode_json( $failed_already_removed->content );

is( $failed_already_removed_json->{status}, 0, );
is( $failed_already_removed_json->{message},
    'Required group does not exist.', );

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
    2, 'This response contains two groups' );

isnt( $admin_user_mega_shop_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

is(
    $admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shop Sysadmins'},
    undef, 'Now, Mega Shop Sysadmins does notexist.'
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

my $failed_not_your_organization = request(
    DELETE
"$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO/$daedalus_project_sysadmins_group_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Daedalus Core token
);

is( $failed_not_your_organization->code(), 400, );

my $failed_not_your_organization_json =
  decode_json( $failed_not_your_organization->content );

is( $failed_not_your_organization_json->{status}, 0, );
is(
    $failed_not_your_organization_json->{message},
    'Invalid organization token.',
);

my $failed_not_your_group = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$daedalus_project_sysadmins_group_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
);

is( $failed_not_your_group->code(), 400, );

my $failed_not_your_group_json = decode_json( $failed_not_your_group->content );

is( $failed_not_your_group_json->{status},  0, );
is( $failed_not_your_group_json->{message}, 'Required group does not exist.', );

my $superadmin_remove_group_success = request(
    DELETE
"$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO/$daedalus_project_sysadmins_group_token",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
);

is( $superadmin_remove_group_success->code(), 200, );

my $superadmin_remove_group_success_json =
  decode_json( $superadmin_remove_group_success->content );

is( $superadmin_remove_group_success_json->{status}, 1, );
is(
    $superadmin_remove_group_success_json->{message},
    'Selected group has been removed from organization.',
);

isnt( $superadmin_remove_group_success_json->{_hidden_data}, undef, );

$admin_user_mega_shop_groups = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_groups->code(), 200, );

$admin_user_mega_shop_groups_json =
  decode_json( $admin_user_mega_shop_groups->content );

my $megashops_supersysadmins_group_token =
  $admin_user_mega_shop_groups_json->{data}->{groups}
  ->{'Mega Shop SuperSysadmins'}->{token};

isnt( $megashops_supersysadmins_group_token, undef );

my $superadmin_remove_group_other_organization_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_supersysadmins_group_token",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
);

is( $superadmin_remove_group_other_organization_success->code(), 200, );

my $superadmin_remove_group_other_organization_success_json =
  decode_json( $superadmin_remove_group_other_organization_success->content );

is( $superadmin_remove_group_other_organization_success_json->{status}, 1, );
is(
    $superadmin_remove_group_other_organization_success_json->{message},
    'Selected group has been removed from organization.',
);

isnt( $superadmin_remove_group_other_organization_success_json->{_hidden_data},
    undef, );

my $check_supersysadmins_does_not_exists = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $check_supersysadmins_does_not_exists->code(), 200, );

my $check_supersysadmins_does_not_exists_json =
  decode_json( $check_supersysadmins_does_not_exists->content );

is( $check_supersysadmins_does_not_exists_json->{status}, 1,
    'Status success.' );

is(
    $check_supersysadmins_does_not_exists_json->{data}->{groups}
      ->{'Mega Shop SuperSysadmins'},
    undef, 'Mega Shop SuperSysadmins does not exists'
);

my $failed_unique_admin = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
);

is( $failed_unique_admin->code(), 400, );

my $failed_unique_admin_json = decode_json( $failed_unique_admin->content );

is( $failed_unique_admin_json->{status}, 0, );
is(
    $failed_unique_admin_json->{message},
'Cannot remove this group, no more admin users will left in this organization.',
);

my $superadmin_remove_unique_admin_group_other_organization_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
);

is( $superadmin_remove_unique_admin_group_other_organization_success->code(),
    200, );

my $superadmin_remove_unique_admin_group_other_organization_success_json =
  decode_json(
    $superadmin_remove_unique_admin_group_other_organization_success->content );

is(
    $superadmin_remove_unique_admin_group_other_organization_success_json
      ->{status},
    1,
);
is(
    $superadmin_remove_unique_admin_group_other_organization_success_json
      ->{message},
    'Selected group has been removed from organization.',
);

isnt( $superadmin_remove_group_other_organization_success_json->{_hidden_data},
    undef, );

my $failed_no_admin_users_left = request(
    POST '/organization/addusertogroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
            user_email         => 'marvin@megashops.com'
        }
    ),
);

is( $failed_no_admin_users_left->code(), 403, );

my $failed_no_admin_users_left_json =
  decode_json( $failed_no_admin_users_left->content );

is( $failed_no_admin_users_left_json->{status}, 0, );
is(
    $failed_no_admin_users_left_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

my $add_new_admin_group = request(
    POST '/organization/creategroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",   #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Admins',
        }
    ),
);

is( $add_new_admin_group->code(), 200, );

my $add_new_admin_group_json = decode_json( $add_new_admin_group->content );

is( $add_new_admin_group_json->{status}, 1, );
is(
    $add_new_admin_group_json->{message},
    'Organization group has been created.',
);

my $megashops_admins_group_token =
  $add_new_admin_group_json->{data}->{organization_groups}->{group_token};

my $add_role_to_group_success = request(
    POST '/organization/addroletogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_admins_group_token,
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

isnt( $add_role_to_group_success_json->{_hidden_data}, undef, );

my $add_user_to_group_success = request(
    POST '/organization/addusertogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_admins_group_token,
            user_token         => 'RjZEmVuvbUn9SGc26QQogs9ZaYyQwI9s'
            ,    # otheradminagain@megashops.com
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

my $add_other_user_to_group_success = request(
    POST '/organization/addusertogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_admins_group_token,
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);

is( $add_other_user_to_group_success->code(), 200, );

my $add_other_user_to_group_success_json =
  decode_json( $add_other_user_to_group_success->content );

is( $add_other_user_to_group_success_json->{status}, 1, );
is(
    $add_other_user_to_group_success_json->{message},
    'Required user has been added to organization group.',
);

my $recreate_original_admin_group = request(
    POST '/organization/creategroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
        }
    ),
);

is( $recreate_original_admin_group->code(), 200, );

my $recreate_original_admin_group_json =
  decode_json( $recreate_original_admin_group->content );

is( $recreate_original_admin_group_json->{status}, 1, );
is(
    $recreate_original_admin_group_json->{message},
    'Organization group has been created.',
);

my $megashops_administrators_group_token =
  $recreate_original_admin_group_json->{data}->{organization_groups}
  ->{group_token};

my $add_role_to_original_group_success = request(
    POST '/organization/addroletogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_administrators_group_token,
            role_name          => 'organization_master'
        }
    ),
);

is( $add_role_to_original_group_success->code(), 200, );

my $add_role_to_original_group_success_json =
  decode_json( $add_role_to_original_group_success->content );

is( $add_role_to_original_group_success_json->{status}, 1, );
is(
    $add_role_to_original_group_success_json->{message},
    'Selected role has been added to organization group.',
);

is( $add_role_to_original_group_success_json->{_hidden_data}, undef, );

my $add_original_admin_user_to_original_group_success = request(
    POST '/organization/addusertogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_administrators_group_token,
            user_token         => 'RjZEmVuvbUn9SGc26QQogs9ZaYyQwI9s'
            ,                                # otheradminagain@megashops.com
        }
    ),
);

is( $add_original_admin_user_to_original_group_success->code(), 200, );

my $add_original_admin_user_to_original_group_success_json =
  decode_json( $add_original_admin_user_to_original_group_success->content );

is( $add_original_admin_user_to_original_group_success_json->{status}, 1, );
is(
    $add_original_admin_user_to_original_group_success_json->{message},
    'Required user has been added to organization group.',
);

#Now marvin destroys all

my $marvin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'marvin@megashops.com',
            password => '1_HAT3_MY_L1F3',
        }
    )
);

is( $marvin_success->code(), 200, );

my $marvin_success_json = decode_json( $marvin_success->content );

is( $marvin_success_json->{status}, 1, );

my $marvin_session_token = $marvin_success_json->{data}->{session_token};

my $marvin_authorization_basic =
  MIME::Base64::encode( "session_token:$marvin_session_token", '' );

my $marvin_removes_group_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_admins_group_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $marvin_authorization_basic",
);

is( $marvin_removes_group_success->code(), 200, );

my $marvin_removes_group_success_json =
  decode_json( $marvin_removes_group_success->content );

is( $marvin_removes_group_success_json->{status}, 1, );
is(
    $marvin_removes_group_success_json->{message},
    'Selected group has been removed from organization.',
);

is( $marvin_removes_group_success_json->{_hidden_data}, undef, );

my $marvin_is_not_admin = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_admins_group_token",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $marvin_authorization_basic",    #Megashops Project token
);

is( $marvin_is_not_admin->code(), 403, );

my $marvin_is_not_admin_json = decode_json( $marvin_is_not_admin->content );

is( $marvin_is_not_admin_json->{status}, 0, );
is(
    $marvin_is_not_admin_json->{message},
'Your organization roles does not match with the following roles: organization master.',
);

done_testing();

DatabaseSetUpTearDown::delete_database();
