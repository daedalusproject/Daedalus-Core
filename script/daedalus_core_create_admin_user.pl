#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME
daedalus_core_create_admin_user.perl - Creates Daedalus Manager Users
=head1 Format
This script will ask you all required fields.
=cut

use Cwd 'abs_path';
use FindBin qw($Bin);
use Path::Class;
use lib dir( $Bin, '..', 'lib' )->stringify;

use Daedalus::Core::Schema::CoreRealms;
use Config::ZOMG;

my $config_filename = file( $Bin, '..', 'daedalus_core.conf' )->stringify;
my $config      = Config::ZOMG->new( file => $config_filename );
my $config_hash = $config->load;
my $dsn         = $config_hash->{'Model::CoreRealms'}->{'connect_info'};
$dsn = $dsn =~ s/__HOME__/$Bin\/../r;

my $schema = Daedalus::Core::Schema::CoreRealms->connect($dsn)
  or die "Failed to connect to database at $dsn";

print "Enter an e-mail: ";
my $email = <STDIN>;

chomp $email;

#Daedalus::Core::Model::CoreRealms->new({email => $email});

