package Daedalus::Users::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Users::Manager

=cut

use strict;
use warnings;
use Moose;

use Digest::SHA qw(sha512_base64);
use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::Core::Users::Manager

=cut

=head1 DESCRIPTION

Daedalus::Core Users Manager

=head1 METHODS

=cut

=head2 check_user_passwrd

Checks user password, this methods receives submitted user,
user salt and stored password.

=cut

sub check_user_passwrd {

    my $submitted_password = shift;
    my $user_salt          = shift;
    my $user_password      = shift;

    my $password = sha512_base64("$user_salt$submitted_password");

    return 1 if ( $password eq $user_password );
    return 0;

}

=head2 auth_user_using_model

Auths user, returns auth data if submitted credentials match
with database info.
=cut

sub auth_user_using_model {

    my $request = shift;
    my $auth    = $request->{request}->{data}->{auth};
    my $model   = $request->{model};

    my %response;
    $response{status}  => "";
    $response{message} => "";
    $response{data}    => {};

    # Get user from model
    my $user = $model->find( { email => $auth->{email} } );

    if ($user) {
        if (
            !(
                check_user_passwrd(
                    $auth->{password}, $user->salt, $user->password
                )
            )
          )
        {
            $response{status}  = 'Failed';
            $response{message} = 'Wrong e-mail or password.';
        }
        else {
            $response{status}  = 'Success';
            $response{message} = 'Auth Successful.';
        }
    }
    else {
        $response{status}  = 'Failed';
        $response{message} = 'Wrong e-mail or password.';
    }
    return \%response;
}

__PACKAGE__->meta->make_immutable;
1;
