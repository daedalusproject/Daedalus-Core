use strict;
use warnings;

use lib './lib';
use Daedalus::Core;

my $app = Daedalus::Core->apply_default_middlewares(Daedalus::Core->psgi_app);
$app;
