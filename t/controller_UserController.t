use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::UserController;

ok( request('/usercontroller')->is_success, 'Request should succeed' );
done_testing();
