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

my $imadmin_get_content = get('/imadmin');
ok( $imadmin_get_content, qr /Method GET not implemented/ );

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

is( $failed_imadmin_user_post_content->code(), 403, );

my $failed_imadmin_user_post_content_json =
  decode_json( $failed_imadmin_user_post_content->content );

is_deeply(
    $failed_imadmin_user_post_content_json,
    {
        'status'  => 0,
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

is( $failed_imadmin_password_post_content->code(), 403, );

my $failed_imadmin_password_post_content_json =
  decode_json( $failed_imadmin_password_post_content->content );

is_deeply(
    $failed_imadmin_password_post_content_json,
    {
        'status'  => 0,
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

is( $imadmin_post_success->code(), 200, );

my $imadmin_post_success_json = decode_json( $imadmin_post_success->content );

is( $imadmin_post_success_json->{status},          1, );
is( $imadmin_post_success_json->{message},         'You are an admin user.', );
is( $imadmin_post_success_json->{data}->{imadmin}, 1, );
isnt(
    $imadmin_post_success_json->{_hidden_data},
    'Only super admin users receive hidden data'
);

my $imadmin_post_success_other_admin = request(
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

is( $imadmin_post_success_other_admin->code(), 200, );

my $imadmin_post_success_other_admin_json =
  decode_json( $imadmin_post_success_other_admin->content );

is( $imadmin_post_success_other_admin_json->{status}, 1, );
is(
    $imadmin_post_success_other_admin_json->{message},
    'You are an admin user.',
);
is( $imadmin_post_success_other_admin_json->{data}->{imadmin}, 1, );
isnt( $imadmin_post_success_other_admin_json->{_hidden_data}, undef, );

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

is( $imadmin_post_failed_no_admin->code(), 403, );

my $imadmin_post_failed_no_admin_json =
  decode_json( $imadmin_post_failed_no_admin->content );

is(
    $imadmin_post_failed_no_admin_json->{message},
    'You are not an admin user.',
);
is( $imadmin_post_failed_no_admin_json->{data}->{imadmin}, 0, );
isnt(
    $imadmin_post_failed_no_admin_json->{_hidden_data},
    'Only super admin users receive hidden data'
);

my $imadmin_post_success_no_superadminadmin = request(
    POST '/imadmin',
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

is( $imadmin_post_success_no_superadminadmin->code(), 200, );

my $imadmin_post_success_no_superadminadmin_json =
  decode_json( $imadmin_post_success_no_superadminadmin->content );

is(
    $imadmin_post_success_no_superadminadmin_json->{message},
    'You are an admin user.',
);
is( $imadmin_post_success_no_superadminadmin_json->{data}->{imadmin}, 1, );
isnt( $imadmin_post_success_no_superadminadmin_json->{_hidden_data},
    'Only super admin users receive hidden data' );

done_testing();
