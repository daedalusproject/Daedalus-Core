package Daedalus::Users::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Users::Manager

=cut

use strict;
use warnings;
use Moose;

use Data::Dumper;

use namespace::clean -except => 'meta';

sub auth_user_using_model {
    my ($data) = shift;

    my $auth = $data->{request}->{auth};

    my %response;
    $response{status}  => "";
    $response{message} => "";
    $response{data}    => {};

    # Get user from model
    my $user = $data->{model}->find( { email => $auth->{username} } );

    if ( !$user ) {
        $response{status}  = 'Failed';
        $response{message} = 'Wrong e-mail or password';
    }
    else {

    }
    return \%response;
}

__PACKAGE__->meta->make_immutable;
1;
