package Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole;
use utf8;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole

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

=head1 TABLE: C<organization_group_roles>

=cut

__PACKAGE__->table("organization_group_roles");

=head1 ACCESSORS

=head2 group_id

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

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "group_id",
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
        data_type                 => "datetime",
        datetime_undef_if_invalid => 1,
        is_nullable               => 0,
    },
);

=head1 PRIMARY KEY

=over 4

=item * L</role_id>

=item * L</group_id>

=back

=cut

__PACKAGE__->set_primary_key( "role_id", "group_id" );

=head1 RELATIONS

=head2 group

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup|OrganizationGroup>

=cut

__PACKAGE__->belongs_to(
    "group",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup",
    { id            => "group_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

=head2 role

Type: belongs_to

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::Role|Role>

=cut

__PACKAGE__->belongs_to(
    "role",
    "Daedalus::Core::Schema::CoreRealms::Result::Role",
    { id            => "role_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2019-07-08 06:29:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mhX2SYy1ul09h0ptc/8XKQ

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
