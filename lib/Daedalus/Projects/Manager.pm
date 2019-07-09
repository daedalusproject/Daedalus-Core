package Daedalus::Projects::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Projects::Manager

=cut

use strict;
use warnings;
use Moose;

use Daedalus::Utils::Crypt;
use List::MoreUtils qw(any uniq);
use Daedalus::Utils::Constants qw(
  $bad_request
  $forbidden
  $organization_token_length
  $organization_group_token_length
);

use namespace::clean -except => 'meta';

our $VERSION = '0.01';

=head1 SYNOPSIS

Daedalus Projects Manager


=head1 DESCRIPTION

Daedalus Projects Manager

=head1 METHODS

=cut

=head2 create_projects

Creates a new Project

=cut

sub create_project {

    my $c               = shift;
    my $organization_id = shift;
    my $project_name    = shift;

    my $response;

    my @pojects_rs =
      $c->model('CoreRealms::Project')
      ->search( { organization_owner => $organization_id } )->all;

    chomp $project_name;
    if ( scalar @pojects_rs > 0 ) {

    }
    else {
        $c->model('CoreRealms::Project');
    }

    return $response;
}

=encoding utf8

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS
=head1 DIAGNOSTICS
=head1 CONFIGURATION AND ENVIRONMENT

If APP_TEST env is enabled, Core reads its configuration from t/ folder, by default config files we be read rom /etc/daedalus-core folder.

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
