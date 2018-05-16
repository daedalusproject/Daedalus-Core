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

my $login_get_content      = get('/login');
my $login_get_content_json = decode_json($login_get_content);

is_deeply(
    $login_get_content_json,
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

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

my $failed_login_user_post_content_json =
  decode_json( $failed_login_user_post_content->content );

is_deeply(
    $failed_login_user_post_content_json,
    {
        'status'  => 'Failed',
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

my $failed_login_password_post_content_json =
  decode_json( $failed_login_password_post_content->content );

is_deeply(
    $failed_login_password_post_content_json,
    {
        'status'  => 'Failed',
        'message' => 'Wrong e-mail or password.',
    }
);

my $login_post_success = request(
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

my $login_post_success_json = decode_json( $login_post_success->content );

is_deeply( $login_post_success_json->{status}, 'Success', );

done_testing();
