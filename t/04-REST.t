use v5.26;
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';

use JSON::XS;
use HTTP::Request::Common;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

use Daedalus::Core::Schema::CoreRealms;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

ok( request('/')->is_success, 'Request should succeed' );

my $content = get('/');

is_deeply( $content, 'Enter the maze.' );

$content = get('/anythingnotfound');

ok( $content, 'You\'ve just found a wall.' );

my $not_admin_no_session_token = request( GET '/ping', );

is( $not_admin_no_session_token->code(), 200, );

my $not_admin_no_session_token_json =
  decode_json( $not_admin_no_session_token->content );

is( $not_admin_no_session_token_json->{status}, 'pong', );

done_testing();

DatabaseSetUpTearDown::delete_database();
