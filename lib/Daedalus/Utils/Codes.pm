package Daedalus::Utils::Codes;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Utils::Codes

=head1 DESCRIPTION

Daedalus Core http codes


=cut

use strict;
use warnings;

use Const::Fast;
use Moose;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(    $bad_request
  $forbidden
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

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;
1;
