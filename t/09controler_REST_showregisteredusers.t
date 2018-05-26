use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $show_my_registered_users_GET_content = get('/showmyregisteredusers');

is_deeply(
    decode_json($show_my_registered_users_GET_content),
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

my $failed_because_no_auth = request(
    POST '/showmyregisteredusers',
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is( $failed_because_no_auth_json->{status},
    'Failed', 'Status failed, no auth.' );
is(
    $failed_because_no_auth_json->{message},
    'Wrong e-mail or password.',
    'A valid e-mail password mut be provided.'
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

is( $failed_no_admin_json->{status}, 'Failed',
    'Status failed, not an andmin.' );
is(
    $failed_no_admin_json->{message},
    'You are not an admin user.',
    'Only admin uers are able view its registered users.'
);

done_testing();
