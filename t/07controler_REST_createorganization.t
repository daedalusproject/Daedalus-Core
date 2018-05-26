use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $add_orgaization_GET_content = get('/createorganization');

is_deeply(
    decode_json($add_orgaization_GET_content),
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

my $failed_because_no_auth = request(
    POST '/createorganization',
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is_deeply(
    $failed_because_no_auth_json,
    {
        'status'  => 'Failed',
        'message' => 'Wrong e-mail or password.',
    }
);

my $failed_no_admin = request(
    POST '/createorganization',
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

is( $failed_no_admin_json->{status},  'Failed', );
is( $failed_no_admin_json->{message}, 'You are not an admin user.', );

my $failed_no_data = request(
    POST '/createorganization',
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

my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status},  'Failed', );
is( $failed_no_data_json->{message}, 'Invalid organization data.', );

my $success_extra_data = request(
    POST '/createorganization',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            organization_data => {
                'name'        => 'Windmaker',
                'extra_stuff' => 'stuff',
            },
        }
    )
);

my $success_extra_data_json = decode_json( $success_extra_data->content );

is( $success_extra_data_json->{status},  'Success', );
is( $success_extra_data_json->{message}, 'Organization created.', );

my $correct_data = request(
    POST '/createorganization',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            organization_data => {
                'name' => 'Windmaker2',
            },
        }
    )
);

my $correct_data_json = decode_json( $correct_data->content );

is( $correct_data_json->{status},  'Success', );
is( $correct_data_json->{message}, 'Organization created.', );
isnt( $correct_data_json->{_hidden_data}, undef, );

my $duplicated_organization = request(
    POST '/createorganization',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            organization_data => {
                'name' => 'Windmaker',
            },
        }
    )
);

my $duplicated_organization_json =
  decode_json( $duplicated_organization->content );

is( $duplicated_organization_json->{status}, 'Failed', );
is( $duplicated_organization_json->{message}, 'Duplicated organization name.',
);

my $duplicated_spaces_organization = request(
    POST '/createorganization',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            organization_data => {
                'name' => 'Windmaker',
            },
        }
    )
);

my $duplicated_spaces_organization_json =
  decode_json( $duplicated_spaces_organization->content );

is( $duplicated_spaces_organization_json->{status}, 'Failed', );
is(
    $duplicated_spaces_organization_json->{message},
    'Duplicated organization name.',
);

done_testing();
