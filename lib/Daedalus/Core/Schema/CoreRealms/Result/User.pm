use utf8;

package Daedalus::Core::Schema::CoreRealms::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::User

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

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 email

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 50

=head2 surname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 100

=head2 phone

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 22

=head2 api_key

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 33

=head2 password

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 128

=head2 salt

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 256

=head2 created_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 modified_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 active

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 1

=head2 auth_token

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=head2 is_admin

  data_type: 'tinyint'
  default_value: 0
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
    "email",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 255
    },
    "name",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 50
    },
    "surname",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 100
    },
    "phone",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 1,
        size          => 22
    },
    "api_key",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 33
    },
    "password",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 128
    },
    "salt",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 0,
        size          => 256
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
    "expires",
    {
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "active",
    { data_type => "tinyint", default_value => 1, is_nullable => 1 },
    "auth_token",
    {
        data_type     => "varchar",
        default_value => "",
        is_nullable   => 1,
        size          => 64
    },
    "is_admin",
    { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_email>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint( "unique_email", ["email"] );

=head1 RELATIONS

=head2 orgaization_users_groups

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrgaizationUsersGroup>

=cut

__PACKAGE__->has_many(
    "orgaization_users_groups",
    "Daedalus::Core::Schema::CoreRealms::Result::OrgaizationUsersGroup",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

=head2 registered_users_registered_users

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::RegisteredUser>

=cut

__PACKAGE__->has_many(
    "registered_users_registered_users",
    "Daedalus::Core::Schema::CoreRealms::Result::RegisteredUser",
    { "foreign.registered_user" => "self.id" },
    { cascade_copy              => 0, cascade_delete => 0 },
);

=head2 registered_users_registrator_users

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::RegisteredUser>

=cut

__PACKAGE__->has_many(
    "registered_users_registrator_users",
    "Daedalus::Core::Schema::CoreRealms::Result::RegisteredUser",
    { "foreign.registrator_user" => "self.id" },
    { cascade_copy               => 0, cascade_delete => 0 },
);

=head2 user_organizations

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::UserOrganization>

=cut

__PACKAGE__->has_many(
    "user_organizations",
    "Daedalus::Core::Schema::CoreRealms::Result::UserOrganization",
    { "foreign.user_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-06-24 19:49:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fK+FhSyvGtP4ejanhmVrxQ

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

__PACKAGE__->add_columns(
    'modified_at',
    {
        %{ __PACKAGE__->column_info('modified_at') },
        set_on_create => 1,
        set_on_update => 1
    }
);

__PACKAGE__->meta->make_immutable;
1
