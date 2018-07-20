use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';

#æuse Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

use Data::Dumper;

ok( request('/ping')->is_success, 'Request should succeed' );

my $content      = get('/ping');
my $ping_content = decode_json($content);

is_deeply( $ping_content->{'status'}, 'pong' );

# Login User

## GET

my $login_get_content = get('/login');

ok( $login_get_content, qr /Method GET not implemented/ );

my $failed_login_user_post_content = request(
    POST '/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@nodomain.io',
                password => 'this_is_a_Test_1234',
            }
        }
    )
);

is( $failed_login_user_post_content->code(), 403, );

my $failed_login_user_post_content_json =
  decode_json( $failed_login_user_post_content->content );

is_deeply(
    $failed_login_user_post_content_json,
    {
        'status'  => 0,
        'message' => 'Wrong e-mail or password.',
    }
);

my $failed_login_password_post_content = request(
    POST '/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Failed_password',
            }
        }
    )
);

is( $failed_login_password_post_content->code(), 403, );

my $failed_login_password_post_content_json =
  decode_json( $failed_login_password_post_content->content );

is_deeply(
    $failed_login_password_post_content_json,
    {
        'status'  => 0,
        'message' => 'Wrong e-mail or password.',
    }
);

my $login_non_admin_post_success = request(
    POST '/login',
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

is( $login_non_admin_post_success->code(), 200, );

my $login_non_admin_post_success_json =
  decode_json( $login_non_admin_post_success->content );

is( $login_non_admin_post_success_json->{status},  1, );
is( $login_non_admin_post_success_json->{message}, 'Auth Successful.', );
is(
    $login_non_admin_post_success_json->{data}->{user}->{email},
    'notanadmin@daedalus-project.io',
);
is( $login_non_admin_post_success_json->{data}->{user}->{is_admin}, 0, );
is( $login_non_admin_post_success_json->{_hidden_data},
    undef, 'Non admin users do no receive hidden data' );

my $login_admin_post_success = request(
    POST '/login',
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

is( $login_admin_post_success->code(), 200, );

my $login_admin_post_success_json =
  decode_json( $login_admin_post_success->content );

is( $login_admin_post_success_json->{status},  1, );
is( $login_admin_post_success_json->{message}, 'Auth Successful.', );
is( $login_admin_post_success_json->{data}->{user}->{email},
    'admin@daedalus-project.io', );
is( $login_admin_post_success_json->{data}->{user}->{is_admin}, 1, );
isnt( $login_admin_post_success_json->{_hidden_data},
    undef, 'Admin users receive hidden data' );

done_testing();
