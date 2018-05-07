use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::UserController;

Daedalus::Core::Controller::UserController->createUser(
    { email => 'foo@domain.com' } );

done_testing();
