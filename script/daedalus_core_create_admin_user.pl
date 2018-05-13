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
use Email::Valid;
use Term::ReadKey;
use Data::Password::Check;
use Carp;
use String::Random;
use Digest::SHA qw(sha512_base64);

# Functions

sub ask_filed {
    my $options = shift;

    my $field;
    my $error = 0;

    my $pwcheck;

    do {
        $error = 0;
        print "$options->{message}: ";
        if ( $options->{secret} ) {

            ReadMode('noecho');
        }

        chomp( $field = <STDIN> );

        if ( $options->{secret} ) {
            ReadMode(0);
            print "\n";
        }
        if ( $options->{field_type} eq "password" ) {
            $pwcheck = Data::Password::Check->check(
                {
                    'password'           => $field,
                    'min_length'         => 12,
                    'diversity_required' => 3,
                    'tests' => [ 'length', 'diverse_characters', 'repeated' ],
                }
            );

            if ( $pwcheck->has_errors ) {

                $error = 1;

                # print the errors
                print( join( "\n", @{ $pwcheck->error_list } ), "\n" );
            }
        }
        elsif ( $options->{field_type} eq "email" ) {
            if ( !( Email::Valid->address($field) ) ) {
                $error = 1;
                print "This does not like an e-mail address.\n";
            }
        }
    } while ($error);

    return $field;

}

sub fill_field {
    my $options = shift;

    my $field;
    my $confirmation_field;
    my $error = 0;

    my $pwcheck;

    if ( !( exists $options->{secret} ) ) {
        $options->{secret} = 0;
    }

    if ( !( exists $options->{field_type} ) ) {
        croak "A filed type has to be provided.\n";
    }

    if ( !( exists $options->{field_name} ) ) {
        croak "A filed name has to be provided.\n";
    }

    if ( !( exists $options->{message} ) ) {
        $options->{message} = "Enter ";
    }

    $field = ask_filed($options);

    if ( $options->{confirmation} ) {
        print "Please, confirm.\n";
        do {
            $confirmation_field = ask_filed($options);
        } while ( $confirmation_field ne $field );
    }

    return $field;
}

# Main

my $config_filename;

# Call the schema

if ( $ENV{APP_TEST} ) {
    $config_filename =
      file( $Bin, '..', 't', 'lib', 'daedalus_core_testing.conf' )->stringify;
}
else { $config_filename = file( $Bin, '..', 'daedalus_core.conf' )->stringify; }

my $config      = Config::ZOMG->new( file => $config_filename );
my $config_hash = $config->load;
my $dsn         = $config_hash->{'Model::CoreRealms'}->{'connect_info'};
$dsn = $dsn =~ s/__HOME__/$Bin\/../r;

my $schema = Daedalus::Core::Schema::CoreRealms->connect($dsn)
  or die "Failed to connect to database at $dsn";

my $name = fill_field(
    {
        field_name   => 'name',
        field_type   => 'name',
        secret       => 0,
        message      => "Enter your Name",
        confirmation => 0,
    }
);

my $surname = fill_field(
    {
        field_name   => 'name',
        field_type   => 'name',
        secret       => 0,
        message      => "Enter your Surname",
        confirmation => 0,
    }
);

my $email = fill_field(
    {
        field_name   => 'e-mail',
        field_type   => 'email',
        secret       => 0,
        message      => "Enter your e-mail address",
        confirmation => 1,
    }
);

my $password = fill_field(
    {
        field_name   => 'password',
        field_type   => 'password',
        secret       => 1,
        message      => "Enter your password",
        confirmation => 1,
    }
);

my $pass     = new String::Random;
my $patern32 = "sssssssssssssssssssssssssssssss";
my $patern64 =
  "sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss";
my $patern256 =
"sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss";

my $apikey     = $pass->randpattern($patern32);
my $auth_token = $pass->randpattern($patern64);
my $salt       = $pass->randpattern($patern256);
$password = sha512_base64("$salt$password");

$schema->resultset('User')->create(
    {
        name       => $name,
        surname    => $surname,
        email      => $email,
        apikey     => $apikey,
        password   => $password,
        salt       => $salt,
        expires    => "3000-01-01",
        active     => "1",
        auth_token => $auth_token,
        is_admin   => 1,
    }
);

print "Admin user created.\n";

