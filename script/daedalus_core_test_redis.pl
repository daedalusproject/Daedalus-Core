#!/usr/bin/env perl

use strict;
use warnings;
use Try::Tiny;
use Cache::Redis;

my $host = $ENV{'REDIS_HOST'};
my $port = $ENV{'REDIS_PORT'};

my $conection_retries = int $ENV{'REDIS_CONECTION_RETRIES'};
my $conection_timeout = int $ENV{'REDIS_CONECTION_TIMEOUT'};

my $succeded_conection = 0;

for ( my $i = 0 ; $i < $conection_retries && $succeded_conection == 0 ; $i++ ) {
    try {
        my $cache = Cache::Redis->new(
            server    => "$host:$port",
            namespace => '',
        );
        if ($cache) {
            $succeded_conection = 1;
        }
    }
    catch {
        $succeded_conection = 0;
    };
    sleep($conection_timeout);
}

if ( $succeded_conection == 0 ) {
    exit 1;
}
else {
    exit 0;
}
