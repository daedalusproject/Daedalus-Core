package Daedalus::Core::Controller::REST;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Daedalus::Core::Controller::REST - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Daedalus::Core::Controller::REST in REST.');
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
