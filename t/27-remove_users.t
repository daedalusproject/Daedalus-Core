use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

my $endpoint = '/user/remove';

my $failed_because_no_auth_token =
  request( DELETE $endpoint, Content_Type => 'application/json', );

is( $failed_because_no_auth_token->code(), 400, );

my $failed_because_no_auth_token_json =
  decode_json( $failed_because_no_auth_token->content );

is( $failed_because_no_auth_token_json->{status}, 0, );
is(
    $failed_because_no_auth_token_json->{message},
    "No session token provided.",
);

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

my $failed_no_token = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_token->code(), 400, );

my $failed_no_token_json = decode_json( $failed_no_token->content );

is( $failed_no_token_json->{status},  0, );
is( $failed_no_token_json->{message}, 'No organization_token provided.', );

my $failed_no_admin = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
    Content       => encode_json(
        {
            user_email => 'whocaresabouthtisuser@domain.com',
        }
    ),
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

my $failed_no_data = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( {} )
);

is( $failed_no_data->code(), 400, );
#
my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status},  0, );
is( $failed_no_data_json->{message}, 'No user_email provided.', );

my $failed_invalid_email = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content => encode_json( { user_email => 'ofcourseinvalid@emails_fail' } ),
);

is( $failed_invalid_email->code(), 400, );

my $failed_invalid_email_json = decode_json( $failed_invalid_email->content );

is( $failed_invalid_email_json->{status},  0, );
is( $failed_invalid_email_json->{message}, 'Invalid user_email', );

my $failed_non_existent_user = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json( { user_email => 'nonrobot@megashops.com' } ),
);

is( $failed_non_existent_user->code(), 400, );

my $failed_non_existent_user_json =
  decode_json( $failed_non_existent_user->content );

is( $failed_non_existent_user_json->{status}, 0, );
is(
    $failed_non_existent_user_json->{message},
    'Requested user does not exists or it has not been registered by you.',
);

my $failed_not_my_registered_user = request(
    DELETE $endpoint,
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content =>
      encode_json( { user_email => 'othernotanadmin@daedalus-project.io' } ),
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

my $add_user_to_group_success = request(
    POST '/organization/addusertogroup',
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins',
            user_email         => 'noadmin@megashops.com'
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
    GET '/organization/showoallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $get_noadmin_is_sysadmin->code(), 200, );

my $get_noadmin_is_sysadmin_json =
  decode_json( $get_noadmin_is_sysadmin->content );

is( $get_noadmin_is_sysadmin_json->{status}, 1, 'Status success.' );
is(
    @{
        $get_noadmin_is_sysadmin->{data}->{groups}
          ->{"Mega Shops Administrators"}->{users}
    }[0],
    'otheradminagain@megashops.com',
    'User has been added'
);

my $remove_user_success = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            user_email => 'noadmin@megashops.com',
        }
    ),
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
    GET '/organization/showoallgroups/ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
);

is( $get_sysadmins->code(), 200, );

my $get_sysadmins_json = decode_json( $get_sysadmins->content );

is( $get_sysadmins_json->{status}, 1, 'Status success.' );
is(
    @{
        $get_sysadmins->{data}->{groups}->{"Mega Shops Administrators"}->{users}
    },
    [],
    'User has been removed'
);

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

my $superadmin_removes_marvin = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            user_email => 'noadmin@megashops.com',
        }
    ),
);

is( $superadmin_removes_marvin->code(), 200, );

my $superadmin_removes_marvin_json =
  decode_json( $superadmin_removes_marvin->content );

is( $superadmin_removes_marvin_json->{status}, 1, );
is(
    $superadmin_removes_marvin_json->{message},
    'Selected user has been removed from organization.',
);

isnt( $superadmin_removes_marvin_json->{_hidden_data}, undef, );

my $already_removed_fail = request(
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $admin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            user_email => 'noadmin@megashops.com',
        }
    ),
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
    DELETE $endpoint,
    Content_Type => 'application/json',
    Authorization =>
      "Basic $superadmin_authorization_basic",    #Megashops Project token
    Content => encode_json(
        {
            user_email => 'noadmin@megashops.com',
        }
    ),
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

done_testing();
