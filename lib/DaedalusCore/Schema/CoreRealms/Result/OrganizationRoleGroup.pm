use utf8;

package DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroup

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp" );

=head1 TABLE: C<organization_role_groups>

=cut

__PACKAGE__->table("organization_role_groups");

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

=head2 role_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

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
        default_value => "",
        is_nullable   => 0,
        size          => 255
    },
    "role_id",
    {
        data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization

Type: belongs_to

Related object: L<DaedalusCore::Schema::CoreRealms::Result::Organization>

=cut

__PACKAGE__->belongs_to(
    "organization",
    "DaedalusCore::Schema::CoreRealms::Result::Organization",
    { id            => "organization_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 organization_role_groups_projects

Type: has_many

Related object: L<DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroupsProject>

=cut

__PACKAGE__->has_many(
    "organization_role_groups_projects",
    "DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroupsProject",
    { "foreign.organization_manager_id" => "self.organization_id" },
    { cascade_copy                      => 0, cascade_delete => 0 },
);

=head2 role

Type: belongs_to

Related object: L<DaedalusCore::Schema::CoreRealms::Result::Role>

=cut

__PACKAGE__->belongs_to(
    "role",
    "DaedalusCore::Schema::CoreRealms::Result::Role",
    { id            => "role_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-05-08 20:50:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kEPdlT1FNfXqA47TGR4B9Q

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
