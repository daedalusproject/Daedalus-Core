use utf8;

package Daedalus::Core::Schema::CoreRealms::Result::Organization;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::Organization

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

=head1 TABLE: C<organizations>

=cut

__PACKAGE__->table("organizations");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

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
    "name",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 100
    },
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

=head2 organization_groups

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup>

=cut

__PACKAGE__->has_many(
    "organization_groups",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup",
    { "foreign.organization_id" => "self.id" },
    { cascade_copy              => 0, cascade_delete => 0 },
);

=head2 user_organizations

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::UserOrganization>

=cut

__PACKAGE__->has_many(
    "user_organizations",
    "Daedalus::Core::Schema::CoreRealms::Result::UserOrganization",
    { "foreign.organization_id" => "self.id" },
    { cascade_copy              => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-05-11 18:21:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aJZ0DDp8tsOHEA2Gm6SBUg

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp", "Core" );

__PACKAGE__->add_columns(
    'created_at',
    {
        %{ __PACKAGE__->column_info('created_at') },
        set_on_create => 1,
        set_on_update => 0
    }
);

__PACKAGE__->add_columns(
    'modified_at',
    {
        %{ __PACKAGE__->column_info('modified_at') },
        set_on_create => 1,
        set_on_update => 1
    }
);

__PACKAGE__->meta->make_immutable;
1;
