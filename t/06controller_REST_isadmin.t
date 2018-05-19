use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';

#æuse Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

use Data::Dumper;

# Check if User is admin

## GET

my $imadmin_get_content      = get('/imadmin');
my $imadmin_get_content_json = decode_json($imadmin_get_content);

is_deeply(
    $imadmin_get_content_json,
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

my $failed_imadmin_user_post_content = request(
    POST '/imadmin',
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

my $failed_imadmin_user_post_content_json =
  decode_json( $failed_imadmin_user_post_content->content );

is_deeply(
    $failed_imadmin_user_post_content_json,
    {
        'status'  => 'Failed',
        'message' => 'Wrong e-mail or password.',
    }
);

my $failed_imadmin_password_post_content = request(
    POST '/imadmin',
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

my $failed_imadmin_password_post_content_json =
  decode_json( $failed_imadmin_password_post_content->content );

is_deeply(
    $failed_imadmin_password_post_content_json,
    {
        'status'  => 'Failed',
        'message' => 'Wrong e-mail or password.',
    }
);

my $imadmin_post_success = request(
    POST '/imadmin',
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

my $imadmin_post_success_json = decode_json( $imadmin_post_success->content );

is( $imadmin_post_success_json->{status},  'Success', );
is( $imadmin_post_success_json->{message}, 'You are an admin user.', );
is( $imadmin_post_success_json->{imadmin}, 'True', );

my $imadmin_post_failed_no_admin = request(
    POST '/imadmin',
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

my $imadmin_post_failed_no_admin_json =
  decode_json( $imadmin_post_failed_no_admin->content );

is( $imadmin_post_failed_no_admin_json->{status}, 'Failed', );
is(
    $imadmin_post_failed_no_admin_json->{message},
    'You are not an admin user.',
);
is( $imadmin_post_failed_no_admin_json->{imadmin}, 'False', );

done_testing();
