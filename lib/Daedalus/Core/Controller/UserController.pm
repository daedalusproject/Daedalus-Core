package Daedalus::Core::Controller::UserController;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Daedalus::Core::Controller::UserController - Catalyst Controller

=head1 DESCRIPTION

User Controller.

This controller manages User methods like register new users, list users, etc

All methods are private, public request comes from REST controller.

=head1 METHODS

=cut

=head2 createUser

Creates a new user

=cut

sub createUser : Private {
    my ( $self, $c, $user_info ) = @_;

    # Check if user already exists
    my $user =
      $c->model('CoreRealms::User')->find( { email => $user_info->{email} } );

    if ($user) {
        die("user exists.\n");
    }
    else {
        die("User does not exist\n");
    }
}

=head2 confirmUserRegistration

Users are invited by Daedalus Organization, users will recive an e-mail contianing an URL like
/confrimregister/AUTH_TOKEN.

=cut

sub confirmUserRegistration : Private {
    my ( $self, $c, $auth_token ) = @_;

    # Find if user exists

    die("Token is $auth_token");
}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
