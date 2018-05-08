use utf8;

package DaedalusCore::Schema::CoreRealms::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

DaedalusCore::Schema::CoreRealms::Result::UserRole

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

=head1 TABLE: C<user_role>

=cut

__PACKAGE__->table("user_role");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 modified_at

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "user_id",
    {
        data_type      => "bigint",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "role_id",
    {
        data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "created_at",
    {
        data_type                 => "timestamp",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
    "modified_at",
    {
        data_type                 => "timestamp",
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

=head2 user

Type: belongs_to

Related object: L<DaedalusCore::Schema::CoreRealms::Result::User>

=cut

__PACKAGE__->belongs_to(
    "user",
    "DaedalusCore::Schema::CoreRealms::Result::User",
    { id            => "user_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-05-08 19:01:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ps9D/jJOUVRn0qtMly+cpg

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
