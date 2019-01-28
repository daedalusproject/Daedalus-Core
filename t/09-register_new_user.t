use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;
use MIME::Base64;

my $registerGETcontent = get('/user/register');
ok( $registerGETcontent, qr /Method GET not implemented/ );

my $failed_because_no_auth = request(
    POST '/user/register',
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

is( $failed_because_no_auth->code(), 400, );

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is( $failed_because_no_auth_json->{status}, 0, 'Status failed, no auth.' );
is(
    $failed_because_no_auth_json->{message},
    'No session token provided.',
    'A valid session token must be provided.'
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

my $failed_no_admin = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $not_admin_authorization_basic",
);

is( $failed_no_admin->code(), 403, );

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 0, 'Status failed, not an andmin.' );
is(
    $failed_no_admin_json->{message},
    'You are not an admin user.',
    'Only admin uers are able to register new users.'
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

my $failed_no_data = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
);

is( $failed_no_data->code(), 400, );

my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status}, 0, 'There is no user data.' );
is(
    $failed_no_data_json->{message},
    'No e-mail provided. No name provided. No surname provided.',
    'It is required user data to register a new user.'
);

is( $failed_no_data_json->{_hidden_data},
    undef, 'If response code is not 2xx there is no hidden_data' );

my $failed_empty_data = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json( {} )
);

is( $failed_empty_data->code(), 400, );

my $failed_empty_data_json = decode_json( $failed_empty_data->content );

is( $failed_empty_data_json->{status}, 0, 'Nothing supplied' );
is(
    $failed_empty_data_json->{message},
    'No e-mail provided. No name provided. No surname provided.',
    'new_user_data is empty.'
);

is( $failed_empty_data_json->{_hidden_data},
    undef, 'If response code is not 2xx there is no hidden_data' );

my $failed_no_email_no_surname = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            name => 'John',
        }
    )
);

is( $failed_no_email_no_surname->code(), 400, );

my $failed_no_email_no_surname_json =
  decode_json( $failed_no_email_no_surname->content );

is( $failed_no_email_no_surname_json->{status}, 0, 'Only name is supplied' );
is(
    $failed_no_email_no_surname_json->{message},
    'No e-mail provided. No surname provided.',
    'new_user_data only contains a name.'
);

is( $failed_no_email_no_surname_json->{_hidden_data},
    undef, 'If response code is not 2xx there is no hidden_data' );

my $failed_no_name_no_surname = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'e-mail' => 'never@mind',
        }
    )
);

is( $failed_no_name_no_surname->code(), 400, );

my $failed_no_name_no_surname_json =
  decode_json( $failed_no_name_no_surname->content );

is( $failed_no_name_no_surname_json->{status}, 0, 'Only email is supplied' );
is(
    $failed_no_name_no_surname_json->{message},
    'e-mail is invalid. No name provided. No surname provided.',
    'new_user_data only contains an email.'
);

is( $failed_no_name_no_surname_json->{_hidden_data},
    undef, 'If response code is not 2xx there is no hidden_data' );

my $failed_invalid_email = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'e-mail' => 'invalidemail_example.com',
            name     => 'somename',
            surname  => 'Some surname',
        }
    )
);

is( $failed_invalid_email->code(), 400, );

my $failed_invalid_email_json = decode_json( $failed_invalid_email->content );

is( $failed_invalid_email_json->{status}, 0, 'E-mail is invalid.' );
is(
    $failed_invalid_email_json->{message},
    'e-mail is invalid.',
    'A valid e-mail is required.'
);

is( $failed_invalid_email_json->{_hidden_data},
    undef, 'If response code is not 2xx there is no hidden_data' );

my $failed_duplicated_email = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            'e-mail' => 'notanadmin@daedalus-project.io',
            name     => 'somename',
            surname  => 'Some surname',
        }
    )
);

is( $failed_duplicated_email->code(), 400, );

my $failed_duplicated_email_json =
  decode_json( $failed_duplicated_email->content );

is( $failed_duplicated_email_json->{status}, 0, 'E-mail is duplicated.' );
is(
    $failed_duplicated_email_json->{message},
    'There already exists a user using this e-mail.',
    'A non previously stored e-mail is required.'
);

is( $failed_duplicated_email_json->{_hidden_data},
    undef, 'If response code is not 2xx there is no hidden_data' );

my $success_superadmin = request(
    POST '/user/register',
    Authorization => "Basic $superadmin_authorization_basic",
    Content_Type  => 'application/json',
    Content       => encode_json(
        {
            'e-mail' => 'othernotanadmin@daedalus-project.io',
            name     => 'Other',
            surname  => 'Not Admin',
        }
    )
);

is( $success_superadmin->code(), 200, );

my $success_superadmin_json = decode_json( $success_superadmin->content );

is( $success_superadmin_json->{status}, 1, 'User has been created.' );
is(
    $success_superadmin_json->{message},
    'User has been registered.',
    'User registered.'
);
is(
    $success_superadmin_json->{_hidden_data}->{new_user}->{'e-mail'},
    'othernotanadmin@daedalus-project.io',
);

isnt( $success_superadmin_json->{data}->{new_user}->{token}, undef, );

my $success_superadmin_other_user = request(
    POST '/user/register',
    Authorization => "Basic $superadmin_authorization_basic",
    Content_Type  => 'application/json',
    Content       => encode_json(
        {
            'e-mail' => 'othernotanadmin2@daedalus-project.io',
            name     => 'Other 2',
            surname  => 'Not Admin 2',
        }
    )
);

is( $success_superadmin_other_user->code(), 200, );

my $success_superadmin_other_user_json =
  decode_json( $success_superadmin_other_user->content );

is( $success_superadmin_other_user_json->{status}, 1,
    'User has been created.' );
is(
    $success_superadmin_other_user_json->{message},
    'User has been registered.',
    'User registered.'
);
is(
    $success_superadmin_other_user_json->{_hidden_data}->{new_user}->{'e-mail'},
    'othernotanadmin2@daedalus-project.io',
);

isnt( $success_superadmin_other_user_json->{data}->{new_user}->{token},
    undef, );

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

my $success_no_superadmin_user = request(
    POST '/user/register',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'e-mail' => 'othernoadmin@daedalus-project.io',
            name     => 'Other',
            surname  => 'No Admin',
        },
    )
);

is( $success_no_superadmin_user->code(), 200, );

my $success_no_superadmin_user_json =
  decode_json( $success_no_superadmin_user->content );

is( $success_no_superadmin_user_json->{status}, 1, 'User has been created.' );
is(
    $success_no_superadmin_user_json->{message},
    'User has been registered.',
    'User registered.'
);

is( $success_no_superadmin_user_json->{_hidden_data},
    undef, 'User is not superadmin.' );

isnt( $success_no_superadmin_user_json->{data}->{new_user}->{token}, undef, );

my $inactive_user_cant_login = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'inactiveuser@daedalus-project.io',
            password => 'N0b0d7car5_;___',
        }
    )
);

is( $inactive_user_cant_login->code(), 403, );

my $inactive_user_cant_login_json =
  decode_json( $inactive_user_cant_login->content );

is( $inactive_user_cant_login_json->{status},  0, );
is( $inactive_user_cant_login_json->{message}, 'Wrong e-mail or password.', );

done_testing();
