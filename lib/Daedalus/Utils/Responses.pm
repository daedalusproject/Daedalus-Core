package Daedalus::Utils::Responses;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Users::Manager

=cut

use strict;
use warnings;
use Moose;

use Daedalus::Users::Manager;
use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::Utils::Responses

=cut

=head1 DESCRIPTION

Daedalus Utils for manageing responses.

=head1 METHODS

=cut

=head2

Checks user password, this methods receives submitted user,
user salt and stored password.

=cut

sub processResponse {
    my $c        = shift;
    my $response = shift;

    #if (Daedalus::Users::Manager::isSuperAdmin($c)){
    #die "Super Admin";
    #}
    #die Dumper($response);
    return $response;
}

__PACKAGE__->meta->make_immutable;
1;
