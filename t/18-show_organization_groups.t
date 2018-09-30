use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;

my $endpoint = "/organization/showgroups";

my $show_organizations_GET_content = get($endpoint);
ok( $show_organizations_GET_content, qr /Method GET not implemented/ );

my $failed_because_no_auth = request(
    GET $endpoint,
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
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $admin_user_mega_shop_groups->code(), 200, );

my $admin_user_mega_shop_groups_json =
  decode_json( $admin_user_mega_shop_groups->content );

is( $admin_user_mega_shop_groups_json->{status}, 1, 'Status success.' );
is( keys %{ $admin_user_mega_shop_groups_json->{data}->{organizations} },
    2, 'This user belongs to Mega Shops and Supershops' );

isnt(
    $admin_user_mega_shop_organization_json->{data}->{organizations}
      ->{'Supershops'}->{token},
    undef, 'API response contains organization token'
);

isnt(
    $admin_user_mega_shop_organization_json->{data}->{organizations}
      ->{'Supershops'}->{groups},
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
    $admin_user_mega_shop_organization_json->{data}->{organizations}
      ->{'Supershops'}->{groups}->{'Supershops Administrators'},
    undef,
'For the time being there is only a group in this organization, Supershops Administrators'
);

is(
    scalar @{
        $admin_user_mega_shop_groups_json->{data}->{organizations}
          ->{'Supershops'}->{groups}->{'Supershops Administrators'}->{roles}
    },
    1,
    'For the time being Supershops Administrators has only one role'
);

is( $admin_user_mega_shop_organization_json->{_hidden_data},
    undef, 'Non Super admin users do not receive hidden data' );

done_testing();
