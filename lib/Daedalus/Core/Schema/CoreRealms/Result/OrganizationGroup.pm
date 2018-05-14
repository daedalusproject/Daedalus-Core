use utf8;

package Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup;

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

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=back

=cut

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp" );

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
    "created_at",
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

=head2 orgaization_users_groups

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrgaizationUsersGroup>

=cut

__PACKAGE__->has_many(
    "orgaization_users_groups",
    "Daedalus::Core::Schema::CoreRealms::Result::OrgaizationUsersGroup",
    { "foreign.group_id" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 organization

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::Organization>

=cut

__PACKAGE__->belongs_to(
    "organization",
    "Daedalus::Core::Schema::CoreRealms::Result::Organization",
    { id            => "organization_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 organization_group_roles

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole>

=cut

__PACKAGE__->has_many(
    "organization_group_roles",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole",
    { "foreign.group_id" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-05-13 17:31:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HZq8a2GkyzTAx9zo0L87xw

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
1;