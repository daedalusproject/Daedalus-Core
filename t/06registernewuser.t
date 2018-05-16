use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS 'decode_json';
use HTTP::Request::Common;

my $registerGETcontent = get('/registernewuser');

is_deeply(
    decode_json($registerGETcontent),
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

done_testing();
