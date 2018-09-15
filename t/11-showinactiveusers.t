use strict;
use warnings;
use Test::More;

use Data::Dumper;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $endpoint = "showinactiveusers";

my $show_inactive_users_GET_content = get($endpoint);
ok( $show_inactive_users_GET_content, qr /Method GET not implemented/ );

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

# admin@daedalus-project.io has registered two users for the time being, these users have not confirmed its registration yet

my $admin_two_user = request(
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

is( $admin_two_user->code(), 200, );

my $admin_two_user_json = decode_json( $admin_two_user->content );

is( $admin_two_user_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_two_user_json->{inactive_users} },
    2, 'There are 2 inactive users' );

my $anotheradmin_admin_zero_users = request(
    POST $endpoint,
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'adminagain@daedalus-project.io',
                password => '__:___Password_1234',
            }
        }
    )
);

is( $anotheradmin_admin_zero_users->code(), 200, );

my $anotheradmin_admin_zero_users_json =
  decode_json( $anotheradmin_admin_zero_users->content );

is( $anotheradmin_admin_zero_users_json->{status},
    1, 'Status success, andmin.' );
is( keys %{ $anotheradmin_admin_zero_users_json->{inactive_users} },
    0, 'adminagain@daedalus-project.io has 0 users inactive' );

# Let's confirm one of admin@daedalus-project.io inactive users
# othernotanadmin@daedalus-project.io

my $inactive_user_data = $admin_two_user_json->{inactive_users}
  ->{'othernotanadmin@daedalus-project.io'};
my $inactive_user_data_auth_token =
  $inactive_user_data->{_hidden_data}->{user}->{auth_token};

my $success_valid_auth_token_and_password = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token => $inactive_user_data_auth_token,
                password   => 'val1d_Pa55w0rd',
            }
        }
    )
);

is( $success_valid_auth_token_and_password->code(), 200 );

my $admin_one_user = request(
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

is( $admin_one_user->code(), 200, );

my $admin_one_user_json = decode_json( $admin_one_user->content );

is( $admin_one_user_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_one_user_json->{inactive_users} },
    1, 'Now, There is only one inactive user' );

done_testing();
