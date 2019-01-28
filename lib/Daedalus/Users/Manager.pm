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
use Daedalus::Utils::Crypt;
use Daedalus::Messages::Manager qw(notify_new_user);
use Data::Dumper;

use namespace::clean -except => 'meta';

=head1 NAME

Daedalus::Users::Manager

=cut

=head1 DESCRIPTION

Daedalus Users Manager

=head1 METHODS

=cut

=head2 check_email_valid

Checks if provided user_email is valid.

=cut

sub check_email_valid {

    my $email = shift;

    return Email::Valid->address($email);
}

=head2 check_user_passwrd

Checks user password, this methods receives submitted user,
user salt and stored password.

=cut

sub check_user_passwrd {

    my $submitted_password = shift;
    my $user_salt          = shift;
    my $user_password      = shift;

    my $password =
      Daedalus::Utils::Crypt::hash_password( $submitted_password, $user_salt );

    return $password eq $user_password;
}

=head2 get_user_from_email

Retrieve user data from model using e-mail

=cut

sub get_user_from_email {
    my $c     = shift;
    my $email = shift;

    my $user = $c->model('CoreRealms::User')->find( { 'email' => $email } );

    return $user;
}

=head2 get_user_from_token

Retrieve user data from model using its token

=cut

sub get_user_from_token {
    my $c     = shift;
    my $token = shift;

    my $user = $c->model('CoreRealms::User')->find( { 'token' => $token } );

    return $user;
}

=head2 get_user_from_id

Retrieve user data from model using user id

=cut

sub get_user_from_id {
    my $c       = shift;
    my $user_id = shift;

    my $user = $c->model('CoreRealms::User')->find( { 'id' => $user_id } );

    return $user;
}

sub get_user_data {
    my $c    = shift;
    my $user = shift;

    my $response = { data => {}, _hidden_data => {} };

    $response->{data} = {
        user => {
            'e-mail' => $user->email,
            name     => $user->name,
            surname  => $user->surname,
            phone    => $user->phone,
            api_key  => $user->api_key,
            active   => $user->active,
            token    => $user->token,
        },
    };

    $response->{_hidden_data} = { user => { id => $user->id } };

#if ( $user->active ) { User is always active, innactive ones cannot login, deleted ones are no present in this model
    $response->{data}->{user}->{is_admin} =
      is_admin_of_any_organization( $c, $user->id );
    $response->{_hidden_data}->{user}->{is_super_admin} =
      is_super_admin( $c, $user->id );

    return $response;
}

=head2 get_user_from_token

Retrieve user data from model

=cut

sub get_user_from_session_token {
    my $c = shift;

    my $response = {
        status  => 0,
        message => "",
    };
    my $token_data;
    my $user;
    my $user_data;

    my ( $session_token_name, $session_token ) =
      $c->req->headers->authorization_basic;

    if ( ( !$session_token_name ) or ( !$session_token ) ) {
        $response->{message} = "No session token provided.";
    }
    else {
        if ( $session_token_name ne "session_token" ) {
            $response->{message} = "No session token provided.";
        }
        else {
            $token_data =
              Daedalus::Utils::Crypt::retrieve_token_data( $c,
                $c->config->{authTokenConfig},
                $session_token );
            if ( $token_data->{status} != 1 ) {
                $response->{status} = 0;
                if ( $token_data->{message} =~ m/invalid/ ) {
                    $response->{message} = "Session token invalid.";
                }
                else {
                    $response->{message} = "Session token expired.";    #Expired
                }
            }
            else {
                $user = $c->model('CoreRealms::User')
                  ->find( { id => $token_data->{data}->{id} } );

#if ( $user->active == 0 ) { User always is active, if it is deleted, user won't be found.
#$response->{message} = "Session token invalid";
#}
#else {
                $user_data = get_user_data( $c, $user );
                $response->{status} = 1;
                $response->{data}   = $user_data;

                #}
            }
        }
    }

    $response->{error_code} = 400;
    return $response;
}

=head2 is_admin_from_session_token

Gets user form session token and check if its an admin one.
=cut

sub is_admin_from_session_token {
    my $c = shift;

    my $response;

    my $user = get_user_from_session_token($c);

    if ( $user->{status} == 0 ) {
        $response = $user;
        $response->{error_code} = 400;
    }
    else {
        $response->{error_code} = 403;
        if ( $user->{data}->{data}->{user}->{is_admin} ) {
            $response->{status} = 1;
            $response->{data}   = $user->{data};
        }
        else {
            $response->{status}  = 0;
            $response->{message} = "You are not an admin user.";
        }
    }

    return $response;
}

=head2 auth_user

Authorize user, returns user data if submitted credentials match
with database info.
=cut

sub auth_user {

    my $c             = shift;
    my $required_data = shift;

    my $response;
    my $user_data;

    $response->{error_code} = 403;

    # Get user from model
    my $user = get_user_from_email( $c, $required_data->{'e-mail'} );
    if ($user) {
        if (
            !(
                check_user_passwrd(
                    $required_data->{'password'}, $user->salt,
                    $user->password
                )
            )
            || ( $user->active == 0 )
          )
        {
            $response->{status}  = 0;
            $response->{message} = 'Wrong e-mail or password.';
        }
        else {
            $response->{status}  = 1;
            $response->{message} = 'Auth Successful.';
            $user_data = get_user_data( $c, $user );
            $response->{data}         = $user_data->{data};
            $response->{_hidden_data} = $user_data->{_hidden_data};

            $response->{data}->{session_token} =
              Daedalus::Utils::Crypt::create_session_token(
                $c->config->{authTokenConfig},
                {
                    id => $response->{_hidden_data}->{user}->{id},
                }
              );
        }
    }
    else {
        $response->{status}  = 0;
        $response->{message} = 'Wrong e-mail or password.';
    }
    return $response;
}

=head2 is_admin_of_any_organization

Return if required user is admin in any Organization

=cut

sub is_admin_of_any_organization {
    my $c       = shift;
    my $user_id = shift;

    my $is_admin = 0;

    my $organization_master_role_id = $c->model('CoreRealms::Role')
      ->find( { role_name => "organization_master" } )->id;

    my $user_groups = $c->model('CoreRealms::OrgaizationUsersGroup')
      ->search( { 'user_id' => $user_id } );

    my @user_groups_array = $user_groups->all;
    for my $user_group (@user_groups_array) {

        # Get group
        my $group_id    = $user_group->group_id;
        my @roles_array = $c->model('CoreRealms::OrganizationGroupRole')
          ->search( { group_id => $group_id } )->all();
        my $roles = "";
        foreach (@roles_array) {

            if ( $_->role_id == $organization_master_role_id ) {
                $is_admin = 1;    #Break all
            }
        }
    }

    return $is_admin;

}

=head2 is_organization_member

Return if required user is member of required Organization

=cut

sub is_organization_member {
    my $c               = shift;
    my $user_id         = shift;
    my $organization_id = shift;

    my $response;

    $response->{status}  = 0;
    $response->{message} = "User is not a memeber of this organization";

    my $organization_member = $c->model('CoreRealms::UserOrganization')
      ->find( { user_id => $user_id, organization_id => $organization_id } );

    if ($organization_member) {
        $response->{status}  = 1;
        $response->{message} = "User is a memeber of this organization";
    }

    return $response;

}

=head2 is_super_admin

Return if required user belongs to a group with 'daedalus_manager'role, user id is provided

=cut

sub is_super_admin {

    my $c       = shift;
    my $user_id = shift;

    my $is_super_admin           = 0;
    my $daedalus_manager_role_id = $c->model('CoreRealms::Role')
      ->find( { role_name => "daedalus_manager" } )->id;

    my $user_groups = $c->model('CoreRealms::OrgaizationUsersGroup')
      ->search( { 'user_id' => $user_id } );

    #if ($user_groups) {
    my @user_groups_array = $user_groups->all;
    for my $user_group (@user_groups_array) {

        # Get group
        my $group_id    = $user_group->group_id;
        my @roles_array = $c->model('CoreRealms::OrganizationGroupRole')
          ->search( { group_id => $group_id } )->all();
        my $roles = "";
        foreach (@roles_array) {

            if ( $_->role_id == $daedalus_manager_role_id ) {
                $is_super_admin = 1;    #Break all
            }

        }
    }

    return $is_super_admin;

}

=head2 register_new_user

Register a new user.

=cut

sub register_new_user {

    my $c                   = shift;
    my $admin_user_data     = shift;
    my $requested_user_data = shift;

    my $registrator_user_id = $admin_user_data->{_hidden_data}->{user}->{id};

    my $response = { status => 1, message => "" };

    my $user_model = $c->model('CoreRealms::User');
    my $user =
      $user_model->find( { 'email' => $requested_user_data->{'e-mail'} } );
    if ($user) {
        $response->{status}  = 0;
        $response->{message} = "There already exists a user using this e-mail.";

    }
    else {
        #
        # Create a user
        my $api_key    = Daedalus::Utils::Crypt::generate_random_string(32);
        my $auth_token = Daedalus::Utils::Crypt::generate_random_string(63);
        my $salt       = Daedalus::Utils::Crypt::generate_random_string(256);
        my $password   = Daedalus::Utils::Crypt::generate_random_string(256);
        my $user_token = Daedalus::Utils::Crypt::generate_random_string(32);
        $password = Daedalus::Utils::Crypt::hash_password( $password, $salt );

        my $registered_user = $user_model->create(
            {
                name       => $requested_user_data->{'name'},
                surname    => $requested_user_data->{'surname'},
                email      => $requested_user_data->{'e-mail'},
                api_key    => $api_key,
                password   => $password,
                salt       => $salt,
                expires    => "3000-01-01",                        #Change it
                active     => 0,
                auth_token => $auth_token,
                token      => $user_token,
            }
        );

        # Who registers who
        my $registered_users_model = $c->model('CoreRealms::RegisteredUser');

        my $user_registered = $registered_users_model->create(
            {
                registered_user  => $registered_user->id,
                registrator_user => $registrator_user_id,
            }
        );

        $response->{status} = 1;

        $response->{message} = "User has been registered.";

        $response->{_hidden_data} = {
            new_user => {
                'e-mail'   => $registered_user->email,
                auth_token => $registered_user->auth_token,
                id         => $registered_user->id,
            },
        };

        $response->{data} = {
            new_user => {
                token => $registered_user->token,
            },
        };

        # Send notification to new user
        notify_new_user(
            $c,
            {
                'e-mail'   => $registered_user->email,
                auth_token => $registered_user->auth_token,
                name       => $registered_user->name,
                surname    => $registered_user->surname
            }
        );
    }

    return $response;
}

=head2 show_registered_users

Register a new user.

=cut

sub show_registered_users {

    my $c               = shift;
    my $admin_user_data = shift;

    my $registrator_user_id = $admin_user_data->{_hidden_data}->{user}->{id};

    my $response = { status => 1, message => "" };

    my $user_model = $c->model('CoreRealms::RegisteredUser');

    my @array_registered_users =
      $user_model->search( { registrator_user => $registrator_user_id } )
      ->all();

    my $users = {
        data         => { registered_users => {} },
        _hidden_data => { registered_users => {} }
    };
    my $user;

    for my $registered_user (@array_registered_users) {
        $user = {
            data => {
                registered_user => {
                    'e-mail' => $registered_user->registered_user->email,
                    name     => $registered_user->registered_user->name,
                    surname  => $registered_user->registered_user->surname,
                    active   => $registered_user->registered_user->active,
                    is_admin => is_admin_of_any_organization(
                        $c, $registered_user->registered_user->id
                    ),
                    token => $registered_user->registered_user->token,
                },
            },
            _hidden_data => {
                registered_user => {
                    id         => $registered_user->registered_user->id,
                    auth_token => $registered_user->registered_user->auth_token,
                    is_super_admin => is_super_admin(
                        $c, $registered_user->registered_user->id
                    ),
                },
            },
        };
        $users->{data}->{registered_users}
          ->{ $user->{data}->{registered_user}->{'e-mail'} } =
          $user->{data}->{registered_user};
        $users->{_hidden_data}->{registered_users}
          ->{ $user->{data}->{registered_user}->{'e-mail'} } =
          $user->{_hidden_data}->{registered_user};
    }

    $response->{data}         = $users->{data};
    $response->{_hidden_data} = $users->{_hidden_data};

    $response->{status} = 1;

    return $response;
}

=head2 confirm_registration

Check auth token and activates inactive users

=cut

sub confirm_registration {
    my $c             = shift;
    my $required_data = shift;

    my $response = {
        status     => 0,
        message    => 'Invalid Auth Token.',
        error_code => 400
    };
    my $auth_token = $required_data->{auth_token};
    if ( length($auth_token) == 63 ) {    # auth token lenght

        #find user
        my $user_model = $c->model('CoreRealms::User');
        my $user =
          $user_model->find( { active => 0, auth_token => $auth_token } );
        if ($user) {
            if ( !$required_data->{password} ) {
                $response->{message} =
                  'Valid Auth Token found, enter your new password.';
            }
            else {
                my $password = $required_data->{password};
                my $password_strenght =
                  Daedalus::Utils::Crypt::check_password($password);
                if ( !$password_strenght->{status} ) {
                    $response->{message} = 'Password is invalid.';
                }
                else {
                    # Password is valid
                    my $new_auth_token =
                      Daedalus::Utils::Crypt::generate_random_string(64);
                    my $new_salt =
                      Daedalus::Utils::Crypt::generate_random_string(256);
                    $password =
                      Daedalus::Utils::Crypt::hash_password( $password,
                        $new_salt );

                    $response->{status}  = 1;
                    $response->{message} = 'Account activated.';

                    $user->update(
                        {
                            password   => $password,
                            salt       => $new_salt,
                            auth_token => $new_auth_token,
                            active     => 1
                        }
                    );
                }
            }
        }
    }
    return $response;
}

=head2 show_active_users

List users, show active ones.

=cut

sub show_active_users {

    my $c               = shift;
    my $admin_user_data = shift;

    my $registered_users_respose =
      show_registered_users( $c, $admin_user_data );

    my $response;

    my $registered_users_data =
      $registered_users_respose->{data}->{registered_users};

    my @active_user_email =
      map { $registered_users_data->{$_}->{active} == 1 ? ($_) : () }
      keys %$registered_users_data;

    $response = {
        status       => 1,
        data         => { active_users => {} },
        _hidden_data => { active_users => {} }
    };

    for my $user_email (@active_user_email) {
        $response->{data}->{active_users}->{$user_email} =
          $registered_users_respose->{data}->{registered_users}->{$user_email};
        $response->{_hidden_data}->{active_users}->{$user_email} =
          $registered_users_respose->{_hidden_data}->{registered_users}
          ->{$user_email};
    }

    return $response;
}

=head2 show_inactive_users

List users, show inactive ones.

=cut

sub show_inactive_users {

    my $c               = shift;
    my $admin_user_data = shift;

    my $registered_users_respose =
      show_registered_users( $c, $admin_user_data );

    my $response;

    my $registered_users_data =
      $registered_users_respose->{data}->{registered_users};

    my @inactive_user_email =
      map { $registered_users_data->{$_}->{active} == 0 ? ($_) : () }
      keys %$registered_users_data;

    $response = {
        status       => 1,
        data         => { inactive_users => {} },
        _hidden_data => { inactive_users => {} }
    };

    for my $user_email (@inactive_user_email) {
        $response->{data}->{inactive_users}->{$user_email} =
          $registered_users_respose->{data}->{registered_users}->{$user_email};
        $response->{_hidden_data}->{inactive_users}->{$user_email} =
          $registered_users_respose->{_hidden_data}->{registered_users}
          ->{$user_email};
    }

    return $response;
}

=head2 get_organization_userss

Get users of given organization

=cut

sub get_organization_users {

    my $c               = shift;
    my $organization_id = shift;
    my $is_super_admin  = shift;

    my $response = {
        status => 1,
        data   => {
            users => {},
        },
    };

    if ($is_super_admin) {
        $response->{_hidden_data} = { users => {} };
    }

    my @organization_users = $c->model('CoreRealms::UserOrganization')
      ->search( { 'organization_id' => $organization_id } )->all();

    for my $organization_user (@organization_users) {
        my $user = $c->model('CoreRealms::User')
          ->find( { 'id' => $organization_user->user_id } );

        # There are always almost one user here
        #if ( !exists( $response->{data}->{users}->{ $user->email } ) ) {
        $response->{data}->{users}->{ $user->email } = {
            'e-mail' => $user->email,
            name     => $user->name,
            surname  => $user->surname,
            phone    => $user->phone,
        };

        if ($is_super_admin) {
            $response->{_hidden_data}->{users}->{ $user->email } = {
                id          => $user->id,
                created_at  => $user->created_at->strftime('%Y-%m-%d %H:%M'),
                modified_at => $user->modified_at->strftime('%Y-%m-%d %H:%M'),
                expires     => $user->expires->strftime('%Y-%m-%d %H:%M'),
            };
        }

        #}
    }
    return $response;
}

=head2 show_orphan_users

List users, show orphan ones.

=cut

sub show_orphan_users {
    my $c               = shift;
    my $admin_user_data = shift;

    my $registered_users_respose =
      show_registered_users( $c, $admin_user_data );

    my $response = {
        data         => { orphan_users => {} },
        _hidden_data => { orphan_users => {} }
    };

    my $registered_users_data =
      $registered_users_respose->{data}->{registered_users};

    my $registered_users_hidden_data =
      $registered_users_respose->{_hidden_data}->{registered_users};

    for my $user_email ( keys %$registered_users_hidden_data ) {
        if ( $registered_users_data->{$user_email}->{active} == 1 ) {
            if (
                scalar(
                    $c->model('CoreRealms::UserOrganization')->search(
                        {
                            'user_id' =>
                              $registered_users_hidden_data->{$user_email}->{id}
                        }
                    )->all()
                ) == 0
              )
            {
                $response->{data}->{orphan_users}->{$user_email} =
                  $registered_users_data->{$user_email};
                $response->{_hidden_data}->{orphan_users}->{$user_email} =
                  $registered_users_hidden_data->{$user_email};
            }
        }

    }

    $response->{status} = 1;

    return $response;
}

=head2 remove_user

Removes selected user.

=cut

sub remove_user {
    my $c         = shift;
    my $user_data = shift;

    my $user_id = $user_data->{_hidden_data}->{user}->{id};

    my $user_group = $c->model('CoreRealms::OrgaizationUsersGroup')->find(
        {
            user_id => $user_id
        }
    );

    $user_group->delete() if ($user_group);

    my $user_organization = $c->model('CoreRealms::UserOrganization')->find(
        {
            user_id => $user_id
        }
    );

    $user_organization->delete() if ($user_organization);

    my $registrator_user = $c->model('CoreRealms::RegisteredUser')->find(
        {
            registrator_user => $user_id
        }
    );

    #Daedalus-Core admin becomes registrator

    $registrator_user->update( { registrator_user => 1 } )
      if ($registrator_user);

    my $registered_user = $c->model('CoreRealms::RegisteredUser')->find(
        {
            registered_user => $user_id
        }
    );

    $registered_user->delete() if ($registered_user);

    my $user = $c->model('CoreRealms::User')->find(
        {
            id => $user_id
        }
    )->delete();

}

=head2 update_user_data

Updates user data

=cut

sub update_user_data {
    my $c              = shift;
    my $user_data      = shift;
    my $data_to_update = shift;

    $c->model('CoreRealms::User')->find(
        {
            id => $user_data->{_hidden_data}->{user}->{id},
        }
    )->update($data_to_update);

}

=encoding utf8

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

__PACKAGE__->meta->make_immutable;
1;
