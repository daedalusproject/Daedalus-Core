use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;

my $endpoint = "/organization/show";

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

is( $failed_because_no_auth_json->{status},  0, );
is( $failed_because_no_auth_json->{message}, 'No session token provided.', );

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

my $admin_two_organization = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $admin_two_organization->code(), 200, );

my $admin_two_organization_json =
  decode_json( $admin_two_organization->content );

is( $admin_two_organization_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_two_organization_json->{data}->{organizations} },
    2, 'Admin belongis to 2 organizations' );

isnt(
    $admin_two_organization_json->{data}->{organizations}->{'Daedalus Project'}
      ->{token},
    undef, 'API response contains organization token'
);

isnt( $admin_two_organization_json->{_hidden_data},
    undef, 'Super admin users receive hidden data' );

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

my $user_without_organization = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $user_without_organization->code(), 200, );

my $user_without_organization_json =
  decode_json( $user_without_organization->content );

is( $user_without_organization_json->{status}, 1, 'Status success.' );
is( keys %{ $user_without_organization_json->{data}->{organizations} },
    0, 'This user does not belong to any organization' );

is( $user_without_organization_json->{_hidden_data},
    undef, 'Non Super admin users do no receive hidden data' );

my $admin_megashops_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $admin_megashops_success->code(), 200, );

my $admin_megashops_success_json =
  decode_json( $admin_megashops_success->content );

is( $admin_megashops_success_json->{status}, 1, );

my $admin_megashops_session_token =
  $admin_megashops_success_json->{data}->{session_token};

my $admin_megashops_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_megashops_session_token", '' );

my $admin_user_mega_shop_organization = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_megashops_authorization_basic",
);

is( $admin_user_mega_shop_organization->code(), 200, );

my $admin_user_mega_shop_organization_json =
  decode_json( $admin_user_mega_shop_organization->content );

is( $admin_user_mega_shop_organization_json->{status}, 1, 'Status success.' );
is(
    keys %{ $admin_user_mega_shop_organization_json->{data}->{organizations} },
    2,
    'This user belongs to Mega Shops and Supershops'
);

isnt(
    $admin_user_mega_shop_organization_json->{data}->{organizations}
      ->{'Supershops'}->{token},
    undef, 'API response contains organization token'
);

is( $admin_user_mega_shop_organization_json->{_hidden_data},
    undef, 'Non Super admin users do no receive hidden data' );

my $non_admin_megashops_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $non_admin_megashops_success->code(), 200, );

my $non_admin_megashops_success_json =
  decode_json( $non_admin_megashops_success->content );

is( $non_admin_megashops_success_json->{status}, 1, );

my $non_admin_megashops_session_token =
  $non_admin_megashops_success_json->{data}->{session_token};

my $non_admin_megashops_authorization_basic =
  MIME::Base64::encode( "session_token:$non_admin_megashops_session_token",
    '' );

my $no_admin_user_mega_shop_organization = request(
    GET $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $non_admin_megashops_authorization_basic",
);

is( $no_admin_user_mega_shop_organization->code(), 200, );

my $no_admin_user_mega_shop_organization_json =
  decode_json( $no_admin_user_mega_shop_organization->content );

is( $no_admin_user_mega_shop_organization_json->{status}, 1,
    'Status success.' );

is(
    keys %{ $no_admin_user_mega_shop_organization_json->{data}->{organizations}
    },
    2,
    'This user belongs to Mega Shops and Supershops'
);

isnt(
    $no_admin_user_mega_shop_organization_json->{data}->{organizations}
      ->{'Supershops'}->{token},
    undef, 'API response contains organization token'
);

is( $no_admin_user_mega_shop_organization_json->{_hidden_data},
    undef, 'Non Super admin users do no receive hidden data' );

done_testing();
