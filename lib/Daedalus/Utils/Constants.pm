package Daedalus::Utils::Constants;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Utils::Constants

=head1 DESCRIPTION

Daedalus Core constants

=cut

use strict;
use warnings;

use Const::Fast;
use Moose;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  $bad_request
  $forbidden
  $api_key_length
  $auth_token_length
  $long_random_string_length
  $user_token_length
  $organization_token_length
  $organization_group_token_length
);

use namespace::clean -except => 'meta';

=head1 VARIABLES

=head2 BAD_REQUEST

HTTP bad request code (400)

=cut

const our $bad_request => 400;

=head2 Forbidden

HTTP Forbidden code (403)

=cut

const our $forbidden => 403;

=head2 API key lenght

Constant that sets API length (32)

=cut

const our $api_key_length => 32;

=head2 Auth Token lenght

Constant that sets Auth token length (32)

=cut

const our $auth_token_length => 63;

=head2 Long random string lenght

Constant that sets long random string length (256)

=cut

const our $long_random_string_length => 256;

=head2 User token lenght

Constant that sets User Token length (32)

=cut

const our $user_token_length => 32;

=head2 Organization token lenght

Constant that sets organization Token length (32)

=cut

const our $organization_token_length => 32;

=head2 Organization group token lenght

Constant that sets organization group Token length (32)

=cut

const our $organization_group_token_length => 32;

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;
1;
