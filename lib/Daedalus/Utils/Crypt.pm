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

use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 DESCRIPTION

Daedalus Passwords and cryptography utils.

=head1 METHODS

=cut

=head2 checkPassword

Checks if password is valid

=cut

sub checkPassword {
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

=head2 generateRandomString

Generate Random String, lenght is provided.

=cut

sub generateRandomString {
    my $lenght = shift;

    my $string = 's' x $lenght;

    my $random_string = new String::Random;

    return $random_string->randpattern($string);
}

=head2 hashPassword

Returns SHA512 checksum from concatenation of salt + password

=cut

sub hashPassword {
    my $password = shift;
    my $salt     = shift;

    return sha512_base64("$salt$password");
}

sub createAuthToken {
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

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
