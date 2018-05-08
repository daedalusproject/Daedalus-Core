use utf8;

package Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProject

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

=head1 TABLE: C<organization_share_project>

=cut

__PACKAGE__->table("organization_share_project");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 organization_project_owner_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 organization_to_manage_proect_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 project_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 modified_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
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
    "organization_project_owner_id",
    {
        data_type      => "bigint",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "organization_to_manage_proect_id",
    {
        data_type      => "bigint",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "project_id",
    { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
    "created_at",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "modified_at",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 organization_project_owner

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationProject>

=cut

__PACKAGE__->belongs_to(
    "organization_project_owner",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationProject",
    { id            => "organization_project_owner_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 organization_share_project_roles

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProjectRole>

=cut

__PACKAGE__->has_many(
    "organization_share_project_roles",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProjectRole",
    { "foreign.organization_share_project" => "self.id" },
    { cascade_copy                         => 0, cascade_delete => 0 },
);

=head2 organization_to_manage_proect

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationProject>

=cut

__PACKAGE__->belongs_to(
    "organization_to_manage_proect",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationProject",
    { id            => "organization_to_manage_proect_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-05-08 21:15:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1cYHYBmd4eRMVNiJZibA6w

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
