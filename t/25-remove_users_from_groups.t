use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

my $endpoint = '/organization/removeuserfromgroup';

my $failed_because_no_auth_token =
  request( DELETE "$endpoint/noorgatoken/nogrouptoken/nousertoken",
    Content_Type => 'application/json', );

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

my $failed_no_token = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_token->code(), 404, );

# organization -> Megashops
# group -> Mega Shops Administrators
# user -> otheradminagain@megashops.com

my $failed_no_admin = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/RjZEmVuvbUn9SGc26QQogs9ZaYyQwI9s",
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 400, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, );
is(
    $failed_no_admin_json->{message},
    'Invalid organization token.',
    'Beacuse you are not an admin user.'
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( {} )
);

is( $failed_no_data->code(), 404, );

my $failed_no_group_data_no_user = request(
    DELETE "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_no_group_data_no_user->code(), 404, );

my $failed_invalid_organization_data = request(
    DELETE
"$endpoint/ivalidorganizationtoken/non_existent_group_token/RjZEmVuvbUn9SGc26QQogs9ZaYyQwI9q",
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
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/non_existent_group_token/RjZEmVuvbUn9SGc26QQogs9ZaYyQwI9q",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_invalid_group_data->code(), 400, );

my $failed_invalid_group_data_json =
  decode_json( $failed_invalid_group_data->content );

is( $failed_invalid_group_data_json->{status},  0, );
is( $failed_invalid_group_data_json->{message}, 'Invalid group token.', );

# User is marvin@megashops.com

my $failed_group_not_found = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/non_existent_group_token/bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_group_not_found->code(), 400, );

my $failed_group_not_found_json =
  decode_json( $failed_group_not_found->content );

is( $failed_group_not_found_json->{status}, 0, );
is( $failed_group_not_found_json->{message},
    'Required group does not exist.', );

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

# organization -> Mega Shops
# Group -> Mega Shop Sysadmins

my $failed_user_not_found = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/qQGzQ4X3BBNiSFvEwBhsQZF47FS0v5Ad",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_user_not_found->code(), 400, );

my $failed_user_not_found_json = decode_json( $failed_user_not_found->content );

is( $failed_user_not_found_json->{status}, 0, );
is(
    $failed_user_not_found_json->{message},
    'There is no registered user with that token.',
);

# User -> marvin@megashops.com

my $remove_user_from_group_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $remove_user_from_group_success->code(), 200, );

my $remove_user_from_group_success_json =
  decode_json( $remove_user_from_group_success->content );

is( $remove_user_from_group_success_json->{status}, 1, );
is(
    $remove_user_from_group_success_json->{message},
    'Required user has been removed from organization group.',
);

is( $remove_user_from_group_success_json->{_hidden_data}, undef, );

my $failed_already_removed = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_already_removed->code(), 400, );

my $failed_already_removed_json =
  decode_json( $failed_already_removed->content );

is( $failed_already_removed_json->{status}, 0, );
is(
    $failed_already_removed_json->{message},
    'Required user does not belong to this group.',
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

isnt( $admin_user_mega_shop_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

isnt(
    $admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shop Sysadmins'},
    undef, 'Mega Shop Sysadmins exists'
);

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{groups}
          ->{'Mega Shop Sysadmins'}->{users}
    },
    1,
'For the time being Mega Shop Sysadmins group has only one user, marvin@megashops.com has been removed.'
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
  ->{'Daedalus Project Sysadmins'}->{token};

# organization -> Daedalus Project
# group -> Daedalus Project Sysadmins
# user -> marvin@megashops.com

my $failed_not_your_organization = request(
    DELETE
"$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO/$daedalus_project_sysadmins_group_token/bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC",
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

my $daedalus_core_sysadmins_group_token =
  $superadminadmin_get_daedalus_core_groups_json->{data}->{groups}
  ->{'Daedalus Core Sysadmins'}->{token};

# organization -> Daedalus Project
# group -> Daedalus Core Sysadmins
# user -> notanadmin@daedalus-project.io

my $superadmin_remove_user_success = request(
    DELETE
"$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO/$daedalus_core_sysadmins_group_token/IXI1VoS8BiIuRrOGS4HEAOBleJVMflfG",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_remove_user_success->code(), 200, );

my $superadmin_remove_user_success_json =
  decode_json( $superadmin_remove_user_success->content );

is( $superadmin_remove_user_success_json->{status}, 1, );
is(
    $superadmin_remove_user_success_json->{message},
    'Required user has been removed from organization group.',
);

isnt( $superadmin_remove_user_success_json->{_hidden_data}, undef, );

# organization -> Megashops
# group -> Mega Shop Sysadmins
# user -> noadmin@megashops.com

my $superadmin_remove_user_other_organization_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_remove_user_other_organization_success->code(), 200, );

my $superadmin_remove_user_other_organization_success_json =
  decode_json( $superadmin_remove_user_other_organization_success->content );

is( $superadmin_remove_user_other_organization_success_json->{status}, 1, );
is(
    $superadmin_remove_user_other_organization_success_json->{message},
    'Required user has been removed from organization group.',
);

isnt( $superadmin_remove_user_other_organization_success_json->{_hidden_data},
    undef, );

my $admin_user_mega_shop_one_user = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
    ,    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_one_user->code(), 200, );

my $admin_user_mega_shop_one_user_json =
  decode_json( $admin_user_mega_shop_one_user->content );

is( $admin_user_mega_shop_one_user_json->{status}, 1, 'Status success.' );

is(
    scalar @{
        $admin_user_mega_shop_one_user_json->{data}->{groups}
          ->{'Mega Shop Sysadmins'}->{users}
    },
    0,
    'Mega Shop Sysadmins has no users'
);

my $failed_remove_removed_user = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/$megashops_sysadmins_group_token/03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
);

is( $failed_remove_removed_user->code(), 400, );

my $failed_remove_removed_user_json =
  decode_json( $failed_remove_removed_user->content );

is( $failed_remove_removed_user_json->{status}, 0, );
is(
    $failed_remove_removed_user_json->{message},
    'Required user does not belong to this group.',
);

# organization -> Mega Shops
# group -> Mega Shops Administrators>
# user -> otheradminagain@megashops.com

my $failed_unique_admin = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/RjZEmVuvbUn9SGc26QQogs9ZaYyQwI9s",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_unique_admin->code(), 400, );

my $failed_unique_admin_json = decode_json( $failed_unique_admin->content );

is( $failed_unique_admin_json->{status}, 0, );
is(
    $failed_unique_admin_json->{message},
'Cannot remove this user, no more admin users will left in this organization.',
);

my $add_new_admin = request(
    POST '/organization/addusertogroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',   # Mega Shops Administrators
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);

is( $add_new_admin->code(), 200, );

my $add_new_admin_json = decode_json( $add_new_admin->content );

is( $add_new_admin_json->{status}, 1, );
is(
    $add_new_admin_json->{message},
    'Required user has been added to organization group.',
);

# organization -> Mega Shops
# group -> Mega Shops Administrators>
# user -> marvin@megashops.com

my $remove_user_from_admin_group_success = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC",
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $remove_user_from_admin_group_success->code(),
    200,
    'If there are more than one admin this user is able to remove itself.' );

my $remove_user_from_admin_group_success_json =
  decode_json( $remove_user_from_admin_group_success->content );

is( $remove_user_from_admin_group_success_json->{status}, 1, );
is(
    $remove_user_from_admin_group_success_json->{message},
    'Required user has been removed from organization group.',
);

is( $remove_user_from_admin_group_success_json->{_hidden_data}, undef, );

# organization -> Mega Shops
# group -> Mega Shops Administrators>
# user -> otheradminagain@megashops.com

my $superadmin_remove_unique_admin = request(
    DELETE
"$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf/EC78R91DADJowsNogz16pHnAcEBiQHWBF/bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_remove_unique_admin->code(), 200, );

my $superadmin_remove_unique_admin_json =
  decode_json( $superadmin_remove_unique_admin->content );

is( $superadmin_remove_unique_admin_json->{status}, 1, );
is(
    $superadmin_remove_unique_admin_json->{message},
    'Required user has been removed from organization group.',
);

my $failed_no_admin_users_left = request(
    POST '/organization/addusertogroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF', # 'Mega Shops Administrators'
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
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

my $add_new_admin_again = request(
    POST '/organization/addusertogroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",   #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF', # 'Mega Shops Administrators'
            user_token => 'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC'
            ,    # otheradminagain@megashops.com
        }
    ),
);

is( $add_new_admin_again->code(), 200, );

my $add_new_admin_again_json = decode_json( $add_new_admin_again->content );

is( $add_new_admin_again_json->{status}, 1, );
is(
    $add_new_admin_again_json->{message},
    'Required user has been added to organization group.',
);

done_testing();
