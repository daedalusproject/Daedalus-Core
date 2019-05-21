#!/usr/bin/env perl

use strict;
use warnings;
use Try::Tiny;
use DBI;

my $username = $ENV{'MYSQL_USER'};
my $password = $ENV{'MYSQL_PASSWORD'};
my $host     = $ENV{'MYSQL_HOST'};
my $port     = $ENV{'MYSQL_PORT'};
my $database = $ENV{'MYSQL_DATABASE'};

my $conection_retries = int $ENV{'MYSQL_CONECTION_RETRIES'};
my $conection_timeout = int $ENV{'MYSQL_CONECTION_TIMEOUT'};

my $succeded_conection = 0;

my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";

for ( my $i = 0 ; $i < $conection_retries && $succeded_conection == 0 ; $i++ ) {
    try {
        my $myConnection = DBI->connect( $dsn, $username, $password );
        if ($myConnection) {
            $succeded_conection = 1;
            $myConnection->disconnect();
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
