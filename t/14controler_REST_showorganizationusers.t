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
is( $failed_no_data_json->{message}, 'Invalid organization data.', );

done_testing();
