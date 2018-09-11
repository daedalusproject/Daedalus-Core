use strict;
use warnings;
use Test::More;

use Data::Dumper;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $endpoint = "showorphanusers";

my $show_organizations_GET_content = get($endpoint);
ok( $show_organizations_GET_content, qr /Method GET not implemented/ );

my $failed_because_no_auth = request(
    POST $endpoint,
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
        'message' => 'Wrong e-mail or password.',
    }
);

my $admin_failed_login = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_failed_Test_1234',
            }
        }
    )
);

is( $admin_failed_login->code(), 403, );

my $admin_failed_login_json = decode_json( $admin_failed_login->content );

is( $admin_failed_login_json->{status}, 0, 'Status failed, wrong password.' );

my $failed_no_admin = request(
    POST $endpoint,
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

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'You are not an admin user.', );

my $megashops_admin_valid_token = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            },
        }
    )
);

is( $megashops_admin_valid_token->code(), 200, );

my $megashops_admin_valid_token_json =
  decode_json( $megashops_admin_valid_token->content );

is( $megashops_admin_valid_token_json->{status}, 1, );

is( keys %{ $megashops_admin_valid_token_json->{data}->{users} },
    0, 'Mega Shops admin has no orphan users' );

is( $megashops_admin_valid_token_json->{_hidden_data},
    undef, 'Non Super admin users do no receive hidden data' );

my $daedalus_admin = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
        }
    )
);

is( $daedalus_admin->code(), 200, );

my $daedalus_admin_json = decode_json( $daedalus_admin->content );

is( keys %{ $daedalus_admin_json->{orphan_users} },
    2, 'Daedalus Project has only one user so far' );

isnt(
    $daedalus_admin_json->{orphan_users}
      { ( keys %{ $daedalus_admin_json->{orphan_users} } )[0] }->{_hidden_data},
    undef,
);

# Register new user

request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token =>
'1qYyhZWMikdm9WK6q/2376cqSoRxO2222UBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l',
                password => '1_HAt3_mY_L1F3',
            },
        }
    )
);

my $magashops_admin_one_new_user = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            },
        }
    )
);

is( $magashops_admin_one_new_user->code(), 200, );

my $magashops_admin_one_new_user_json =
  decode_json( $magashops_admin_one_new_user->content );

is( keys %{ $magashops_admin_one_new_user_json->{orphan_users} },
    1, 'Marvin is orphan.' );

is(
    $magashops_admin_one_new_user_json->{orphan_users}
      { ( keys %{ $daedalus_admin_json->{orphan_users} } )[0] }->{_hidden_data},
    undef,
);

done_testing();
