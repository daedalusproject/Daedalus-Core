use strict;
use warnings;
use Test::More;
use Data::Dumper;

use Catalyst::Test 'Daedalus::Core';

#æuse Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

use Data::Dumper;

ok( request('/')->is_success, 'Request should succeed' );

my $content = get('/');

is_deeply( $content, 'Enter the maze.' );

$content = get('/anythingnotfound');

ok( $content, 'You\'ve just found a wall.' );

done_testing();
