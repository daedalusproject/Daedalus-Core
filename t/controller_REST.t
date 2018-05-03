use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

ok( request('/rest')->is_success, 'Request should succeed' );
done_testing();
