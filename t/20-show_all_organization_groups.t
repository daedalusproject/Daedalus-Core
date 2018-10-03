use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;

my $endpoint = "organization/showoallgroups";

my $failed_because_no_auth = request(
    GET "$endpoint/sometoken",
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

is( $failed_because_no_auth->code(), 403, );

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is_deeply(
    $failed_because_no_auth_json,
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
    GET "$endpoint/sometoken",
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

my $admin_user_mega_shop_groups = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_groups->code(), 200, );

my $admin_user_mega_shop_groups_json =
  decode_json( $admin_user_mega_shop_groups->content );

is( $admin_user_mega_shop_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $admin_user_mega_shop_groups_json->{data}->{groups} },
    1, 'This response only contains one group' );

isnt( $admin_user_mega_shop_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

is(
    keys %{ $admin_user_mega_shop_groups_json->{data}->{groups} },
    1,
'For the time being there is only a group in this organization, Mega Shops Administrators'
);

isnt(
    $admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shops Administrators'},
    undef,
'For the time being there is only a group in this organization, Mega Shops Administrators'
);

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{groups}
          ->{'Mega Shops Administrators'}->{roles}
    },
    2,
'For the time being Supershops Administrators has two roles, firemen and organization master'
);

is( $admin_user_mega_shop_groups_json->{_hidden_data},
    undef, 'Non Super admin users do not receive hidden data' );

my $invalid_token_failed = request(
    GET "$endpoint/Z2cP8KLNEst3hs8CS",    #Invalid token
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $invalid_token_failed->code(), 400, );

my $invalid_token_failed_json = decode_json( $invalid_token_failed->content );

is( $invalid_token_failed_json->{status}, 0, 'Invalid token.' );
is(
    $invalid_token_failed_json->{message},
    'Invalid Organization token.',
    'Of course.'
);

my $valid_token_not_my_organization_failed = request(
    GET "$endpoint/FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO",    #Daedalus Project
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $valid_token_not_my_organization_failed->code(), 400, );

my $valid_token_not_my_organization_failed_json =
  decode_json( $valid_token_not_my_organization_failed->content );

is( $valid_token_not_my_organization_failed_json->{status},
    0, 'Not your organization.' );
is(
    $valid_token_not_my_organization_failed_json->{message},
    'Invalid organization token.',
    'Not really but Daedalus-Core is not going to tell you.'
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

my $superadmin_show_organizations = request(
    GET "/organization/show",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_show_organizations->code(), 200, );

my $superadmin_show_organizations =
  decode_json( $superadmin_show_organizations->content );

my $ultra_shops_token =
  $superadmin_show_organizations->{data}->{organizations}->{Ultrashops}
  ->{token};

my $superadmin_user_ultra_shop_groups = request(
    GET "$endpoint/$ultra_shops_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_user_ultra_shop_groups->code(), 200, );

my $superadmin_user_ultra_shop_groups_json =
  decode_json( $superadmin_user_ultra_shop_groups->content );

is( $superadmin_user_ultra_shop_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $superadmin_user_ultra_shop_groups_json->{data}->{groups} },
    1, 'There is only one group' );

isnt(
    $superadmin_user_ultra_shop_groups_json->{data}->{groups}
      ->{'Ultrashops Administrators'},
    undef,
'For the time being there is only a group in this organization, Ultrashops Administrators'
);

is(
    scalar @{
        $superadmin_user_ultra_shop_groups_json->{data}->{groups}
          ->{'Ultrashops Administrators'}->{roles}
    },
    1,
    'For the time being Ultrashops Administrators has only one role'
);

isnt( $superadmin_user_ultra_shop_groups_json->{_hidden_data},
    undef, 'Super admin users receive hidden data' );

is(
    $superadmin_user_ultra_shop_groups_json->{_hidden_data}->{'groups'}
      ->{'Ultrashops Administrators'}->{'roles'}->{'organization_master'},
    1, 'Check ids'
);

my $super_admin_user_mega_shop_groups = request(
    GET "$endpoint/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf",    # Mega Shops Token
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $super_admin_user_mega_shop_groups->code(), 200, );

my $super_admin_user_mega_shop_groups_json =
  decode_json( $super_admin_user_mega_shop_groups->content );

is( $super_admin_user_mega_shop_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $super_admin_user_mega_shop_groups_json->{data}->{groups} },
    1, 'This response only contains one group' );

isnt( $super_admin_user_mega_shop_groups_json->{data}->{groups},
    undef, 'API response contains organization groups' );

is(
    keys %{ $super_admin_user_mega_shop_groups_json->{data}->{groups} },
    1,
'For the time being there is only a group in this organization, Mega Shops Administrators'
);

isnt(
    $super_admin_user_mega_shop_groups_json->{data}->{groups}
      ->{'Mega Shops Administrators'},
    undef,
'For the time being there is only a group in this organization, Mega Shops Administrators'
);

is(
    scalar @{
        $super_admin_user_mega_shop_groups_json->{data}->{groups}
          ->{'Mega Shops Administrators'}->{roles}
    },
    2,
'For the time being Supershops Administrators has two roles, firemen and organization master'
);

isnt( $super_admin_user_mega_shop_groups_json->{_hidden_data},
    undef, 'Super admin users do receive hidden data' );

done_testing();
