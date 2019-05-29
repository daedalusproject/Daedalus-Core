package Daedalus::Core::Controller::Root;

use Moose;
use namespace::autoclean;

use Daedalus::Utils::Constants qw(
  $success
  $not_found
);

our $VERSION = '0.01';

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => q{} );

=encoding utf-8

=head1 NAME

Daedalus::Core::Controller::Root - Root Controller for Daedalus::Core

=head1 SYNOPSIS

Daedalus::Core Root Controller.

=head1 DESCRIPTION

Basic Controller

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION


=head1 SUBROUTINES/METHODS

=head2 index

The root page (/)

=cut

sub WelcomeEmptyPage : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Enter the maze.');
    $c->response->status($success);
    return;
}

=head2 default

Standard 404 error page

=cut

sub defaultNotFound : Path {
    my ( $self, $c ) = @_;
    $c->response->body('You\'ve just found a wall.');
    $c->response->status($not_found);
    return;
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') { return; }

=encoding utf8

=head1 DIAGNOSTICS
=head1 CONFIGURATION AND ENVIRONMENT
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
