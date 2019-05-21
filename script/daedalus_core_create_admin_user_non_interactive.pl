#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME
daedalus_core_create_admin_user_non_interactive.perl - Creates Daedalus Manager Users
=cut

use Daedalus::Core::Schema::CoreRealms;
use Config::ZOMG;
use Email::Valid;
use Term::ReadKey;
use Data::Password::Check;
use Carp;
use String::Random;
use Digest::SHA qw(sha512_base64);

my $username = $ENV{'MYSQL_USER'};
my $password = $ENV{'MYSQL_PASSWORD'};
my $host     = $ENV{'MYSQL_HOST'};
my $port     = $ENV{'MYSQL_PORT'};
my $database = $ENV{'MYSQL_DATABASE'};

my $admin_name     = $ENV{'ADMIN_NAME'};
my $admin_surname  = $ENV{'ADMIN_SURNAME'};
my $admin_email    = $ENV{'ADMIN_EMAIL'};
my $admin_password = $ENV{'ADMIN_PASSWORD'};

my $organization_name = $ENV{'ADMIN_ORGANIZATION_NAME'};

my $succeded_conection = 0;

my $dsn = "DBI:mysql:database=$database;host=$host;port=$port";

my $schema =
  Daedalus::Core::Schema::CoreRealms->connect( $dsn, $username, $password )
  or die "Failed to connect to
database at $dsn";

my $pass     = new String::Random;
my $patern32 = "sssssssssssssssssssssssssssssss";
my $patern64 =
  "sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss";
my $patern256 =
"sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss";

my $api_key    = $pass->randpattern($patern32);
my $auth_token = $pass->randpattern($patern64);
my $salt       = $pass->randpattern($patern256);
$admin_password = sha512_base64("$salt$admin_password");

my $user = $schema->resultset('User')->create(
    {
        name       => $admin_name,
        surname    => $admin_surname,
        email      => $admin_email,
        api_key    => $api_key,
        password   => $admin_password,
        salt       => $salt,
        expires    => "3000-01-01",
        active     => 1,
        auth_token => $auth_token,
    }
);

# Create Roles

my $organization_master_role =
  $schema->resultset('Role')->create( { role_name => "organization_master", } );
$schema->resultset('Role')->create( { role_name => "project_caretaker", } );
$schema->resultset('Role')->create(
    {
        role_name => "health_watcher",
    }
);
$schema->resultset('Role')->create( { role_name => "expenses_watcher", } );
$schema->resultset('Role')->create( { role_name => "maze_master", } );
my $fireman =
  $schema->resultset('Role')->create( { role_name => "fireman", } );
$schema->resultset('Role')->create( { role_name => "fireman_commando", } );
my $daedalus_manager =
  $schema->resultset('Role')->create( { role_name => "daedalus_manager", } );

# Create organization

my $organization = $schema->resultset('Organization')->create(
    {
        name  => $organization_name,
        token => $pass->randpattern($patern32)
    }
);

# admin@daedalus-project.io belongs to ""Daedalus Project"" Organization

$schema->resultset('UserOrganization')->create(
    {
        organization_id => $organization->id,
        user_id         => $user->id,
    }
);

my $organization_group = $schema->resultset('OrganizationGroup')->create(
    {
        organization_id => $organization->id,
        group_name      => "$organization_name Super Administrators",
        token           => $pass->randpattern($patern32),
    }
);

# Daedalus Administrators has the following roles #  daedalus_manager #  organization_master

my $organization_group_role =
  $schema->resultset('OrganizationGroupRole')->create(
    {
        group_id => $organization_group->id,
        role_id  => $daedalus_manager->id,
    }
  );

$schema->resultset('OrganizationGroupRole')->create(
    {
        group_id => $organization_group->id,
        role_id  => $organization_master_role->id,
    }
);

$schema->resultset('OrganizationUsersGroup')->create(
    {
        group_id => $organization_group->id,
        user_id  => $user->id,
    }
);

print "Admin user created.\n";

