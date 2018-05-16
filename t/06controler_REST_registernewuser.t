use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $registerGETcontent = get('/registernewuser');

is_deeply(
    decode_json($registerGETcontent),
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

my $registerGETcontent = get('/registernewuser');

is_deeply(
    decode_json($registerGETcontent),
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

my $failed_because_no_auth = request(
    POST '/registernewuser',
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

