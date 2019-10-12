package Daedalus::Utils::Constants;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Utils::Constants

=head1 DESCRIPTION

Daedalus Core constants

=cut

use 5.026_001;
use strict;
use warnings;

use Const::Fast;
use Moose;

use base qw(Exporter);
our @EXPORT_OK = qw(
  $success
  $bad_request
  $forbidden
  $not_found
  $api_key_length
  $auth_token_length
  $long_random_string_length
  $user_token_length
  $organization_token_length
  $organization_group_token_length
  $project_token_length
);

use namespace::clean -except => 'meta';

our $VERSION = '0.01';

=head1 SYNOPSIS

Daedalus Core Constants

=head1 DESCRIPTION

Daedalus Core Constant variables

=head1 VARIABLES

=head2 Success

HTTP success request code (200)

=cut

const our $success => 200;

=head2 Bad Request

HTTP bad request code (400)

=cut

const our $bad_request => 400;

=head2 Forbidden

HTTP Forbidden code (403)

=cut

const our $forbidden => 403;

=head2 Not found

HTTP not found request code (404)

=cut

const our $not_found => 404;

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

=head2 Project token lenght

Constant that sets projects Token length (32)

=cut

const our $project_token_length => 32;

=head1 METHODS
=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>, L<https://git.daedalus-project.io/daedalusproject/Hermes-Perl?nav_source=navbar|Hermes>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS
=head1 DIAGNOSTICS
=head1 CONFIGURATION AND ENVIRONMENT

/etc/daedalus-core must contain Hermes config.

=head1 DEPENDENCIES

See debian/control

=head1 INCOMPATIBILITIES
=head1 BUGS AND LIMITATIONS
=head1 LICENSE AND COPYRIGHT

Copyright 2018-2019 Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.


=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;
1;
