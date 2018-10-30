use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

my $endpoint = '/organization/removeorganizationgroup';

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

my $failed_no_token = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_token->code(), 400, );

my $failed_no_token_json = decode_json( $failed_no_token->content );

is( $failed_no_token_json->{status},  0, );
is( $failed_no_token_json->{message}, 'No organization_token provided.', );

my $failed_no_admin = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
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
    Content       => encode_json( {} )
);

is( $failed_no_data->code(), 400, );
#
my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status},  0, );
is( $failed_no_data_json->{message}, 'No organization_token provided.', );

my $failed_no_group_data = request(
    DELETE $endpoint,
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            group_name => 'Some nonexistent group',
        }
    ),
);

is( $failed_no_organization_data->code(), 400, );

my $failed_no_organization_data_json =
  decode_json( $failed_no_organization_data->content );

is( $failed_no_organization_data_json->{status}, 0, );
is(
    $failed_no_organization_data_json->{message},
    'No organization_token provided.',
);

my $failed_invalid_organization_data = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_name         => 'non existen group',
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

my $failed_group_not_found = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Clowns',
        }
    ),
);

is( $failed_group_not_found->code(), 400, );

my $failed_group_not_found_json =
  decode_json( $failed_group_not_found->content );

is( $failed_group_not_found_json->{status}, 0, );
is( $failed_group_not_found_json->{message},
    'Required group does not exist.', );

my $remove_group_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
        }
    ),
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
        }
    ),
);

is( $failed_already_removed->code(), 400, );

my $failed_already_removed_json =
  decode_json( $failed_already_removed->content );

is( $failed_already_removed_json->{status}, 0, );
is( $failed_already_removed_json->{message},
    'Required group does not exist.', );

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
    2, 'This response contains two groups' );

isnt( $admin_user_mega_shop_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

is(
    $admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shop Sysadmins'},
    undef, 'Now, Mega Shop Sysadmins does notexist.'
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

my $superadmin_remove_group_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            group_name         => 'Daedalus Core Sysadmins',
        }
    ),
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

my $superadmin_remove_group_other_organization_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shop SuperSysadmins',
        }
    ),
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
    GET "/organization/showoallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
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
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Administrators',
        }
    ),
);

is( $failed_unique_admin->code(), 400, );

my $failed_unique_admin_json = decode_json( $failed_unique_admin->content );

is( $failed_unique_admin_json->{status}, 0, );
is(
    $failed_unique_admin_json->{message},
'Cannot remove this group, no more admin users will left in this organization.',
);

my $superadmin_remove_unique_admin_group_other_organization_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_name => 'Mega Shops Administrators',
        }
    ),
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
    'You are not a organization master of this organization.',
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

my $add_role_to_group_success = request(
    POST '/organization/addrolegroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Admins',
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
            group_name         => 'Mega Shops Admins',
            user_email         => 'otheradminagain@megashops.com'
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
            group_name         => 'Mega Shops Admins',
            user_email         => 'marvin@megashops.com'
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

my $add_role_to_original_group_success = request(
    POST '/organization/addrolegroup',
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
            group_name         => 'Mega Shops Administrators',
            user_email         => 'otheradminagain@megashops.com'
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
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $marvin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shops Admins',
        }
    ),
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
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $marvin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Admins',
        }
    ),
);

is( $marvin_is_not_admin->code(), 403, );

my $marvin_is_not_admin_json = decode_json( $marvin_is_not_admin->content );

is( $marvin_is_not_admin_json->{status}, 0, );
is(
    $marvin_is_not_admin_json->{message},
    'You are not a organization master of this organization.',
);

done_testing();
