package Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup;
use utf8;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup

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

=head1 TABLE: C<organization_groups>

=cut

__PACKAGE__->table("organization_groups");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 organization_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 group_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 token

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "bigint",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "organization_id",
    {
        data_type      => "bigint",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "group_name",
    {
        data_type     => "varchar",
        default_value => q{},
        is_nullable   => 0,
        size          => 255
    },
    "created_at",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "token",
    {
        data_type     => "varchar",
        default_value => q{},
        is_nullable   => 0,
        size          => 32
    },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_token>

=over 4

=item * L</token>

=back

=cut

__PACKAGE__->add_unique_constraint( "unique_token", ["token"] );

=head1 RELATIONS

=head2 organization

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::Organization|Organization>

=cut

__PACKAGE__->belongs_to(
    "organization",
    "Daedalus::Core::Schema::CoreRealms::Result::Organization",
    { id            => "organization_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 organization_group_roles

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole|OrganizationGroupRole>

=cut

__PACKAGE__->has_many(
    "organization_group_roles",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole",
    { "foreign.group_id" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 organization_users_groups

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationUsersGroup|OrganizationUsersGroup>

=cut

__PACKAGE__->has_many(
    "organization_users_groups",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationUsersGroup",
    { "foreign.group_id" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 shared_project_group_assignments

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::SharedProjectGroupAssignment|SharedProjectGroupAssignment>

=cut

__PACKAGE__->has_many(
    "shared_project_group_assignments",
    "Daedalus::Core::Schema::CoreRealms::Result::SharedProjectGroupAssignment",
    { "foreign.group_id" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2019-10-13 21:23:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+wsiHXF2LhpTIIuEI4jgWQ

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp", "Core" );

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
