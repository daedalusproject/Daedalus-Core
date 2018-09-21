use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';

#æuse Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

ok( request('/')->is_success, 'Request should succeed' );

my $content = get('/');

is_deeply( $content, 'Enter the maze.' );

$content = get('/anythingnotfound');

ok( $content, 'You\'ve just found a wall.' );

done_testing();
