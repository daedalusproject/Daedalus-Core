use utf8;

package DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroupsProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroupsProject

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

=head1 TABLE: C<organization_role_groups_project>

=cut

__PACKAGE__->table("organization_role_groups_project");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 organization_manager_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 project_id

  data_type: 'bigint'
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
    "organization_manager_id",
    {
        data_type      => "bigint",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization_manager

Type: belongs_to

Related object: L<DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroup>

=cut

__PACKAGE__->belongs_to(
    "organization_manager",
    "DaedalusCore::Schema::CoreRealms::Result::OrganizationRoleGroup",
    { organization_id => "organization_manager_id" },
    { is_deferrable   => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 project

Type: belongs_to

Related object: L<DaedalusCore::Schema::CoreRealms::Result::Project>

=cut

__PACKAGE__->belongs_to(
    "project",
    "DaedalusCore::Schema::CoreRealms::Result::Project",
    { id            => "project_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-05-08 20:50:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cDrVRLkJPnQ2NvSwBHyI9A

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
