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

Daedalus::Users::Manager

=cut

=head1 DESCRIPTION

Daedalus Users Manager

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

    return $password eq $user_password;
}

=head2 auth_user_using_model

Auths user, returns auth data if submitted credentials match
with database info.
=cut

sub authUserUsingModel {

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
            $response{status}       = 'Success';
            $response{message}      = 'Auth Successful.';
            $response{_hidden_data} = { id => $user->id };
            $response{data}         = {
                email    => $user->email,
                name     => $user->name,
                surname  => $user->surname,
                phone    => $user->phone,
                api_key  => $user->api_key,
                email    => $user->email,
                is_admin => $user->is_admin,
            };
        }
    }
    else {
        $response{status}  = 'Failed';
        $response{message} = 'Wrong e-mail or password.';
    }
    return \%response;
}

=head2 isAdmin

Return if required user is admin.

=cut

sub isAdmin {

    my $user_login_response = shift;
    my $response;

    $response = {
        status       => "Failed",
        message      => "You are not an admin user.",
        imadmin      => "False",
        _hidden_data => $user_login_response->{_hidden_data},
    };

    # Check if logged user is admin
    if ( $user_login_response->{data}->{is_admin} == 1 ) {
        $response->{status}  = "Success";
        $response->{message} = "You are an admin user.";
        $response->{imadmin} = 'True',;
    }

    return $response;

}

sub registerNewUser {
    die "YO";
}

__PACKAGE__->meta->make_immutable;
1;
