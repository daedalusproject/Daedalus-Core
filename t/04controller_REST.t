use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS 'decode_json';

ok( request('/ping')->is_success, 'Request should succeed' );

my $content      = get('/ping');
my $ping_content = decode_json($content);

is_deeply( $ping_content->{'status'}, 'pong' );
done_testing();
