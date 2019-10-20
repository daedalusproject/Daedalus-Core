use v5.26;
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'Daedalus::Core';
use Daedalus::Core::Controller::REST;

use JSON::XS;
use MIME::Base64;
use HTTP::Request::Common qw(GET PUT POST DELETE);

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/script";

use DatabaseSetUpTearDown;

DatabaseSetUpTearDown::delete_database();
DatabaseSetUpTearDown::create_database();

my $endpoint = '/projects/show';

my $non_admin_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'noadmin@megashops.com',
            password => '__;;_12__Password_34',
        }
    )
);

is( $non_admin_login_success->code(), 200, );

my $non_admin_login_success_json =
  decode_json( $non_admin_login_success->content );

is( $non_admin_login_success_json->{status}, 1, );

my $non_admin_login_success_token =
  $non_admin_login_success_json->{data}->{session_token};

my $non_admin_authorization_basic =
  MIME::Base64::encode( "session_token:$non_admin_login_success_token", '' );

my $admin_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'otheradminagain@megashops.com',
            password => '__::___Password_1234',
        }
    )
);

is( $admin_login_success->code(), 200, );

my $admin_login_success_json = decode_json( $admin_login_success->content );

is( $admin_login_success_json->{status}, 1, );

my $admin_login_success_token =
  $admin_login_success_json->{data}->{session_token};

my $admin_authorization_basic =
  MIME::Base64::encode( "session_token:$admin_login_success_token", '' );

my $superadmin_login = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'admin@daedalus-project.io',
            password => 'this_is_a_Test_1234',
        }
    )
);

is( $superadmin_login->code(), 200, );

my $superadmin_login_json = decode_json( $superadmin_login->content );

is( $superadmin_login_json->{status}, 1, );

my $superadmin_session_token = $superadmin_login_json->{data}->{session_token};

my $superadmin_authorization_basic =
  MIME::Base64::encode( "session_token:$superadmin_session_token", '' );

#my $success_admin = request(
#    GET "$endpoint",
#    Content_Type  => 'application/json',
#    Authorization => "Basic $admin_authorization_basic",
#);
#
#is( $success_admin->code(), 200, );
#
#my $success_admin_json = decode_json( $success_admin->content );
#
#is( $success_admin_json->{status}, 1, );
#
#is( $success_admin_json->{_hidden_data}, undef, );
#
#isnt( $success_admin_json->{data},             undef, );
#isnt( $success_admin_json->{data}->{projects}, undef, );

my $create_group_megashop_sysadmins = request(
    POST "/organization/creategroup",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop Sysadmins'
        }
    ),
);

is( $create_group_megashop_sysadmins->code(), 200, );

my $create_group_megashop_sysadmins_json =
  decode_json( $create_group_megashop_sysadmins->content );

my $megashops_sysadmins_group_token =
  $create_group_megashop_sysadmins_json->{data}->{organization_groups}
  ->{group_token};

my $add_fireman_role_to_megashop_sysadmins_group = request(
    POST "/organization/addroletogroup",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Megashops
            group_token => $megashops_sysadmins_group_token,
            role_name   => 'fireman'
        }
    ),
);

is( $add_fireman_role_to_megashop_sysadmins_group->code(), 200, );

my $add_maze_master_role_to_megashop_sysadmins_group = request(
    POST "/organization/addroletogroup",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Megashops
            group_token => $megashops_sysadmins_group_token,
            role_name   => 'maze_master'
        }
    ),
);

is( $add_maze_master_role_to_megashop_sysadmins_group->code(), 200, );

my $create_group_megashop_healers = request(
    POST "/organization/creategroup",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",    #Megashops token
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_name         => 'Mega Shop healers'
        }
    ),
);

is( $create_group_megashop_healers->code(), 200, );

my $create_group_megashop_healers_json =
  decode_json( $create_group_megashop_healers->content );

my $megashops_healers_group_token =
  $create_group_megashop_healers_json->{data}->{organization_groups}
  ->{group_token};

my $add_health_watcher_role_to_megashop_healers_group = request(
    POST "/organization/addroletogroup",
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Megashops
            group_token => $megashops_healers_group_token,
            role_name   => 'health_watcher'
        }
    ),
);

is( $add_health_watcher_role_to_megashop_healers_group->code(), 200, );

my $add_marvin_to_megashops = request(
    POST '/organization/adduser',
    Content_Type  => 'application/json',
    Authorization => "Basic $superadmin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);
is( $add_marvin_to_megashops->code(), 200, );

my $add_marvin_to_megashop_sysadmins_group = request(
    POST '/organization/addusertogroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_sysadmins_group_token,
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);

is( $add_marvin_to_megashop_sysadmins_group->code(), 200, );

my $add_marvin_to_megashop_healers_group = request(
    POST '/organization/addusertogroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_healers_group_token,
            user_token =>
              'bBRVZCmo2vAQjjSLXGBiz324Qya4h3pC',    # marvin@megashops.com
        }
    ),
);

my $add_no_admin_megashop_healers_group = request(
    POST '/organizGation/addusertogroup',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            organization_token => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            group_token        => $megashops_healers_group_token,
            user_token =>
              '03QimYFYtn2O2c0WvkOhUuN4c8gJKOkt',    # noadmin@megashops.com
        }
    ),
);

is( $add_marvin_to_megashop_healers_group->code(), 200, );

my $hank_scorpio_login_success = request(
    POST '/user/login',
    Content_Type => 'application/json',
    Content      => encode_json(
        {
            'e-mail' => 'hscorpio@globex.com',
            password => '::::Sc0rP10___:::;;;;;',
        }
    )
);

is( $hank_scorpio_login_success->code(), 200, );

my $hank_scorpio_login_success_json =
  decode_json( $hank_scorpio_login_success->content );

is( $hank_scorpio_login_success_json->{status}, 1, );

my $hank_scorpio_login_success_token =
  $hank_scorpio_login_success_json->{data}->{session_token};

my $hank_scorpio_authorization_basic =
  MIME::Base64::encode( "session_token:$hank_scorpio_login_success_token", '' );

my $create_arcturus_project = request(
    POST '/project/create',
    Content_Type  => 'application/json',
    Authorization => "Basic $hank_scorpio_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3', # Globex
            'name'               => 'Arcturus Project',
        }
    )
);

is( $create_arcturus_project->code(), 200, );

my $create_arcturus_project_json =
  decode_json( $create_arcturus_project->content );

my $arcturus_project_token =
  $create_arcturus_project_json->{data}->{project}->{token};

my $share_arcturus_project_with_megashops_project_caretaker = request(
    POST '/project/share',
    Content_Type  => 'application/json',
    Authorization => "Basic $hank_scorpio_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3', # Globex
            'organization_to_share_token' =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Mega shops
            'project_token' => $arcturus_project_token,
            'role_name'     => 'project_caretaker',
        }
    )
);

is( $share_arcturus_project_with_megashops_project_caretaker->code(), 200, );

my $share_arcturus_project_with_daedalus_project_maze_master = request(
    POST '/project/share',
    Content_Type  => 'application/json',
    Authorization => "Basic $hank_scorpio_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3', # Globex
            'organization_to_share_token' =>
              'FrFM2p5vUb2FpQ0Sl9v0MXvJnb4OxNzO',    # Daedalus Project
            'project_token' => $arcturus_project_token,
            'role_name'     => 'maze_master',
        }
    )
);

is( $share_arcturus_project_with_daedalus_project_maze_master->code(), 200, );

my $share_arcturus_project_with_megashops_health_watcher = request(
    POST '/project/share',
    Content_Type  => 'application/json',
    Authorization => "Basic $hank_scorpio_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'AUDBO7LQvpFciDhfuApGkVbpYQqJVFV3', # Globex
            'organization_to_share_token' =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Megashops
            'project_token' => $arcturus_project_token,
            'role_name'     => 'health_watcher',
        }
    )
);

is( $share_arcturus_project_with_megashops_health_watcher->code(), 200, );

my $megashop_healers_group_has_access_to_arcturus_project = request(
    POST '/project/share/group',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token'   => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' => $arcturus_project_token,
            'group_token'          => $megashops_healers_group_token,
        }
    )
);

is( $megashop_healers_group_has_access_to_arcturus_project->code(), 200, );

my $share_megashops_ecommerce_project_with_megashops_health_watcher = request(
    POST '/project/share',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Megashops
            'organization_to_share_token' =>
              'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',    # Megashops
            'project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'role_name' => 'health_watcher',
        }
    )
);

is( $share_megashops_ecommerce_project_with_megashops_health_watcher->code(),
    200, );

my $megashop_healers_group_has_access_to_megashops_ecommerce = request(
    POST '/project/share/group',
    Content_Type  => 'application/json',
    Authorization => "Basic $admin_authorization_basic",
    Content       => encode_json(
        {
            'organization_token' => 'ljMPXvVHZZQTbXsaXWA2kgSWzL942Puf',
            'shared_project_token' =>
              'oqu2eeCee2Amae6Aijo7tei5woh4jiet',    # Mega Shops e-commerce
            'group_token' => $megashops_healers_group_token,
        }
    )
);

is( $megashop_healers_group_has_access_to_megashops_ecommerce->code(), 200, );

done_testing();

#DatabaseSetUpTearDown::delete_database();
