package Daedalus::Organizations::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Organizations::Manager

=cut

use strict;
use warnings;
use Moose;

use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::Organizations::Manager

=cut

=head1 DESCRIPTION

Daedalus Organizations Manager

=head1 METHODS

=cut

=head2 createOrganization

Creates a new Organization

=cut

sub createOrganization {

    my $request = shift;
    my $model   = $request->{model};

    my $organization_data = $request->{request}->{data}->{organization_data};

    # Create Organization
    $request->model('CoreRealms::Organization')
      ->create( { name => $organization_data->{name} } );

}
__PACKAGE__->meta->make_immutable;
1;
