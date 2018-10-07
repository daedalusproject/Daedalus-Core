use utf8;

package Daedalus::Core::Schema::CoreRealms::Result::UserOrganization;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::UserOrganization

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

=head1 TABLE: C<user_organization>

=cut

__PACKAGE__->table("user_organization");

=head1 ACCESSORS

=head2 organization_id

  data_type: 'bigint'
  default_value: 0
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "organization_id",
    {
        data_type      => "bigint",
        default_value  => 0,
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "user_id",
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
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</organization_id>

=back

=cut

__PACKAGE__->set_primary_key( "user_id", "organization_id" );

=head1 RELATIONS

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

=head2 user

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user",
    "Daedalus::Core::Schema::CoreRealms::Result::User",
    { id            => "user_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-10-07 09:52:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0SGVlJuZsjstfMRSeiOIkg

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
