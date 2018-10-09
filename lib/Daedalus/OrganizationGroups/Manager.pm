package Daedalus::OrganizationGroups::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::OrganizationGroups::Manager

=cut

use strict;
use warnings;
use Moose;

use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::OrganizationGroups::Manager

=cut

=head1 DESCRIPTION

Daedalus Organization Groups Manager

=head1 METHODS

=cut

=head2 count_roles

Counts how many roles have "role_name" assigned

=cut

sub count_roles {

    my $c         = shift;
    my $groups    = shift;
    my $role_name = shift;

    my $count = 0;

    for my $group_name ( keys %{$groups} ) {
        if ( grep( /^$role_name$/, @{ $groups->{$group_name}->{roles} } ) ) {
            $count = $count + 1;
        }
    }

    return $count;
}

__PACKAGE__->meta->make_immutable;
1;
