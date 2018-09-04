use strict;
use warnings;
use Test::More;

use Data::Dumper;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $endpoint = "showorganizations";

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

my $admin_three_organization = request(
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

is( $admin_three_organization->code(), 200, );

my $admin_three_organization_json =
  decode_json( $admin_three_organization->content );

is( $admin_three_organization_json->{status}, 1, 'Status success, admin.' );
is( scalar @{ $admin_three_organization_json->{data}->{organizations} },
    3, 'Admin belongis to 3 organizations' );

isnt( $admin_three_organization_json->{_hidden_data},
    undef, 'Super admin users receive hidden data' );

my $user_without_organization = request(
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

is( $user_without_organization->code(), 200, );

my $user_without_organization_json =
  decode_json( $user_without_organization->content );

is( $user_without_organization_json->{status}, 1, 'Status success.' );
is( scalar @{ $user_without_organization_json->{data}->{organizations} },
    0, 'This user does not belong to any organization' );

is( $user_without_organization_json->{_hidden_data},
    undef, 'Non admin users do no receive hidden data' );

done_testing();
