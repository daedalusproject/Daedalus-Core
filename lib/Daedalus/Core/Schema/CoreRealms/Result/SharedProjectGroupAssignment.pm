package Daedalus::Core::Schema::CoreRealms::Result::SharedProjectGroupAssignment;
use utf8;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::SharedProjectGroupAssignment

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime|DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<shared_project_group_assignment>

=cut

__PACKAGE__->table("shared_project_group_assignment");

=head1 ACCESSORS

=head2 shared_project_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 group_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "shared_project_id",
    {
        data_type         => "bigint",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_foreign_key    => 1,
        is_nullable       => 0,
    },
    "group_id",
    {
        data_type      => "bigint",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "created_at",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 1,
    },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<shared_project_id>

=over 4

=item * L</shared_project_id>

=item * L</group_id>

=back

=cut

__PACKAGE__->add_unique_constraint( "shared_project_id",
    [ "shared_project_id", "group_id" ] );

=head1 RELATIONS

=head2 group

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup|OrganizationGroup>

=cut

__PACKAGE__->belongs_to(
    "group",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup",
    { id            => "group_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 shared_project

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::SharedProject|SharedProject>

=cut

__PACKAGE__->belongs_to(
    "shared_project",
    "Daedalus::Core::Schema::CoreRealms::Result::SharedProject",
    { id            => "shared_project_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2020-04-21 21:12:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+8Gkou/Kk8h+1PNG4oDyWw

# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp",
    "Validation", "Core" );

__PACKAGE__->add_columns(
    'created_at',
    {
        %{ __PACKAGE__->column_info('created_at') },
        set_on_create => 1,
        set_on_update => 0
    }
);

__PACKAGE__->meta->make_immutable;

our $VERSION = '0.01';

=encoding utf8

=head1 SYNOPSIS
=head1 DESCRIPTION
=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS
=head1 DIAGNOSTICS
=head1 CONFIGURATION AND ENVIRONMENT
=head1 DEPENDENCIES
=head1 INCOMPATIBILITIES
=head1 BUGS AND LIMITATIONS
=head1 LICENSE AND COPYRIGHT

Copyright 2018-2020 Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

1;
