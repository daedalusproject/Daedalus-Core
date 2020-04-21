package Daedalus::Core::Schema::CoreRealms::Result::Role;
use utf8;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Daedalus::Core::Schema::CoreRealms::Result::Role

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

=head1 TABLE: C<roles>

=cut

__PACKAGE__->table("roles");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 role_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 20

=head2 created_at

  data_type: 'datetime'
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
    "role_name",
    {
        data_type     => "varchar",
        default_value => q{},
        is_nullable   => 0,
        size          => 20
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

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_role_name>

=over 4

=item * L</role_name>

=back

=cut

__PACKAGE__->add_unique_constraint( "unique_role_name", ["role_name"] );

=head1 RELATIONS

=head2 organization_group_roles

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole|OrganizationGroupRole>

=cut

__PACKAGE__->has_many(
    "organization_group_roles",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroupRole",
    { "foreign.role_id" => "self.id" },
    { cascade_copy      => 0, cascade_delete => 0 },
);

=head2 shared_projects

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::SharedProject|SharedProject>

=cut

__PACKAGE__->has_many(
    "shared_projects",
    "Daedalus::Core::Schema::CoreRealms::Result::SharedProject",
    { "foreign.organization_to_manage_role_id" => "self.id" },
    { cascade_copy                             => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2020-04-21 21:12:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KYmB2CooMRxLpPtJWGcC5A
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

Copyright 2018-2020 Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

1;
