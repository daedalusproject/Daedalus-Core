package Daedalus::Core::Schema::CoreRealms::Result::Organization;
use utf8;

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

=item * L<DBIx::Class::InflateColumn::DateTime|DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

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

=head2 token

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 33

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
        default_value => qw(),
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
    "token",
    {
        data_type     => "varchar",
        default_value => qw(),
        is_nullable   => 0,
        size          => 33
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

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup|OrganizationGroup>

=cut

__PACKAGE__->has_many(
    "organization_groups",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationGroup",
    { "foreign.organization_id" => "self.id" },
    { cascade_copy              => 0, cascade_delete => 0 },
);

=head2 organization_share_project_organization_owners

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProject|OrganizationShareProject>

=cut

__PACKAGE__->has_many(
    "organization_share_project_organization_owners",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProject",
    { "foreign.organization_owner_id" => "self.id" },
    { cascade_copy                    => 0, cascade_delete => 0 },
);

=head2 organization_share_project_organizations_to_manage

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProject|OrganizationShareProject>

=cut

__PACKAGE__->has_many(
    "organization_share_project_organizations_to_manage",
    "Daedalus::Core::Schema::CoreRealms::Result::OrganizationShareProject",
    { "foreign.organization_to_manage_id" => "self.id" },
    { cascade_copy                        => 0, cascade_delete => 0 },
);

=head2 projects

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::Project|Project>

=cut

__PACKAGE__->has_many(
    "projects",
    "Daedalus::Core::Schema::CoreRealms::Result::Project",
    { "foreign.organization_owner" => "self.id" },
    { cascade_copy                 => 0, cascade_delete => 0 },
);

=head2 user_organizations

Type: has_many

Related object: L<Daedalus::Core::Schema::CoreRealms::Result::UserOrganization|UserOrganization>

=cut

__PACKAGE__->has_many(
    "user_organizations",
    "Daedalus::Core::Schema::CoreRealms::Result::UserOrganization",
    { "foreign.organization_id" => "self.id" },
    { cascade_copy              => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07048 @ 2019-07-08 06:29:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AObfm3M6ww8wh5S7rd24YA
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

__PACKAGE__->add_columns(
    'modified_at',
    {
        %{ __PACKAGE__->column_info('modified_at') },
        set_on_create => 1,
        set_on_update => 1
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
