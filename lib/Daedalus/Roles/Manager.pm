package Daedalus::Roles::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Roles::Manager

=cut

use 5.026_001;
use strict;
use warnings;
use Moose;
use List::MoreUtils qw(any uniq);

use namespace::clean -except => 'meta';

our $VERSION = '0.01';

=head1 SYNOPSIS

Daedalus Roles Manager


=head1 DESCRIPTION

Daedalus Roles Manager

=head1 SUBROUTINES/METHODS

=cut

=head2 list_roles

Lists available roles

=cut

sub list_roles {
    my $c = shift;

    my $roles = { data => [], _hidden_data => {} };

    my @available_roles =
      $c->model('CoreRealms::Role')
      ->search( { role_name => { 'not in' => ['daedalus_manager'] } } )->all;

    for my $role (@available_roles) {
        push @{ $roles->{data} }, $role->role_name;
        $roles->{_hidden_data}->{ $role->role_name } = { id => $role->id };
    }
    return $roles;
}

=head2 list_roles_by_id

Lists available roles by id

=cut

sub list_roles_by_id {
    my $c = shift;

    my $roles = {};

    my @available_roles =
      $c->model('CoreRealms::Role')
      ->search( { role_name => { 'not in' => ['daedalus_manager'] } } )->all;

    for my $role (@available_roles) {
        $roles->{ $role->id } = $role->role_name;
    }
    return $roles;
}

=head2 check_role_existence

Checks if role name exists

=cut

sub check_role_existence {
    my $c              = shift;
    my $role_candidate = shift;

    my $roles = { data => [], _hidden_data => {} };

    my $response = { status => 1, message => q{} };

    my @available_roles =
      $c->model('CoreRealms::Role')
      ->search( { role_name => { 'not in' => ['daedalus_manager'] } } )->all;

    for my $role (@available_roles) {
        push @{ $roles->{data} }, $role->role_name;
        $roles->{_hidden_data}->{ $role->role_name } = { id => $role->id };
    }

    if ( exists $roles->{_hidden_data}->{$role_candidate} ) {
        $response->{data} = { name => $role_candidate, };
        $response->{_hidden_data} =
          { id => $roles->{_hidden_data}->{$role_candidate}->{id} };
    }
    else {
        $response->{status} = 0;
    }
    return $response;
}

=head2 count_roles

Counts how many roles have "role_name" assigned

=cut

sub count_roles {

    my $c         = shift;
    my $groups    = shift;
    my $role_name = shift;

    my $count = 0;

    for my $group_name ( keys %{$groups} ) {
        if (
            any { /^$role_name$/sxm }
            uniq @{ $groups->{$group_name}->{roles} }
          )

        {
            $count = $count + 1;
        }
    }

    return $count;
}

=encoding utf8

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS
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
