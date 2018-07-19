use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $show_my_registered_users_GET_content = get('/showmyregisteredusers');
ok( $show_my_registered_users_GET_content, qr /Method GET not implemented/ );

my $failed_because_no_auth = request(
    POST '/showmyregisteredusers',
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is( $failed_because_no_auth_json->{status}, 0, 'Status failed, no auth.' );
is(
    $failed_because_no_auth_json->{message},
    'Wrong e-mail or password.',
    'A valid e-mail password must be provided.'
);

my $failed_no_admin = request(
    POST '/showmyregisteredusers',
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

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, 'Status failed, not an andmin.' );
is(
    $failed_no_admin_json->{message},
    'You are not an admin user.',
    'Only admin uers are able view its registered users.'
);

my $admin_admin_two_users = request(
    POST '/showmyregisteredusers',
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

my $admin_admin_two_users_json = decode_json( $admin_admin_two_users->content );

is( $admin_admin_two_users_json->{status}, 'Success',
    'Status success, admin.' );
is( keys %{ $admin_admin_two_users_json->{registered_users} },
    2, 'admin@daedalus-project.io has 2 users registered' );
ok(
    $admin_admin_two_users_json->{registered_users}
      { ( keys %{ $admin_admin_two_users_json->{registered_users} } )[0] }
      ->{_hidden_data},
    'admin@daedalus-project.io is super admin.'
);

my $anotheradmin_admin_zero_users = request(
    POST '/showmyregisteredusers',
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

my $anotheradmin_admin_zero_users_json =
  decode_json( $anotheradmin_admin_zero_users->content );

is( $anotheradmin_admin_zero_users_json->{status},
    'Success', 'Status success, andmin.' );
is( keys %{ $anotheradmin_admin_zero_users_json->{registered_users} },
    0, 'adminagain@daedalus-project.io has 0 users registered' );

my $admin_admin_one_user = request(
    POST '/showmyregisteredusers',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'yetanotheradmin@daedalus-project.io',
                password => 'Is a Password_1234',
            }
        }
    )
);

my $admin_admin_one_user_json = decode_json( $admin_admin_one_user->content );

is( $admin_admin_one_user_json->{status}, 'Success', 'Status success, admin.' );
is( keys %{ $admin_admin_one_user_json->{registered_users} },
    1, 'yetanotheradmin@daedalus-project.io has 1 user registered' );
isnt(
    $admin_admin_two_users_json->{registered_users}
      { ( keys %{ $admin_admin_two_users_json->{registered_users} } )[0] }
      ->{_hidden_data},
    'yetanotheradmin@daedalus-project.io is not super admin.'
);

done_testing();
