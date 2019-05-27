package Daedalus::Utils::Codes;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Utils::Codes

=cut

use strict;
use warnings;
use Const::Fast;

use Exporter;
our @ISA    = qw/ Exporter /;
our @EXPORT = qw/ $bad_request $forbidden /;

=head1 DESCRIPTION

Daedalus Core http codes

=head1 VARIABLES

=head2 BAD_REQUEST

HTTP bad request code (400)

=cut

const my $bad_request => 400;

=head2 Forbidden

HTTP Forbidden code (403)

=cut

const my $forbidden => 403;

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

1;
