#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME
daedalus_core_create_admin_user.perl - Creates Daedalus Manager Users
=cut

use Cwd 'abs_path';
use FindBin qw($Bin);
use Path::Class;
use lib dir( $Bin, '../../', 'lib' )->stringify;

use Daedalus::Core::Schema::CoreRealms;
use Config::ZOMG;
use Email::Valid;
use Term::ReadKey;
use Data::Password::Check;
use Carp;
use String::Random;
use Digest::SHA qw(sha512_base64);

use Data::Dumper;

my $config_filename;

# Call the schema

$config_filename =
  file( $Bin, '..', 'lib', 'daedalus_core_testing.conf' )->stringify;

my $config      = Config::ZOMG->new( file => $config_filename );
my $config_hash = $config->load;
my $dsn         = $config_hash->{'Model::CoreRealms'}->{'connect_info'};
$dsn = $dsn =~ s/__HOME__/$Bin\/..\/../r;

my $schema = Daedalus::Core::Schema::CoreRealms->connect($dsn)
  or die "Failed to connect to database at $dsn";

# Admin user

my $name     = 'Admin';
my $surname  = 'User';
my $email    = 'admin@daedalus-project.io';
my $password = 'this_is_a_Test_1234';
my $api_key  = 'lTuuauLEKCtXhbBVyxfpVHpdodiBaJb';
my $auth_token =
  'gqYyhZWMfPFm9WK6q/XYUVcqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5p';
my $salt =
'lec6bQeaUiJoFQ3zPZiNzfz7D2LDuVkErT11QSJUkcndeGSmCVDNSLJ4O3EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
$password = sha512_base64("$salt$password");

my $user = $schema->resultset('User')->create(
    {
        name       => $name,
        surname    => $surname,
        email      => $email,
        api_key    => $api_key,
        password   => $password,
        salt       => $salt,
        expires    => "3000-01-01",
        active     => "1",
        auth_token => $auth_token,
        is_admin   => 1,
    }
);

# Create Roles

$schema->resultset('Role')->create( { role_name => "organization_master", } );
$schema->resultset('Role')->create(
    {
        role_name => "project_caretaker",
    }
);
$schema->resultset('Role')->create( { role_name => "health_watcher", } );
$schema->resultset('Role')->create( { role_name => "expenses_watcher", } );
$schema->resultset('Role')->create(
    {
        role_name => "maze_master",
    }
);
$schema->resultset('Role')->create( { role_name => "fireman", } );
$schema->resultset('Role')->create( { role_name => "fireman_commando", } );
my $daedalus_manager =
  $schema->resultset('Role')->create( { role_name => "daedalus_manager", } );

# Create organization

my $organization =
  $schema->resultset('Organization')->create( { name => "Daedalus Project", } );

my $organization_group = $schema->resultset('OrganizationGroup')->create(
    {
        organization_id => $organization->id,
        group_name      => "Daedalus Administrators",
    }
);

my $organization_group_role =
  $schema->resultset('OrganizationGroupRole')->create(
    {
        group_id => $organization_group->id,
        role_id  => $daedalus_manager->id,
    }
  );

$schema->resultset('OrgaizationUsersGroup')->create(
    {
        group_id => $organization_group->id,
        user_id  => $user->id,
    }
);

# No admin user

$name       = 'NoAdmin';
$surname    = 'User';
$email      = 'notanadmin@daedalus-project.io';
$password   = 'Test_is_th1s_123';
$api_key    = 'lTluauLErCtXhbBdyxfpVHpdodiBaJb';
$auth_token = 'gqYyhZWMfPFm9WK6q/XYUVcqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
$salt =
'1ec6bQeaUiJoFQ3zPZiNzfz7D2LDuVkErT11QSJUkcndeGSmCVDNSLJ4O3EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
$password = sha512_base64("$salt$password");

$schema->resultset('User')->create(
    {
        name       => $name,
        surname    => $surname,
        email      => $email,
        api_key    => $api_key,
        password   => $password,
        salt       => $salt,
        expires    => "3000-01-01",
        active     => "1",
        auth_token => $auth_token,
        is_admin   => 0,
    }
);

$name       = 'Other Admin';
$surname    = 'User';
$email      = 'yetanotheradmin@daedalus-project.io';
$password   = 'Is a Password_1234';
$api_key    = 'lTluauLErCtXhbBdyxfpVHpdodiBaJb';
$auth_token = 'gqYyhZWMffFm9WK6q/XYUVcqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
$salt =
'1ec6bQeaUiJoFQ3zPZiNzfz7F2LDuVkErT11QSJUkcndeGSmCVDNSLJ4O3EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
$password = sha512_base64("$salt$password");

$schema->resultset('User')->create(
    {
        name       => $name,
        surname    => $surname,
        email      => $email,
        api_key    => $api_key,
        password   => $password,
        salt       => $salt,
        expires    => "3000-01-01",
        active     => "1",
        auth_token => $auth_token,
        is_admin   => 1,
    }
);

$name       = 'Other Admin';
$surname    = 'Again';
$email      = 'adminagain@daedalus-project.io';
$password   = '__:___Password_1234';
$api_key    = 'lTluauLErCtXhbBdyxfpVHpfifoBaJb';
$auth_token = 'gqYyhZWMffFm9WK6q/2376cqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
$salt =
'1ec6bQeaUiJoFQ3zPZiNzfz7F2LDuVkErT11QSJUkcndeGSmCVDNSL1297EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
$password = sha512_base64("$salt$password");

$schema->resultset('User')->create(
    {
        name       => $name,
        surname    => $surname,
        email      => $email,
        api_key    => $api_key,
        password   => $password,
        salt       => $salt,
        expires    => "3000-01-01",
        active     => "1",
        auth_token => $auth_token,
        is_admin   => 1,
    }
);

