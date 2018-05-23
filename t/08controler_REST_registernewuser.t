use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $registerGETcontent = get('/registernewuser');

is_deeply(
    decode_json($registerGETcontent),
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

my $failed_because_no_auth = request(
    POST '/registernewuser',
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

my $failed_because_no_auth_json =
  decode_json( $failed_because_no_auth->content );

is( $failed_because_no_auth_json->{status},
    'Failed', 'Status failed, no auth.' );
is(
    $failed_because_no_auth_json->{message},
    'Wrong e-mail or password.',
    'A valid e-mail password mut be provided.'
);

my $failed_no_admin = request(
    POST '/registernewuser',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'notanadmin@daedalus-project.io',
                password => 'Test_is_th1s_123',
            }
        }
    )
);

my $failed_no_admin_json = decode_json( $failed_no_admin->content );

is( $failed_no_admin_json->{status}, 'Failed',
    'Status failed, not an andmin.' );
is(
    $failed_no_admin_json->{message},
    'You are not an admin user.',
    'Only admin uers are able to register new users.'
);

my $failed_no_data = request(
    POST '/registernewuser',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            }
        }
    )
);

my $failed_no_data_json = decode_json( $failed_no_data->content );

is( $failed_no_data_json->{status}, 'Failed', 'There is no user data.' );
is(
    $failed_no_data_json->{message},
    'Invalid user data.',
    'It is required user data to register a new user.'
);

my $failed_empty_data = request(
    POST '/registernewuser',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            new_user_data => {},
        }
    )
);

my $failed_empty_data_json = decode_json( $failed_empty_data->content );

is( $failed_empty_data_json->{status}, 'Failed', 'Nothing supplied' );
is(
    $failed_empty_data_json->{message},
    'No email supplied.No name supplied.No surname supplied.',
    'new_user_data is empty.'
);

my $failed_no_email_no_surname = request(
    POST '/registernewuser',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            new_user_data => {
                name => 'John',
            },
        }
    )
);

my $failed_no_email_no_surname_json =
  decode_json( $failed_no_email_no_surname->content );

is( $failed_no_email_no_surname_json->{status},
    'Failed', 'Only name is supplied' );
is(
    $failed_no_email_no_surname_json->{message},
    'No email supplied.No surname supplied.',
    'new_user_data only contains a name.'
);

my $failed_no_name_no_surname = request(
    POST '/registernewuser',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            new_user_data => {
                email => 'never@mind',
            },
        }
    )
);

my $failed_no_name_no_surname_json =
  decode_json( $failed_no_name_no_surname->content );

is( $failed_no_name_no_surname_json->{status},
    'Failed', 'Only email is supplied' );
is(
    $failed_no_name_no_surname_json->{message},
    'No name supplied.No surname supplied.',
    'new_user_data only contains an email.'
);

my $failed_invalid_email = request(
    POST '/registernewuser',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'admin@daedalus-project.io',
                password => 'this_is_a_Test_1234',
            },
            new_user_data => {
                email   => 'invalidemail_example.com',
                name    => 'somename',
                surname => 'Some surname',

            },
        }
    )
);

my $failed_invalid_email_json = decode_json( $failed_invalid_email->content );

is( $failed_invalid_email_json->{status}, 'Failed', 'E-mail is invalid.' );
is(
    $failed_invalid_email_json->{message},
    'Provided e-amil is invalid.',
    'A valid e-mail is required.'
);

done_testing();
