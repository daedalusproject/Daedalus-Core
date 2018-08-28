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
use JSON::XS;
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
    my $c    = shift;
    my $data = shift;

    my $hermes_config = $c->config->{hermes};
    my $base_url      = $c->config->{baseurl}->{value};
    my $confirm_url   = "$base_url/confirmregistration/$data->{auth_token}";
    my $subject =
      "Welcome to Daedalus Project, $data->{name} $data->{surname}.";
    my $body = "Please, confirm your register at $confirm_url";

    my $HERMES = Daedalus::Hermes->new( $hermes_config->{type} );
    my $hermes = $HERMES->new(
        host     => $hermes_config->{host},
        user     => $hermes_config->{user},
        password => $hermes_config->{password},
        port     => $hermes_config->{port},
        queues   => $hermes_config->{queues},
    );

    my $message = {
        emailto => $data->{email},
        subject => $subject,
        body    => $body,
    };

    my $encoded_message = encode_json($message);

    $hermes->validateAndSend(
        { queue => 'daedalus_core_notifications', message => $encoded_message }
    );

    undef $hermes;
    undef $HERMES;
}

__PACKAGE__->meta->make_immutable;
1;
