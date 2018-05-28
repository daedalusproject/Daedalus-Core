package Daedalus::Utils::Responses;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Utils::Responsesr

=cut

use strict;
use warnings;
use Moose;

use Daedalus::Users::Manager;
use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 DESCRIPTION

Daedalus Utils for manageing responses.

=head1 METHODS

=cut

=head2

Returns response so far.

=cut

sub processResponse {
    my $c        = shift;
    my $response = shift;

    return $response;
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
