#!/usr/bin/env perl
package DatabaseSetUpTearDown;

use strict;
use warnings;

=head1 NAME
daedalus_core_create_admin_user.perl - Creates Daedalus Manager Users
=cut

use Cwd 'abs_path';
use FindBin qw($Bin);
use Path::Class;
use lib dir( $Bin, '../../', 'lib' )->stringify;
use lib "$Bin/../lib";

use Daedalus::Core::Schema::CoreRealms;
use Config::ZOMG;
use Email::Valid;
use Term::ReadKey;
use Data::Password::Check;
use Carp;
use String::Random;
use Digest::SHA qw(sha512_base64);

sub create_database {
    my $schema = Daedalus::Core::Schema::CoreRealms->connect(
        "dbi:$ENV{APP_TEST_DATABASE_TYPE}:$ENV{APP_TEST_DATABASE_NAME}",
        $ENV{APP_TEST_DATABASE_USER},
        $ENV{APP_TEST_DATABASE_PASSWORD}
    );

    $schema->deploy();
    populate_databse();

}

sub delete_database {
    if ( $ENV{APP_TEST_DATABASE_TYPE} eq "SQLite" ) {
        unlink $ENV{APP_TEST_DATABASE_NAME};
    }
    else { croak "$ENV{APP_TEST_DATABASE_TYPE} type not managed"; }
}

sub populate_databse {

    my $config_filename =
      file( $Bin, 'lib', 'daedalus_core_testing.conf' )->stringify;

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
    my $user_token = 'gDoGxCkNI0DrItDrOzWKjS5tzCHjJTVO';

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
            token      => $user_token,
        }
    );

    # Create Roles

    my $organization_master_role =
      $schema->resultset('Role')
      ->create( { role_name => "organization_master", } );
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
      $schema->resultset('Role')
      ->create( { role_name => "daedalus_manager", } );

    # Create organization

    my $organization = $schema->resultset('Organization')->create(
        {
            name  => "Daedalus Project",
            token => "FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO"
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
            group_name      => "Daedalus Super Administrators",
            token           => "8B8hl0RNItqemTqYmv4mJgYo6GssPzG8g",
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

    # No admin user

    $name     = 'NoAdmin';
    $surname  = 'User';
    $email    = 'notanadmin@daedalus-project.io';
    $password = 'Test_is_th1s_123';
    $api_key  = 'lTluauLErCtXhbBdyxfpVHpdodiBaJb';
    $auth_token =
      'gqYyhZWMfPFm9WK6q/XYUVcqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
    $salt =
'1ec6bQeaUiJoFQ3zPZiNzfz7D2LDuVkErT11QSJUkcndeGSmCVDNSLJ4O3EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
    $password   = sha512_base64("$salt$password");
    $user_token = 'IXI1VoS8BiIuRrOGS4HEAOBleJVMflfG';

    my $notanadmin = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    $schema->resultset('UserOrganization')->create(
        {
            organization_id => $organization->id,
            user_id         => $notanadmin->id,
        }
    );

    $name     = 'Other Admin';
    $surname  = 'Again';
    $email    = 'adminagain@daedalus-project.io';
    $password = '__:___Password_1234';
    $api_key  = 'lTluauLErCtXhbBdyxfpVHpfifoBaJb';
    $auth_token =
      'gqYyhZWMffFm9WK6q/2376cqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
    $salt =
'1ec6bQeaUiJoFQ3zPZiNzfz7F2LDuVkErT11QSJUkcndeGSmCVDNSL1297EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
    $password   = sha512_base64("$salt$password");
    $user_token = 'ZdKR9o9QCo2qjgWkSfevJCNZUP6Y96vJg';

    my $admin_again = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    my $admin_organization_group =
      $schema->resultset('OrganizationGroup')->create(
        {
            organization_id => $organization->id,
            group_name      => "Daedalus Administrators",
            token           => "Vqt0h0C2j6Z7q0jISTOC67qVSHTtXCGaM",
        }
      );

    $schema->resultset('OrganizationGroupRole')->create(
        {
            group_id => $admin_organization_group->id,
            role_id  => $organization_master_role->id,
        }
    );

    $schema->resultset('OrganizationUsersGroup')->create(
        {
            group_id => $admin_organization_group->id,
            user_id  => $admin_again->id,
        }
    );

    $name     = 'Other Admin';
    $surname  = 'User';
    $email    = 'yetanotheradmin@daedalus-project.io';
    $password = 'Is a Password_1234';
    $api_key  = 'lTluauLErCtXhbBdyxfpVHpdodiBaJb';
    $auth_token =
      'gqYyhZWMffFm9WK6q/XYUVcqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
    $salt =
'1ec6bQeaUiJoFQ3zPZiNzfz7F2LDuVkErT11QSJUkcndeGSmCVDNSLJ4O3EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
    $password   = sha512_base64("$salt$password");
    $user_token = 's8YxNnLdXJfyThrf5TTI7Uw8aeN9mQXO';

    my $yet_another_admin = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    $schema->resultset('OrganizationUsersGroup')->create(
        {
            group_id => $admin_organization_group->id,
            user_id  => $yet_another_admin->id,
        }
    );

    # Create an inactive user

    $name     = 'Inactive';
    $surname  = 'user';
    $email    = 'inactiveuser@daedalus-project.io';
    $password = 'N0b0d7car5_;___';
    $api_key  = 'lTluauLErCtXhbBdyxfpVHrsifoBaJb';
    $auth_token =
      'gqYyhZWMffFm9WK6q/2376cqSoRxOS9EdUBrQnPpUnVB0/Fb/3t1cQXPfIr.X5l';
    $salt =
'1ec6bQeaUiJoFQ3zPZiNzfz7F2LDuVkErT11QSJUkcndeGSmCVDNSL3497EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
    $password   = sha512_base64("$salt$password");
    $user_token = 'h9jVrmdNsjWgKF6nhuzWkQiQwdalQSjF';

    $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 0,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    $name     = 'Admin';
    $surname  = 'User';
    $email    = 'otheradminagain@megashops.com';
    $password = '__::___Password_1234';
    $api_key  = '1TluauLErCtXhbBdyxfpVHpfifoBaJb';
    $auth_token =
      '1qYyhZWMffFm9WK6q/2376cqSoRxOS9EdUBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
    $salt =
'13ec6bQeaUiJoFQ3zPZiNzfz7F2LDuVkErT11QSJUkcndeGSmCVDNSL1297EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
    $password   = sha512_base64("$salt$password");
    $user_token = 'RjZEmVuvbUn9SGc26QQogs9ZaYyQwI9s';

    my $yet_other_user = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    my $yet_other_organization = $schema->resultset('Organization')->create(
        {
            name  => "Mega Shops",
            token => "ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf"
        }
    );

    $schema->resultset('UserOrganization')->create(
        {
            organization_id => $yet_other_organization->id,
            user_id         => $yet_other_user->id,
        }
    );

    my $yet_other_organization_group =
      $schema->resultset('OrganizationGroup')->create(
        {
            organization_id => $yet_other_organization->id,
            group_name      => "Mega Shops Administrators",
            token           => "EC78R91DADJowsNogz16pHnAcEBiQHWBF",
        }
      );

    $schema->resultset('OrganizationGroupRole')->create(
        {
            group_id => $yet_other_organization_group->id,
            role_id  => $fireman->id,
        }
    );

    $schema->resultset('OrganizationGroupRole')->create(
        {
            group_id => $yet_other_organization_group->id,
            role_id  => $organization_master_role->id,
        }
    );

    $schema->resultset('OrganizationUsersGroup')->create(
        {
            group_id => $yet_other_organization_group->id,
            user_id  => $yet_other_user->id,
        }
    );

    $name     = 'No Admin';
    $surname  = 'User';
    $email    = 'noadmin@megashops.com';
    $password = '__;;_12__Password_34';
    $api_key  = '1TluauLErCtXhFddyxfpVHpfifoBaJb';
    $auth_token =
      '1qYyhZWMffFm9WK6q/2376cqSoRxO2222UBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
    $salt =
'13ec6bQeaUiJoFQ3zPZiNzfz7F2LDuVkErT11QSJUkcndeGSmCVDNSL2347EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
    $password   = sha512_base64("$salt$password");
    $user_token = '03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt';

    my $yet_other_no_admin_user = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    $schema->resultset('UserOrganization')->create(
        {
            organization_id => $yet_other_organization->id,
            user_id         => $yet_other_no_admin_user->id,
        }
    );

    $schema->resultset('RegisteredUser')->create(
        {
            registered_user  => $yet_other_no_admin_user->id,
            registrator_user => $yet_other_user->id,
        }
    );

    $name     = 'Marvin';
    $surname  = 'Robot';
    $email    = 'marvin@megashops.com';
    $password = '1_HAT3_MY_L1F3';
    $api_key  = '1TluauLErCtFhFddyxfpVHpfifoBaJb';
    $auth_token =
      '1qYyhZWMikdm9WK6q/2376cqSoRxO2222UBrQnPpUnMC0/Fb/3t1cQXPfIr.X5l';
    $salt =
'13ec6bQeaUiJoFQ3zPZiNzfz7F2LDuWkErT11QSJUkcndeGSmCVDNSL2347EK4ISumABtLoqN3aQz9NKX/J3dBORC3tUKTIkM1zIwYSIUBjn9/fjkdeU2IXnoepKIQ0LucMty4IfrVqbKVtQtaHxqdjnZotPG77W1MvikCSYrmCwTPxSAH5l.6tf9vu9ep9BAZGnbROlMAoGDV5cel.vsOZ9y8z9OUIdZnx.2wRfp0H6MGQlKINdx9FMZ.9NSbxy';
    $password   = sha512_base64("$salt$password");
    $user_token = 'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC';

    my $marvin_megashops = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    $schema->resultset('RegisteredUser')->create(
        {
            registered_user  => $marvin_megashops->id,
            registrator_user => $yet_other_user->id,
        }
    );

    $name       = 'Super';
    $surname    = 'Boos';
    $email      = 'superboos@bugstech.com';
    $password   = '__:bugs:___Password_1234';
    $api_key    = 'uWeG8EgjuOr7KF1iF1r0rMkXnbr7s7h';
    $auth_token = '05oKMasl0GOo2TDu7eNhSpThUAKednH0GdVOsJWGWPjoT4vkLUYmE';
    $salt =
'3TX0jLY5guUpFij2p8CXKjSufn3pWBIVNxzB7q3eqUuHw20pEY0RStUBbmFE6NNsSiL9BrKXhhokAIpI7ImBBqMMjEVi4yTCrZXpXBEA0grRLMTkql2qyi1Dz6G1ya2TDug6EUmNPeGFEIgKhTJmmnQ6g5lReWIn0Mz1uZPl1blgX6y89O9qUtXPKO9xGWzcYRVxnwPntO796g3W8wr49hrF0gqP0noWx9nOPFMlUyYBGLfxwsnowq4877aaXKR';
    $password   = sha512_base64("$salt$password");
    $user_token = 'tqqZW1Xrjw6BAUJo6Y5WqQzBJenxOY9X';

    my $superboss = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    $name     = 'Mini';
    $surname  = 'Boos';
    $email    = 'miniboos@bugstech.com';
    $password = '__:bUgs:___1234';
    $api_key  = 'Nv9iLAlTmiXmBjfNR0Dr42Hnmg707Dnx';
    $auth_token =
      'XJLwWEPti8uuuzHSRvMjAzav46VhQtjRFXnalmBgS8kKcLMAGJVCAr7fPwQ30dth';
    $salt =
'ztbXWmgipKc8GYvCoC2mxYNswAmqT9dRJxJMpCPsLjwsdso9qUTchKvjSxZUjrZuGzx532i13StGHL8UgWYfBChrSBEjTLg70pwcznqEMe30cIyC6fp2wdWmRJcQYtoWPnBN0h2PSggIhKz8rsikPQAJAEakLKaubgDq1r7xoiKQLg85xqKeCi1BKYZXR4HuQ31LljORIHsVYW0ElqwfvN5gt6xsBJtJDJGVl0fligdjPjNAAo2wnW3Gll1sZVM';
    $password   = sha512_base64("$salt$password");
    $user_token = 'ctDKugSeUxg8mqPAJ0uFfl5jzksk1IiP';

    my $miniboss = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    $name     = 'Ultra';
    $surname  = 'Boos';
    $email    = 'ultraboos@bugstech.com';
    $password = '__:bUgs:_ULTR:A__1234';
    $api_key  = '0uIRKa8kWN9TJJU3mA3Jawer1ETbEina';
    $auth_token =
      'vhPMp1BPMSdsiHokuJcgEYDWEunQxgDo4AV1HR0om4Jb6TdBWrSZTW5YsPc3iTzW';
    $salt =
'y2TlG6VXTHhbpLRNFCcwNJCg23p9fjBtJrnFlKQjnjBFHeZc1Gq49rXnhAIWHuZ5n7jWKdmzkOvkOdG1VEVHUuX5aVfTLW3blJU1wo5tfroRaSy8ZkSVTIRbHh8JpUOufR1VlUXgutcJPGvbxQo6qse0J6vftuyz69zBJ7yPUrF59r6KfKCWiZjHK2hY2a7oUmdgkRJFLHGEX6dwKPx99QtUYzDkV4A9pSpURyvYvoKQT05Bxq3yOdT6kw03tl6';
    $password   = sha512_base64("$salt$password");
    $user_token = '2yu2CRQadSjFBf3R2E57X86Yh10XX9wh';

    my $ultraboss = $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );

    my $bugstech_organization = $schema->resultset('Organization')->create(
        {
            name  => "Bugs Tech",
            token => "cnYXfKLhTIgYxX7zHZLYjEAL1k8UhtvW"
        }
    );

    $schema->resultset('UserOrganization')->create(
        {
            organization_id => $bugstech_organization->id,
            user_id         => $superboss->id,
        }
    );

    $schema->resultset('UserOrganization')->create(
        {
            organization_id => $bugstech_organization->id,
            user_id         => $miniboss->id,
        }
    );

    $schema->resultset('UserOrganization')->create(
        {
            organization_id => $bugstech_organization->id,
            user_id         => $ultraboss->id,
        }
    );

    my $bugstech_administrators_group =
      $schema->resultset('OrganizationGroup')->create(
        {
            organization_id => $bugstech_organization->id,
            group_name      => "Bugs Tech Administrators",
            token           => "8JgKXXonBTSkxKRutW1ewC4FbmV0s6FGc",
        }
      );

    $schema->resultset('OrganizationGroupRole')->create(
        {
            group_id => $bugstech_administrators_group->id,
            role_id  => $fireman->id,
        }
    );

    $schema->resultset('OrganizationGroupRole')->create(
        {
            group_id => $bugstech_administrators_group->id,
            role_id  => $organization_master_role->id,
        }
    );

    $schema->resultset('OrganizationUsersGroup')->create(
        {
            group_id => $bugstech_administrators_group->id,
            user_id  => $superboss->id,
        }
    );

    $schema->resultset('OrganizationUsersGroup')->create(
        {
            group_id => $bugstech_administrators_group->id,
            user_id  => $ultraboss->id,
        }
    );

    $schema->resultset('OrganizationUsersGroup')->create(
        {
            group_id => $bugstech_administrators_group->id,
            user_id  => $miniboss->id,
        }
    );

    $schema->resultset('RegisteredUser')->create(
        {
            registered_user  => $miniboss->id,
            registrator_user => $superboss->id,
        }
    );

    $schema->resultset('RegisteredUser')->create(
        {
            registered_user  => $superboss->id,
            registrator_user => $ultraboss->id,
        }
    );

    $name     = 'Orphan';
    $surname  = 'Boos';
    $email    = 'orphanboos@bugstech.com';
    $password = '__:bUgs:_ULTR:A__1234';
    $api_key  = '0uIRKa8kWN9TJJU3mA3Jawer1ETbEina';
    $auth_token =
      'vhPMp1BPMSdsiHokuJcgEYDWEunQxgDo4AV1HR0om4Jb6TdBWrSZTW5YsPc3iTzW';
    $salt =
'y2TlG6VXTHhbpLRNFCcwNJCg23p9fjBtJrnFlKQjnjBFHeZc1Gq49rXnhAIWHuZ5n7jWKdmzkOvkOdG1VEVHUuX5aVfTLW3blJU1wo5tfroRaSy8ZkSVTIRbHh8JpUOufR1VlUXgutcJPGvbxQo6qse0J6vftuyz69zBJ7yPUrF59r6KfKCWiZjHK2hY2a7oUmdgkRJFLHGEX6dwKPx99QtUYzDkV4A9pSpURyvYvoKQT05Bxq3yOdT6kw03tl6';
    $password   = sha512_base64("$salt$password");
    $user_token = 'qQGzQ4X3BBNiSFvEwBhsQZF47FS0v5AP';

    $schema->resultset('User')->create(
        {
            name       => $name,
            surname    => $surname,
            email      => $email,
            api_key    => $api_key,
            password   => $password,
            salt       => $salt,
            expires    => "3000-01-01",
            active     => 1,
            auth_token => $auth_token,
            token      => $user_token,
        }
    );
}

1;
