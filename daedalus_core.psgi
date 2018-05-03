use strict;
use warnings;

use Daedalus::Core;

my $app = Daedalus::Core->apply_default_middlewares(Daedalus::Core->psgi_app);
$app;

