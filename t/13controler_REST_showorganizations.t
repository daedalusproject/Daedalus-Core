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

# admin@daedalus-project.io is allowd to show its organizations

my $admin_one_organization = request(
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

is( $admin_one_organization->code(), 200, );

my $admin_one_organization_json =
  decode_json( $admin_one_organization->content );

is( $admin_one_organization_json->{status}, 1, 'Status success, admin.' );
is( keys %{ $admin_one_organization_json->{organizations} },
    1, 'There is one active organization' );
done_testing();
