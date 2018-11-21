package Daedalus::Utils::Crypt;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Utils::Crypt

=cut

use strict;
use warnings;
use Moose;

use Data::Password::Check;
use String::Random;
use Digest::SHA qw(sha512_base64);
use Crypt::JWT qw(decode_jwt encode_jwt);
use Try::Tiny;

use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 DESCRIPTION

Daedalus Passwords and cryptography utils.

=head1 METHODS

=cut

=head2 check_password

Checks if password is valid

=cut

sub check_password {
    my $password = shift;

    my $response;

    my $pwcheck = Data::Password::Check->check(
        {
            'password'           => $password,
            'min_length'         => 12,
            'diversity_required' => 3,
            'tests' => [ 'length', 'diverse_characters', 'repeated' ],
        }
    );

    if ( $pwcheck->has_errors ) {

        $response->{status} = 0;

        # print the errors
        $response->{message} = join( "|", @{ $pwcheck->error_list } );
    }
    else {
        $response->{status}  = 1;
        $response->{message} = "Provided Password if valid.";
    }

    return $response;
}

=head2 generate_random_string

Generate Random String, lenght is provided.

=cut

sub generate_random_string {
    my $lenght = shift;

    # Generate random strings without dots

    my $generator = String::Random->new;
    $generator->{'A'} = [ @{ $generator->{'C'} }, @{ $generator->{'c'} },
        @{ $generator->{'n'} } ];

    my $string = 'A' x $lenght;

    return $generator->randpattern($string);
}

=head2 hash_password

Returns SHA512 checksum from concatenation of salt + password

=cut

sub hash_password {
    my $password = shift;
    my $salt     = shift;

    return sha512_base64("$salt$password");
}

=head2 create_session_token

Creates JSON Web Token

=cut

sub create_session_token {
    my $session_token_config = shift;
    my $data                 = shift;

    my $key = Crypt::PK::RSA->new( $session_token_config->{rsa_private_key} );
    my $relative_exp = $session_token_config->{relative_exp};

    my $token = encode_jwt(
        payload      => $data,
        key          => $key,
        alg          => 'RS256',
        relative_exp => $relative_exp
    );

    return $token;
}

=head2 retrieve_token_data

Retrieves user data from  JSON Web Token

=cut

sub retrieve_token_data {
    my $c                    = shift;
    my $session_token_config = shift;
    my $session_token        = shift;

    my $retreived_data = { status => 0, };

    my $cached_relative_exp = 0;

    my $public_key =
      Crypt::PK::RSA->new( $session_token_config->{rsa_public_key} );

    try {
        $retreived_data->{status} = 1;
        $retreived_data->{data} =
          decode_jwt( token => $session_token, key => $public_key );
        $cached_relative_exp = $c->cache->get( $retreived_data->{data}->{id} );
        if ($cached_relative_exp) {
            if ( $retreived_data->{data}->{exp} - $cached_relative_exp <= 0 ) {

                $retreived_data->{status}  = 0;
                $retreived_data->{message} = 'Session token inavlid.';
            }
        }

    }
    catch {
        $retreived_data->{status}  = 0;
        $retreived_data->{message} = $_;
    };
    return $retreived_data;
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;
1;
