use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

my $endpoint = '/user/remove';

my $failed_because_no_user_token =
  request( DELETE $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_user_token->code(), 404, );

my $non_admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'notanadmin@daedalus-project.io',
            password => 'Test_is_th1s_123',
        }
    )
);

is( $non_admin_success->code(), 200, );

my $non_admin_success_json = decode_json( $non_admin_success->content );

is( $non_admin_success_json->{status}, 1, );

my $not_admin_session_token = $non_admin_success_json->{data}->{session_token};

my $not_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$not_admin_session_token", '' );

my $failed_no_token =
  request( DELETE $endpoint, Content_Type => 'application/json', );

is( $failed_no_token->code(), 404, );

my $failed_no_admin = request(
    DELETE "$endpoint/whocaresabouthtisusertoken",
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status},  0, );
is( $failed_no_admin_json->{message}, 'You are not an admin user.', );

my $admin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $admin_success->code(), 200, );

my $admin_success_json = decode_json( $admin_success->content );

is( $admin_success_json->{status}, 1, );

my $admin_session_token = $admin_success_json->{data}->{session_token};

my $admin_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_session_token", '' );

my $superadmin_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'admin@daedalus-project.io',
            password => 'this_is_a_Test_1234',
        }
    )
);

is( $superadmin_success->code(), 200, );

my $superadmin_success_json = decode_json( $superadmin_success->content );

is( $superadmin_success_json->{status}, 1, );

my $superadmin_session_token =
  $superadmin_success_json->{data}->{session_token};

my $superadmin_authorization_basic =
  MIME::Base64::encode( "session_token:$superadmin_session_token", '' );

my $list_users = request(
    GET '/user/showregistered',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $list_users->code(), 200, );

my $list_users_json = decode_json( $list_users->content );

is( $list_users_json->{status}, 1, 'Status success.' );
is( keys %{ $list_users_json->{data}->{registered_users} },
    4, 'This user has registered 4 users for the tiem being.' );

my $failed_non_existent_user = request(
    DELETE "$endpoint/invalidtoken_adddddoiuhjhgjhagds",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_non_existent_user->code(), 400, );

my $failed_non_existent_user_json =
  decode_json( $failed_non_existent_user->content );

is( $failed_non_existent_user_json->{status}, 0, );
is(
    $failed_non_existent_user_json->{message},
    'Requested user does not exists or it has not been registered by you.',
);

my $superadmin_get_active_users = request(
    GET "user/showactive",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

my $superadmin_get_active_users_json =
  decode_json( $superadmin_get_active_users->content );

is( $superadmin_get_active_users_json->{status}, 1, );

my $othernotanadmin_user_token =
  $superadmin_get_active_users_json->{data}->{active_users}
  ->{'othernotanadmin@daedalus-project.io'}->{token};

my $failed_not_my_registered_user = request(
    DELETE "$endpoint/$othernotanadmin_user_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $failed_not_my_registered_user->code(), 400, );

my $failed_not_my_registered_user_json =
  decode_json( $failed_not_my_registered_user->content );

is( $failed_not_my_registered_user_json->{status}, 0, );
is(
    $failed_not_my_registered_user_json->{message},
    'Requested user does not exists or it has not been registered by you.',
);

# Let's test group removal

my $create_group_success = request(
    POST '/organization/creategroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins'
        }
    ),
);

is( $create_group_success->code(), 200, );

my $create_group_success_json = decode_json( $create_group_success->content );

is( $create_group_success_json->{status}, 1, );
is(
    $create_group_success_json->{message},
    'Organization group has been created.',
);

is( $create_group_success_json->{_hidden_data}, undef, );

my $megashops_sysadmins_group_token =
  $create_group_success_json->{data}->{organization_groups}->{group_token};

my $add_user_to_group_success = request(
    POST '/organization/addusertogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_sysadmins_group_token,
            user_token =>
              '03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt',    # noadmin@megashops.com
        }
    ),
);

is( $add_user_to_group_success->code(), 200, );

my $add_user_to_group_success_json =
  decode_json( $add_user_to_group_success->content );

is( $add_user_to_group_success_json->{status}, 1, );
is(
    $add_user_to_group_success_json->{message},
    'Required user has been added to organization group.',
);

is( $add_user_to_group_success_json->{_hidden_data}, undef, );

my $get_noadmin_is_sysadmin = request(
    GET '/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $get_noadmin_is_sysadmin->code(), 200, );

my $get_noadmin_is_sysadmin_json =
  decode_json( $get_noadmin_is_sysadmin->content );

is( $get_noadmin_is_sysadmin_json->{status}, 1, 'Status success.' );
isnt(
    $get_noadmin_is_sysadmin_json->{_hidden_data}->{groups}
      ->{"Mega Shop Sysadmins"}->{users}->{'noadmin@megashops.com'},
    undef, 'User has been added'
);

my $remove_user_success = request(
    DELETE "$endpoint/03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
);

is( $remove_user_success->code(), 200, );

my $remove_user_success_json = decode_json( $remove_user_success->content );

is( $remove_user_success_json->{status}, 1, );
is(
    $remove_user_success_json->{message},
    'Selected user has been removed from organization.',
);

is( $remove_user_success_json->{_hidden_data}, undef, );

my $list_users_again = request(
    GET '/user/showregistered',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $list_users_again->code(), 200, );

my $list_users_again_json = decode_json( $list_users_again->content );

is( $list_users_again_json->{status}, 1, 'Status success.' );
is( keys %{ $list_users_again_json->{data}->{registered_users} },
    3, 'noadmin@megashops.com has been deleted' );

my $get_sysadmins = request(
    GET '/organization/showallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $get_sysadmins->code(), 200, );

my $get_sysadmins_json = decode_json( $get_sysadmins->content );

is( $get_sysadmins_json->{status}, 1, 'Status success.' );
is(
    $get_sysadmins_json->{_hidden_data}->{groups}->{"Mega Shop Sysadmins"}
      ->{users}->{'noadmin@megashops.com'},
    undef, 'User has been removed'
);

my $superadmin_removes_marvin = request(
    DELETE "$endpoint/bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
);

is( $superadmin_removes_marvin->code(), 200, );

my $superadmin_removes_marvin_json =
  decode_json( $superadmin_removes_marvin->content );

is( $superadmin_removes_marvin_json->{status}, 1, );
is(
    $superadmin_removes_marvin_json->{message},
    'Selected user has been removed from organization.',
);

my $already_removed_fail = request(
    DELETE "$endpoint/03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
);

is( $already_removed_fail->code(), 400, );

my $already_removed_fail_json = decode_json( $already_removed_fail->content );

is( $already_removed_fail_json->{status}, 0, );
is(
    $already_removed_fail_json->{message},
    'Requested user does not exists or it has not been registered by you.',
);

is( $already_removed_fail_json->{_hidden_data}, undef, );

my $already_removed_fail_superadmin = request(
    DELETE "$endpoint/03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
);

is( $already_removed_fail_superadmin->code(), 400, );

my $already_removed_fail_superadmin_json =
  decode_json( $already_removed_fail_superadmin->content );

is( $already_removed_fail_superadmin_json->{status}, 0, );
is(
    $already_removed_fail_superadmin_json->{message},
    'Requested user does not exists or it has not been registered by you.',
);

is( $already_removed_fail_superadmin_json->{_hidden_data}, undef, );

my $remove_myslef_fail_superadmin = request(
    DELETE "$endpoint/gDoGxCkNI0DrItDrOzWKjS5tzCHjJTVO",
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
);

is( $remove_myslef_fail_superadmin->code(), 400, );

my $remove_myslef_fail_superadmin_json =
  decode_json( $remove_myslef_fail_superadmin->content );

is( $remove_myslef_fail_superadmin_json->{status}, 0, );
is(
    $remove_myslef_fail_superadmin_json->{message},
    'Requested user does not exists or it has not been registered by you.',
);

is( $remove_myslef_fail_superadmin_json->{_hidden_data}, undef, );

my $superadmin_removes_superboss = request(
    DELETE "$endpoint/tqqZW1Xrjw6BAUJo6Y5WqQzBJenxOY9X",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_removes_superboss->code(), 200, );

my $superadmin_removes_superboss_json =
  decode_json( $superadmin_removes_superboss->content );

is( $superadmin_removes_superboss_json->{status}, 1, );
is(
    $superadmin_removes_superboss_json->{message},
    'Selected user has been removed from organization.',
);

my $admin_get_inactive_users = request(
    GET "user/showinactive",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

my $admin_get_inactive_users_json =
  decode_json( $admin_get_inactive_users->content );

is( $admin_get_inactive_users_json->{status}, 1, );

isnt(
    $admin_get_inactive_users_json->{data}->{inactive_users}
      ->{'shirorobot@megashops.com'}->{token},
    undef
);

my $shirorobot_user_token =
  $admin_get_inactive_users_json->{data}->{inactive_users}
  ->{'shirorobot@megashops.com'}->{token};

my $superadmin_removes_shiro = request(
    DELETE "$endpoint/$shirorobot_user_token",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_removes_shiro->code(), 200, );

my $superadmin_removes_shiro_json =
  decode_json( $superadmin_removes_shiro->content );

is( $superadmin_removes_shiro_json->{status}, 1, );
is(
    $superadmin_removes_shiro_json->{message},
    'Selected user has been removed from organization.',
);

my $superadmin_removes_orphan = request(
    DELETE "$endpoint/qQGzQ4X3BBNiSFvEwBhsQZF47FS0v5AP",
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $superadmin_removes_orphan->code(), 200, );

my $superadmin_removes_orphan_json =
  decode_json( $superadmin_removes_orphan->content );

is( $superadmin_removes_orphan_json->{status}, 1, );
is(
    $superadmin_removes_orphan_json->{message},
    'Selected user has been removed from organization.',
);

done_testing();
