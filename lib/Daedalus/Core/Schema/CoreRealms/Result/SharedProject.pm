package Daedalus::Core::Schema::CoreRealms::Result::SharedProject;
use utf8;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::SharedProject

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

=head1 TABLE: C<shared_projects>

=cut

__PACKAGE__->table("shared_projects");

=head1 ACCESSORS

=head2 organization_to_manage_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 organization_to_manage_role_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 project_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 organization_manager_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 deleted

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "organization_to_manage_id",
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
        is_nullable               => 0,
    },
    "organization_to_manage_role_id",
    {
        data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "project_id",
    {
        data_type      => "bigint",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "organization_manager_id",
    { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
    "deleted",
    { data_type => "tinyint", default_value => 0, is_nullable => 1 },
    "id",
    {
        data_type         => "bigint",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization_to_manage

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::Organization|Organization>

=cut

__PACKAGE__->belongs_to(
    "organization_to_manage",
    "Daedalus::Core::Schema::CoreRealms::Result::Organization",
    { id            => "organization_to_manage_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "CASCADE" },
);

=head2 organization_to_manage_role

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::Role|Role>

=cut

__PACKAGE__->belongs_to(
    "organization_to_manage_role",
    "Daedalus::Core::Schema::CoreRealms::Result::Role",
    { id            => "organization_to_manage_role_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "CASCADE" },
);

=head2 project

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::Project|Project>

=cut

__PACKAGE__->belongs_to(
    "project",
    "Daedalus::Core::Schema::CoreRealms::Result::Project",
    { id            => "project_id" },
    { is_deferrable => 1, on_delete => "NO ACTION", on_update => "CASCADE" },
);

=head2 shared_project_group_assignment

Type: might_have

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::SharedProjectGroupAssignment|SharedProjectGroupAssignment>

=cut

__PACKAGE__->might_have(
    "shared_project_group_assignment",
    "Daedalus::Core::Schema::CoreRealms::Result::SharedProjectGroupAssignment",
    { "foreign.shared_project_id" => "self.id" },
    { cascade_copy                => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2019-10-10 21:21:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:62Ry+H7EKJfrsfOIOb7ZnQ

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

Copyright 2018-2019 Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

1;
