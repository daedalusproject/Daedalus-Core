use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;


my $failed_because_no_auth = request(
    GET '/user/showregistered',
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

is( $failed_because_no_auth->code(), 403, );

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is( $failed_because_no_auth_json->{status}, 0, 'Status failed, no auth.' );
is(
    $failed_because_no_auth_json->{message},
    'No sesion token provided.',
    'A valid session token must be provided.'
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
    GET '/user/showregistered',
    Content_Type => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, 'Status failed, not an andmin.' );
is(
    $failed_no_admin_json->{message},
    'You are not an admin user.',
    'Only admin uers are able view its registered users.'
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


my $admin_admin_two_users = request(
    GET '/user/showregistered',
    Content_Type => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $admin_admin_two_users->code(), 200, );

my $admin_admin_two_users_json = decode_json( $admin_admin_two_users->content );

is( $admin_admin_two_users_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_admin_two_users_json->{registered_users} },
    2, 'admin@daedalus-project.io has 2 users registered' );
ok(
    $admin_admin_two_users_json->{registered_users}
      { ( keys %{ $admin_admin_two_users_json->{registered_users} } )[0] }
      ->{_hidden_data},
    'admin@daedalus-project.io is super admin.'
);

my $other_admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content      => encode_json(
        {
            auth => {
                email    => 'adminagain@daedalus-project.io',
                password => '__:___Password_1234',
            }
        }
    )
);

is( $other_admin_success->code(), 200, );

my $other_admin_success_json = decode_json( $other_admin_success->content );

is( $other_admin_success_json->{status}, 1, );

my $other_admin_session_token =
  $other_admin_success_json->{data}->{session_token};

my $other_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$other_admin_session_token", '' );

my $anotheradmin_admin_zero_users = request(
    GET '/user/showregistered',
    Content_Type => 'application/json',
    Authorization => "Basic $other_admin_authorization_basic",
);

is( $anotheradmin_admin_zero_users->code(), 200, );

my $anotheradmin_admin_zero_users_json =
  decode_json( $anotheradmin_admin_zero_users->content );

is( $anotheradmin_admin_zero_users_json->{status},
    1, 'Status success, andmin.' );
is( keys %{ $anotheradmin_admin_zero_users_json->{registered_users} },
    0, 'adminagain@daedalus-project.io has 0 users registered' );

my $yet_other_admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content      => encode_json(
        {
            auth => {
                email    => 'yetanotheradmin@daedalus-project.io',
                password => 'Is a Password_1234',
            }
        }
    )
);

is( $yet_other_admin_success->code(), 200, );

my $yet_other_admin_success_json = decode_json( $yet_other_admin_success->content );

is( $yet_other_admin_success_json->{status}, 1, );

my $yet_other_admin_session_token =
  $yet_other_admin_success_json->{data}->{session_token};

my $yet_other_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$yet_other_admin_session_token", '' );

my $yet_other_admin_one_user = request(
    GET '/user/showregistered',
    Content_Type => 'application/json',
    Authorization => "Basic $yet_other_admin_authorization_basic",
);


is( $yet_other_admin_one_user->code(), 200, );

my $yet_other_admin_one_user_json = decode_json( $yet_other_admin_one_user->content );

is( $yet_other_admin_one_user_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $yet_other_admin_one_user_json->{registered_users} },
    1, 'There is one user registered' );
isnt(
    $yet_other_admin_one_user_json->{registered_users}
      { ( keys %{ $yet_other_admin_one_user_json->{registered_users} } )[0] }
      ->{_hidden_data},
    'yetanotheradmin@daedalus-project.io is not super admin.'
);

done_testing();
