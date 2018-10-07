use utf8;

package Daedalus::Core::Schema::CoreRealms::Result::RegisteredUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::RegisteredUser

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

=head1 TABLE: C<registered_users>

=cut

__PACKAGE__->table("registered_users");

=head1 ACCESSORS

=head2 registered_user

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 registrator_user

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
    "registered_user",
    {
        data_type      => "bigint",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "registrator_user",
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

=item * L</registered_user>

=item * L</registrator_user>

=back

=cut

__PACKAGE__->set_primary_key( "registered_user", "registrator_user" );

=head1 RELATIONS

=head2 registered_user

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::User>

=cut

__PACKAGE__->belongs_to(
    "registered_user",
    "Daedalus::Core::Schema::CoreRealms::Result::User",
    { id            => "registered_user" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 registrator_user

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::User>

=cut

__PACKAGE__->belongs_to(
    "registrator_user",
    "Daedalus::Core::Schema::CoreRealms::Result::User",
    { id            => "registrator_user" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-10-07 09:52:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QTVcQSHR2nOgFEzNwgWgeA
#
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
1;
