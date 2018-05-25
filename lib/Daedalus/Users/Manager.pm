package Daedalus::Users::Manager;

=pod
=encoding UTF-8
=head1 NAME

Daedalus::Core::Users::Manager

=cut

use strict;
use warnings;
use Moose;

use Email::Valid;
use String::Random;
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

=head2 authUser

Auths user, returns auth data if submitted credentials match
with database info.
=cut

sub authUser {

    my $c    = shift;
    my $auth = $c->{request}->{data}->{auth};

    my $response;
    $response->{status}  => "";
    $response->{message} => "";
    $response->{data}    => {};

    # Get user from model
    my $user =
      $c->model('CoreRealms::User')->find( { email => $auth->{email} } );

    if ($user) {
        if (
            !(
                check_user_passwrd(
                    $auth->{password}, $user->salt, $user->password
                )
            )
          )
        {
            $response->{status}  = 'Failed';
            $response->{message} = 'Wrong e-mail or password.';
        }
        else {
            $response->{status}  = 'Success';
            $response->{message} = 'Auth Successful.';
            $response->{data}    = {
                'user' => {
                    email    => $user->email,
                    name     => $user->name,
                    surname  => $user->surname,
                    phone    => $user->phone,
                    api_key  => $user->api_key,
                    email    => $user->email,
                    is_admin => $user->is_admin,
                },
            };
            $response->{_hidden_data} = { user => { id => $user->id } };

            # If user is superAdmin remove _hidden_data
            if ( !isSuperAdmin( $c, $response ) ) {
                delete $response->{_hidden_data};
            }
        }
    }
    else {
        $response->{status}  = 'Failed';
        $response->{message} = 'Wrong e-mail or password.';
    }
    return $response;
}

=head2 isAdmin

Return if required user is admin.

=cut

sub isAdmin {

    my $c = shift;

    my $user_auth = authUserUsingModel($c);
    my $response;

    if ( $user_auth->{status} eq "Failed" ) {
        $response = $user_auth;
    }
    else {
        $response = {
            status       => "Failed",
            message      => "You are not an admin user.",
            imadmin      => "False",
            _hidden_data => $user_auth->{_hidden_data},
        };

        # Check if logged user is admin
        if ( $user_auth->{data}->{is_admin} == 1 ) {
            $response->{status}  = "Success";
            $response->{message} = "You are an admin user.";
            $response->{imadmin} = 'True',;
        }
    }
    return $response;

}

=head2 isSuperAdminBy

Return if required user belongs to a group with 'daedalus_manager'role

=cut

sub isSuperAdmin {

    my $c       = shift;
    my $request = shift;

    my $is_super_admin = 0;

    # Check-hidden_data;
    my $find_by_user_id = 0;
    if ( exists( $request->{_hidden_data} ) ) {
        if ( exists( $request->{_hidden_data}->{user} ) ) {
            $find_by_user_id = 1;

            $is_super_admin =
              isSuperAdminById( $c, $request->{_hidden_data}->{user}->{id} );

        }
    }
    if ( $find_by_user_id == 0 ) {
        my $user_admin_response = isAdmin($c);
        if ( $user_admin_response->{status} eq "Success" ) {
            $is_super_admin = isSuperAdminById( $c,
                $user_admin_response->{_hidden_data}->{user}->{id} );
        }
    }
    return $is_super_admin;

}

=head2 isSuperAdminById

Return if required user belongs to a group with 'daedalus_manager'role, user id is provided

=cut

sub isSuperAdminById {

    my $c       = shift;
    my $user_id = shift;

    my $daedalus_manager_role_id = $c->model('CoreRealms::Role')
      ->find( { role_name => "daedalus_manager" } )->id;

    my $user_groups = $c->model('CoreRealms::OrgaizationUsersGroup')
      ->search( { 'user_id' => $user_id } );
    if ($user_groups) {
        my @user_groups_array = $user_groups->all;
        for my $user_group (@user_groups_array) {

            # Get group
            my $group_id    = $user_group->group_id;
            my @roles_array = $c->model('CoreRealms::OrganizationGroupRole')
              ->search( { group_id => $group_id } )->all();
            my $roles = "";

            foreach (@roles_array) {

                if ( $_->role_id == $daedalus_manager_role_id ) {
                    return 1;    #Break all
                }

            }
        }
    }

    return 0;

}

sub registerNewUser {

    my $request         = shift;
    my $admin_user_data = shift;    #hidden_data

    my $response = { status => "Success", message => "", _hidden_data => "" };

    my $requested_user_data = $request->{request}->{data}->{new_user_data};

    my @required_user_data = qw/email name surname/;

    # Check required data
    for my $data (@required_user_data) {
        if ( !( exists $requested_user_data->{$data} ) ) {
            $response->{status} = "Failed";
            $response->{message} .= "No $data supplied.";
        }
        else {
            chomp $requested_user_data->{$data};
        }
    }

    # Check if email is valid
    if ( $response->{status} ne 'Failed' ) {
        if ( !( Email::Valid->address( $requested_user_data->{email} ) ) ) {
            $response->{status}  = "Failed";
            $response->{message} = "Provided e-mail is invalid.";
        }
        else {
            # check if user already exists

            my $user_model = $request->model('CoreRealms::User');
            my $user =
              $user_model->find( { email => $requested_user_data->{email} } );
            if ($user) {
                $response->{status} = "Failed";
                $response->{message} =
                  "There already exists a user using this e-mail.";

            }
            else {
                # Is admin?
                if ( exists $requested_user_data->{is_admin} ) {
                    if ( $requested_user_data->{is_admin} != 0 ) {
                        $requested_user_data->{is_admin} = 1;
                    }
                }
                else {
                    $requested_user_data->{is_admin} = 0;
                }

                # Create a user
                my $pass     = new String::Random;
                my $patern32 = 'sssssssssssssssssssssssssssssss';
                my $patern64 =
'sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss';
                my $patern256 =
'sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss';

                my $api_key    = $pass->randpattern($patern32);
                my $auth_token = $pass->randpattern($patern64);
                my $salt       = $pass->randpattern($patern256);
                my $password   = $pass->randpattern($patern256);
                $password = sha512_base64("$salt$password");

                my $registered_user = $user_model->create(
                    {
                        name       => $requested_user_data->{name},
                        surname    => $requested_user_data->{surname},
                        email      => $requested_user_data->{email},
                        api_key    => $api_key,
                        password   => $password,
                        salt       => $salt,
                        expires    => "3000-01-01",                   #Change it
                        active     => 0,
                        auth_token => $auth_token,
                        is_admin => $requested_user_data->{is_admin},
                    }
                );

                # Who registers who
                my $registered_users_model =
                  $request->model('CoreRealms::RegisteredUser');

                my $user_registered = $registered_users_model->create(
                    {
                        registered_user  => $registered_user->id,
                        registrator_user => $admin_user_data->{id},
                    }
                );

                $response->{status} = "Success";

                if ( $requested_user_data->{is_admin} ) {
                    $response->{message} = "Admin user has been registered.";
                }
                else {
                    $response->{message} = "User has been registered.";
                }

                $response->{_hidden_data} = {
                    email      => $registered_user->email,
                    auth_token => $registered_user->auth_token,
                  }

            }
        }
    }
    return $response;

}

__PACKAGE__->meta->make_immutable;
1;
