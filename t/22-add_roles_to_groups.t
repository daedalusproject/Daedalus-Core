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

my $endpoint = '/organization/addroletogroup';

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

my $failed_no_token = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_token->code(), 400, );

my $failed_no_token_json = decode_json( $failed_no_token->content );

is( $failed_no_token_json->{status},  0, );
is( $failed_no_token_json->{message}, 'No organization_token provided.', );

my $failed_no_admin = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token =>
              'EC78R91DADJowsNogz16pHnAcEBiQHWBF',    #Mega Shops Administrators
            role_name => 'fireman'
        }
    ),
);

is( $failed_no_admin->code(), 400, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, );
is(
    $failed_no_admin_json->{message},
    'Invalid organization token.',
    'Because you are not an admin user.'
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

my $failed_no_group_data_no_role = request(
    POST $endpoint,
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
    'No group_token provided. No role_name provided.',
);

my $failed_no_organization_data_no_role = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content =>
      encode_json( { group_token => 'EC78R91DADJowsNogz16pHnAcEBiQHWBF' } ),
);

is( $failed_no_organization_data_no_role->code(), 400, );
#
my $failed_no_organization_data_no_role_json =
  decode_json( $failed_no_organization_data_no_role->content );

is( $failed_no_organization_data_no_role_json->{status}, 0, );
is(
    $failed_no_organization_data_no_role_json->{message},
    'No organization_token provided.',
);

my $failed_no_organization_data_no_group_data = request(
    POST $endpoint,
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
    'No organization_token provided.',
);

my $failed_no_organization_data_no_role_data = request(
    POST $endpoint,
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
    'No group_token provided.',
);

my $failed_invalid_organization_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_token        => 'non existent token',
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
    'Invalid organization token.',
);

my $failed_invalid_group_data = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ivalidorganizationtoken',
            group_token        => 'non existent token',
            role_name          => 'clowns'                  # There is no clowns
        }
    ),
);

is( $failed_invalid_group_data->code(), 400, );

my $failed_invalid_group_data_json =
  decode_json( $failed_invalid_group_data->content );

is( $failed_invalid_group_data_json->{status}, 0, );
is( $failed_invalid_group_data_json->{message},
    'Invalid organization token.', );

my $failed_group_not_found = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => 'invalidtoken',
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
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => 'EC78R91DADJowsNogz16pHnAcEBiQHWBF',
            role_name          => 'clown'
        }
    ),
);

is( $failed_role_not_found->code(), 400, );

my $failed_role_not_found_json = decode_json( $failed_role_not_found->content );

is( $failed_role_not_found_json->{status},  0, );
is( $failed_role_not_found_json->{message}, 'Required role does not exist.', );

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

my $create_group_success = request(
    POST '/organization/creategroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
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

my $superadmin_create_group_success = request(
    POST '/organization/creategroup',
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

isnt(
    $superadminadmin_get_megashops_groups_json->{data}->{groups}
      ->{'Mega Shop Sysadmins'}->{token},
    undef,
);

my $megashops_sysadmins_group_token =
  $superadminadmin_get_megashops_groups_json->{data}->{groups}
  ->{'Mega Shop Sysadmins'}->{token};

my $add_role_to_group_success = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Megashops
            group_token => $megashops_sysadmins_group_token,
            role_name   => 'fireman'
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

my $failed_already_added = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_sysadmins_group_token,
            role_name          => 'fireman'
        }
    ),
);

is( $failed_already_added->code(), 400, );

my $failed_already_added_json = decode_json( $failed_already_added->content );

is( $failed_already_added_json->{status}, 0, );
is(
    $failed_already_added_json->{message},
    'Required role is already assigned to this group.',
);

my $failed_not_your_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',           # Daedalus Token
            group_token => $megashops_sysadmins_group_token,
            role_name   => 'fireman'
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

isnt(
    $superadminadmin_get_daedalus_core_groups_json->{data}->{groups}
      ->{'Daedalus Core Sysadmins'}->{token},
    undef, 'Status success.'
);

my $daedalus_project_sysadmins_group_token =
  $superadminadmin_get_daedalus_core_groups_json->{data}->{groups}
  ->{'Daedalus Core Sysadmins'}->{token};

my $failed_not_your_organization_group = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',           # Megashops Token
            group_token => $daedalus_project_sysadmins_group_token,
            role_name   => 'fireman'
        }
    ),
);

is( $failed_not_your_organization_group->code(), 400, );

my $failed_not_your_organization_group_json =
  decode_json( $failed_not_your_organization_group->content );

is( $failed_not_your_organization_group_json->{status}, 0, );
is(
    $failed_not_your_organization_group_json->{message},
    'Required group does not exist.',
    "It exists but it does not belong to your organization."
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
    2, 'This response contains two groups' );

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
          ->{'Mega Shop Sysadmins'}->{roles}
    },
    1,
    'For the time being Mega Shop Sysadmins has only fireman as role'
);

$failed_not_your_organization = request(
    POST $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',    #Dadeadlus Project token
            group_token => $daedalus_project_sysadmins_group_token,
            role_name   => 'fireman'
        }
    ),
);

is( $failed_not_your_organization->code(), 400, );

$failed_not_your_organization_json =
  decode_json( $failed_not_your_organization->content );

is( $failed_not_your_organization_json->{status}, 0, );
is(
    $failed_not_your_organization_json->{message},
    'Invalid organization token.',
);

my $superadmin_add_role_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            group_token        => $daedalus_project_sysadmins_group_token,
            role_name          => 'fireman'
        }
    ),
);

is( $superadmin_add_role_success->code(), 200, );

my $superadmin_add_role_success_json =
  decode_json( $superadmin_add_role_success->content );

is( $superadmin_add_role_success_json->{status}, 1, );
is(
    $superadmin_add_role_success_json->{message},
    'Selected role has been added to organization group.',
);

isnt( $superadmin_add_role_success_json->{_hidden_data}, undef, );

my $superadmin_add_role_other_organization_success = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            group_token => $megashops_sysadmins_group_token,
            role_name   => 'health_watcher'
        }
    ),
);

is( $superadmin_add_role_other_organization_success->code(), 200, );

my $superadmin_add_role_other_organization_success_json =
  decode_json( $superadmin_add_role_other_organization_success->content );

is( $superadmin_add_role_other_organization_success_json->{status}, 1, );
is(
    $superadmin_add_role_other_organization_success_json->{message},
    'Selected role has been added to organization group.',
);

isnt( $superadmin_add_role_other_organization_success_json->{_hidden_data},
    undef, );

my $admin_user_mega_shop_two_roles = request(
    GET "/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
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
          ->{'Mega Shop Sysadmins'}->{roles}
    },
    2,
    'Mega Shop Sysadmins has two roles'
);

done_testing();

DatabaseSetUpTearDown::delete_database();
