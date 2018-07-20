use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $add_orgaization_GET_content = get('/createorganization');
ok( $add_orgaization_GET_content, qr /Method GET not implemented/ );

my $failed_because_no_auth = request(
    POST '/createorganization',
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

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
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

is( $failed_no_data->code(), 400, );

my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status},  0, );
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

is( $success_extra_data->code(), 200, );

my $success_extra_data_json = decode_json( $success_extra_data->content );

is( $success_extra_data_json->{status},  1, );
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

is( $correct_data->code(), 200, );

my $correct_data_json = decode_json( $correct_data->content );

is( $correct_data_json->{status},  1, );
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

is( $duplicated_organization->code(), 400, );

my $duplicated_organization_json =
  decode_json( $duplicated_organization->content );

is( $duplicated_organization_json->{status}, 0, );
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

is( $duplicated_spaces_organization->code(), 400, );

my $duplicated_spaces_organization_json =
  decode_json( $duplicated_spaces_organization->content );

is( $duplicated_spaces_organization_json->{status}, 0, );
is(
    $duplicated_spaces_organization_json->{message},
    'Duplicated organization name.',
);

my $correct_data_admin_not_superadmin = request(
    POST '/createorganization',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'yetanotheradmin@daedalus-project.io',
                password => 'Is a Password_1234',
            },
            organization_data => {
                'name' => 'Cloudmaker',
            },
        }
    )
);

is( $duplicated_spaces_organization->code(), 200, );

my $correct_data_admin_not_superadmin_json =
  decode_json( $correct_data_admin_not_superadmin->content );

is( $correct_data_admin_not_superadmin_json->{status}, 1, );
is(
    $correct_data_admin_not_superadmin_json->{message},
    'Organization created.',
);
is( $correct_data_admin_not_superadmin_json->{_hidden_data}, undef, );

done_testing();
