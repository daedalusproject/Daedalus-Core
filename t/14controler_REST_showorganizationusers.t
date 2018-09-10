use strict;
use warnings;
use Test::More;

use Data::Dumper;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $endpoint = "showorganizationusers";

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

my $failed_no_data = request(
    POST $endpoint,
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

is( $failed_no_data->code(), 400, );

my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status},  0, );
is( $failed_no_data_json->{message}, 'Invalid Organization token.', );

my $megashops_admin_invalid_short_token = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            },
            organization => {
                token => 'somefailedtoken',
            },
        }
    )
);

is( $megashops_admin_invalid_short_token->code(), 400, );

my $megashops_admin_invalid_short_token_json =
  decode_json( $megashops_admin_invalid_short_token->content );

is( $megashops_admin_invalid_short_token_json->{status}, 0, );
is(
    $megashops_admin_invalid_short_token_json->{message},
    'Invalid Organization token.',
);

my $megashops_admin_invalid_token = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            },
            organization => {
                token =>
                  'ljMPXvVHZZQTbXsaXWA2kgSWzL942Pof',    #Almost the same token
            },
        }
    )
);

is( $megashops_admin_invalid_token->code(), 400, );

my $megashops_admin_invalid_token_json =
  decode_json( $megashops_admin_invalid_token->content );

is( $megashops_admin_invalid_token_json->{status}, 0, );
is(
    $megashops_admin_invalid_token_json->{message},
    'Invalid Organization token.',
);

my $megashops_admin_daedalus_token = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            },
            organization => {
                token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO'
                ,    #Daedalus Organization token
            },
        }
    )
);

is( $megashops_admin_daedalus_token->code(), 400, );

my $megashops_admin_daedalus_token_json =
  decode_json( $megashops_admin_invalid_token->content );

is( $megashops_admin_daedalus_token_json->{status}, 0, );
is(
    $megashops_admin_daedalus_token_json->{message},
    'Invalid Organization token.',
);

my $megashops_admin_valid_token = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            },
            organization => {
                token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            },
        }
    )
);

is( $megashops_admin_valid_token->code(), 200, );

my $megashops_admin_valid_token_json =
  decode_json( $megashops_admin_valid_token->content );

is( $megashops_admin_valid_token_json->{status}, 1, );

is( keys %{ $megashops_admin_valid_token_json->{data}->{users} },
    2, 'Mega Shops has two  users' );

is( $megashops_admin_valid_token_json->{_hidden_data},
    undef, 'Non Super admin users do no receive hidden data' );

my $superadmin_token = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            organization => {
                token => 'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',
            },
        }
    )
);

is( $superadmin_token->code(), 200, );

my $superadmin_token_json = decode_json( $superadmin_token->content );

is( scalar @{ $superadmin_token_json->{data}->{users} },
    1, 'Daedalus Project has only one user so far' );

isnt( $megashops_admin_valid_token_json->{_hidden_data},
    undef, 'Super admin users do receive hidden data' );

done_testing();
