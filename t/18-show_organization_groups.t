use v5.26;
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

my $endpoint = "/organization/showusergroups";

my $show_organizations_GET_content = get($endpoint);
ok( $show_organizations_GET_content, qr /Method GET not implemented/ );

my $failed_because_no_auth = request(
    GET $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

is( $failed_because_no_auth->code(), 400, );

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is( $failed_because_no_auth_json->{status},  0, );
is( $failed_because_no_auth_json->{message}, "No session token provided.", );

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

my $admin_user_mega_shop_groups = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $admin_user_mega_shop_groups->code(), 200, );

my $admin_user_mega_shop_groups_json =
  decode_json( $admin_user_mega_shop_groups->content );

is( $admin_user_mega_shop_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $admin_user_mega_shop_groups_json->{data}->{organizations} },
    2, 'This user belongs to Mega Shops and Supershops' );

isnt(
    $admin_user_mega_shop_groups_json->{data}->{organizations}->{'Supershops'}
      ->{token},
    undef, 'API response contains organization token'
);

isnt(
    $admin_user_mega_shop_groups_json->{data}->{organizations}->{'Supershops'}
      ->{groups},
    undef, 'API response contains organization groups'
);

is(
    keys %{
        $admin_user_mega_shop_groups_json->{data}->{organizations}
          ->{'Supershops'}->{groups}
    },
    1,
'For the time being there is only a group in this organization, Supershops Administrators'
);

isnt(
    $admin_user_mega_shop_groups_json->{data}->{organizations}->{'Supershops'}
      ->{groups}->{'Supershops Administrators'},
    undef,
'For the time being there is only a group in this organization, Supershops Administrators'
);

isnt(
    $admin_user_mega_shop_groups_json->{data}->{organizations}->{'Supershops'}
      ->{groups}->{'Supershops Administrators'}->{'token'},
    undef, 'Supershops Administrators has an organization group token'
);

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{organizations}
          ->{'Supershops'}->{groups}->{'Supershops Administrators'}->{roles}
    },
    1,
    'For the time being Supershops Administrators has only one role'
);

is( $admin_user_mega_shop_groups_json->{_hidden_data},
    undef, 'Non Super admin users do not receive hidden data' );

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

my $superadmin_user_ultra_shop_groups = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_user_ultra_shop_groups->code(), 200, );

my $superadmin_user_ultra_shop_groups_json =
  decode_json( $superadmin_user_ultra_shop_groups->content );

is( $superadmin_user_ultra_shop_groups_json->{status}, 1, 'Status success.' );
is(
    keys %{ $superadmin_user_ultra_shop_groups_json->{data}->{organizations} },
    2,
    'This user belongs to Daedalus Project and Ultrashops'
);

isnt(
    $superadmin_user_ultra_shop_groups_json->{data}->{organizations}
      ->{'Ultrashops'}->{token},
    undef, 'API response contains organization token'
);

isnt(
    $superadmin_user_ultra_shop_groups_json->{data}->{organizations}
      ->{'Ultrashops'}->{groups},
    undef, 'API response contains organization groups'
);

is(
    keys %{
        $superadmin_user_ultra_shop_groups_json->{data}->{organizations}
          ->{'Ultrashops'}->{groups}
    },
    1,
'For the time being there is only a group in this organization, Supershops Administrators'
);

isnt(
    $superadmin_user_ultra_shop_groups_json->{data}->{organizations}
      ->{'Ultrashops'}->{groups}->{'Ultrashops Administrators'},
    undef,
'For the time being there is only a group in this organization, Ultrashops Administrators'
);

isnt(
    $superadmin_user_ultra_shop_groups_json->{data}->{organizations}
      ->{'Ultrashops'}->{groups}->{'Ultrashops Administrators'}->{'token'},
    undef, 'Ultrashops Administrators has an organization group token'
);

is(
    scalar @{
        $superadmin_user_ultra_shop_groups_json->{data}->{organizations}
          ->{'Ultrashops'}->{groups}->{'Ultrashops Administrators'}->{roles}
    },
    1,
    'For the time being Ultrashops Administrators has only one role'
);

isnt( $superadmin_user_ultra_shop_groups_json->{_hidden_data},
    undef, 'Super admin users receive hidden data' );

is(
    $superadmin_user_ultra_shop_groups_json->{_hidden_data}->{organizations}
      ->{'Ultrashops'}->{'groups'}->{'Ultrashops Administrators'}->{'roles'}
      ->{'organization_master'},
    1, 'Check ids'
);

done_testing();

DatabaseSetUpTearDown::delete_database();
