use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use HTTP::Request::Common;

my $confirm_registration_GET_content = get('/confirmregistration');

is_deeply(
    decode_json($confirm_registration_GET_content),
    {
        status  => 'Failed',
        message => "This method does not support GET requests."
    }
);

my $failed_because_no_auth_token = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json( {} ),
);

my $failed_because_no_auth_token_json =
  decode_json( $failed_because_no_auth_token->content );

is( $failed_because_no_auth_token_json->{status},
    'Failed', 'Status failed, no auth.' );
is(
    $failed_because_no_auth_token_json->{message},
    'Wrong e-mail or password.',
    'A valid e-mail password must be provided.'
);

my $failed_short_auth_token = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token => 'too_short_token',
            }
        }
    )
);

my $failed_short_auth_token_json =
  decode_json( $failed_short_auth_token->content );

is( $failed_short_auth_token_json->{status},
    'Failed', 'Status failed, auth_token too short' );
is(
    $failed_short_auth_token_json->{message},
    'Invalid Auth Token.',
    'Token is invalid because its too short.'
);

my $failed_invalid_auth_token = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token =>
'w8DGLY.jzMy4QrPqdl./6WOKvOhEC8T9leuNbSOVle3Zl6/Zd./m1yJMhHmnwH.',
            }
        }
    )
);

my $failed_invalid_auth_token_json =
  decode_json( $failed_invalid_auth_token->content );

is( $failed_invalid_auth_token_json->{status},
    'Failed', 'Status failed, auth_token does not exists' );
is(
    $failed_invalid_auth_token_json->{message},
    'Invalid Auth Token.',
    'Token is invalid because it does not exists.'
);

my $failed_valid_auth_token_no_password = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token =>
'w8DGLY.jzMy4QrPqdl./6WOKvOhEC8T9leuNbSOVle3Zl6/Zd./m1yJMhHmnwHW',
            }
        }
    )
);

my $failed_valid_auth_token_no_password_json =
  decode_json( $failed_valid_auth_token_no_password->content );

is( $failed_valid_auth_token_no_password_json->{status},
    'Failed', 'Status failed, no password supplied' );
is(
    $failed_valid_auth_token_no_password_json->{message},
    'Valid Auth Token found, enter your new password.',
    'Token is valid but there is no password supplied.'
);

my $failed_valid_auth_token_short_password = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token =>
'w8DGLY.jzMy4QrPqdl./6WOKvOhEC8T9leuNbSOVle3Zl6/Zd./m1yJMhHmnwHW',
                password => 'pass',
            }
        }
    )
);

my $failed_valid_auth_token_short_password_json =
  decode_json( $failed_valid_auth_token_short_password->content );

is( $failed_valid_auth_token_short_password_json->{status},
    'Failed', 'Status failed, no password supplied' );
is(
    $failed_valid_auth_token_short_password_json->{message},
    'Password is invalid.',
    'Password is too short.'
);

my $failed_valid_auth_token_password_no_diverse = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token =>
'w8DGLY.jzMy4QrPqdl./6WOKvOhEC8T9leuNbSOVle3Zl6/Zd./m1yJMhHmnwHW',
                password => 'passwordddddddddddddd',
            }
        }
    )
);

my $failed_valid_auth_token_password_no_diverse_json =
  decode_json( $failed_valid_auth_token_password_no_diverse->content );

is( $failed_valid_auth_token_password_no_diverse_json->{status},
    'Failed', 'Status failed, no password supplied' );
is(
    $failed_valid_auth_token_password_no_diverse_json->{message},
    'Password is invalid.',
    'Password is has no diverse characters.'
);

my $success_valid_auth_token_and_password = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token =>
'w8DGLY.jzMy4QrPqdl./6WOKvOhEC8T9leuNbSOVle3Zl6/Zd./m1yJMhHmnwHW',
                password => 'val1d_Pa55w0rd',
            }
        }
    )
);

my $success_valid_auth_token_and_password_json =
  decode_json( $success_valid_auth_token_and_password->content );

is( $success_valid_auth_token_and_password_json->{status},
    'Success', 'Password changed, account is activated.' );
is(
    $success_valid_auth_token_and_password_json->{message},
    'Account activated.',
    'Auth token has changed.'
);

my $failed_account_activated_changed_auth_token = request(
    POST '/confirmregistration',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                auth_token =>
'w8DGLY.jzMy4QrPqdl./6WOKvOhEC8T9leuNbSOVle3Zl6/Zd./m1yJMhHmnwHW',
                password => 'val1d_Pa55w0rd',
            }
        }
    )
);

my $failed_account_activated_changed_auth_token_json =
  decode_json( $failed_account_activated_changed_auth_token->content );

is( $failed_account_activated_changed_auth_token_json->{status},
    'Failed', 'Auth Token has changed.' );
is(
    $failed_account_activated_changed_auth_token_json->{message},
    'Invalid Auth Token.',
    'So, provided auth token becomes invalid.'
);

my $login_works = request(
    POST '/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            auth => {
                email    => 'otheradmin@daedalus-project.io',
                password => 'val1d_Pa55w0rd',
            }
        }
    )
);

my $login_works_json = decode_json( $login_works->content );

is( $login_works_json->{status}, 'Success', 'Now user is able to login.' );
is(
    $login_works_json->{message},
    'Auth Successful.',
    'Successful auth message.'
);

done_testing();
