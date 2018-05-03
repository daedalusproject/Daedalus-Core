#!/usr/bin/env perl
use strict;
use warnings;

## Tell perl which directory CoreRealms is in:

use FindBin qw($Bin);
use lib "$Bin/../lib";

use DaedalusCore::Schema;
