use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common;

my $failed_because_no_auth_token =
  request( POST '/organization/create', Content_Type => 'application/json', );

is( $failed_because_no_auth_token->code(), 403, );

my $failed_because_no_auth_token_json =
  decode_json( $failed_because_no_auth_token->content );

is_deeply(
    $failed_because_no_auth_token_json,
    {
        'status'  => '0',
        'message' => 'No sesion token provided.',
    }
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
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'You are not an admin user.', );

my $admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradminagain@megashops.com',
                password => '__::___Password_1234',
            }
        }
    )
);

is( $admin_success->code(), 200, );

my $admin_success_json = decode_json( $admin_success->content );

is( $admin_success_json->{status}, 1, );

my $admin_session_token = $admin_success_json->{data}->{session_token};

my $admin_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_session_token", '' );

my $failed_no_data = request(
    POST '/organization/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( {} )
);

is( $failed_no_data->code(), 400, );
#
my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status},  0, );
is( $failed_no_data_json->{message}, 'Invalid organization data.', );

#my $success_extra_data = request(
#    POST '/createorganization',
#    Content_Type => 'application/json',
#    Content      => encode_json(
#        {
#            auth => {
#                email    => 'admin@daedalus-project.io',
#                password => 'this_is_a_Test_1234',
#            },
#            organization_data => {
#                'name'        => 'Windmaker',
#                'extra_stuff' => 'stuff',
#            },
#        }
#    )
#);
#
#is( $success_extra_data->code(), 200, );
#
#my $success_extra_data_json = decode_json( $success_extra_data->content );
#
#is( $success_extra_data_json->{status},  1, );
#is( $success_extra_data_json->{message}, 'Organization created.', );
#
#my $correct_data = request(
#    POST '/createorganization',
#    Content_Type => 'application/json',
#    Content      => encode_json(
#        {
#            auth => {
#                email    => 'admin@daedalus-project.io',
#                password => 'this_is_a_Test_1234',
#            },
#            organization_data => {
#                'name' => 'Windmaker2',
#            },
#        }
#    )
#);
#
#is( $correct_data->code(), 200, );
#
#my $correct_data_json = decode_json( $correct_data->content );
#
#is( $correct_data_json->{status},  1, );
#is( $correct_data_json->{message}, 'Organization created.', );
#isnt( $correct_data_json->{_hidden_data}, undef, );
#
#my $duplicated_organization = request(
#    POST '/createorganization',
#    Content_Type => 'application/json',
#    Content      => encode_json(
#        {
#            auth => {
#                email    => 'admin@daedalus-project.io',
#                password => 'this_is_a_Test_1234',
#            },
#            organization_data => {
#                'name' => 'Windmaker',
#            },
#        }
#    )
#);
#
#is( $duplicated_organization->code(), 400, );
#
#my $duplicated_organization_json =
#  decode_json( $duplicated_organization->content );
#
#is( $duplicated_organization_json->{status}, 0, );
#is( $duplicated_organization_json->{message}, 'Duplicated organization name.',
#);
#
#my $duplicated_spaces_organization = request(
#    POST '/createorganization',
#    Content_Type => 'application/json',
#    Content      => encode_json(
#        {
#            auth => {
#                email    => 'admin@daedalus-project.io',
#                password => 'this_is_a_Test_1234',
#            },
#            organization_data => {
#                'name' => 'Windmaker',
#            },
#        }
#    )
#);
#
#is( $duplicated_spaces_organization->code(), 400, );
#
#my $duplicated_spaces_organization_json =
#  decode_json( $duplicated_spaces_organization->content );
#
#is( $duplicated_spaces_organization_json->{status}, 0, );
#is(
#    $duplicated_spaces_organization_json->{message},
#    'Duplicated organization name.',
#);
#
#my $correct_data_admin_not_superadmin = request(
#    POST '/createorganization',
#    Content_Type => 'application/json',
#    Content      => encode_json(
#        {
#            auth => {
#                email    => 'yetanotheradmin@daedalus-project.io',
#                password => 'Is a Password_1234',
#            },
#            organization_data => {
#                'name' => 'Cloudmaker',
#            },
#        }
#    )
#);
#
#is( $correct_data_admin_not_superadmin->code(), 200, );
#
#my $correct_data_admin_not_superadmin_json =
#  decode_json( $correct_data_admin_not_superadmin->content );
#
#is( $correct_data_admin_not_superadmin_json->{status}, 1, );
#is(
#    $correct_data_admin_not_superadmin_json->{message},
#    'Organization created.',
#);
#is( $correct_data_admin_not_superadmin_json->{_hidden_data}, undef, );
#
done_testing();
