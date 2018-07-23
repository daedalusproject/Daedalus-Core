package Daedalus::Messages::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Messages::Manager

=cut

use strict;
use warnings;
use Moose;
use Daedalus::Hermes;
use Data::Dumper;
use base qw(Exporter);

our @ISA    = qw(Exporter);
our @EXPORT = qw(notify_new_user);

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::Messages::Manager

=cut

=head1 DESCRIPTION

Daedalus Messages Manager

=head1 METHODS

=cut

=head2 notify_new_user

Send a notification to a new registered user

=cut

sub notify_new_user {
    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
