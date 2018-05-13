use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS 'decode_json';

my $registerGETcontent = get('/registernewuser');

is_deeply(
    $registerGETcontent,
    {
        status  => 'failed',
        message => "This method does not support GET requests."
    }
);

done_testing();
