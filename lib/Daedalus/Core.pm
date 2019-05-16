package Daedalus::Core;
use Moose;
use namespace::autoclean;
use Cache::Redis;
use Catalyst::Runtime 5.80;

use Catalyst qw/
  -Debug
  ConfigLoader::Multi
  Static::Simple
  Cache
  /;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in daedalus_core.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

if ( $ENV{APP_TEST} ) {

    if ( $ENV{APP_TEST_KUBERNETES} ) {
        __PACKAGE__->config(
            'Plugin::ConfigLoader' => {
                file => __PACKAGE__->path_to('t/lib/daedalus_core_testing.conf')
            }
        );
        __PACKAGE__->config( 'Plugin::ConfigLoader' =>
              { file => __PACKAGE__->path_to('t/lib/kubernetes_conf') } );
    }
    else {
        __PACKAGE__->config(
            'Plugin::ConfigLoader' => {
                file => __PACKAGE__->path_to('t/lib/daedalus_core_testing.conf')
            }
        );
        __PACKAGE__->config( 'Plugin::ConfigLoader' =>
              { file => __PACKAGE__->path_to('t/lib/conf') } );
    }
}
else {
    __PACKAGE__->config(
        'Plugin::ConfigLoader' => { file => '/etc/daedalus-core' } );
}

__PACKAGE__->config(
    name => 'Daedalus::Core',

    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,   # Send X-Catalyst header
);

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

Daedalus::Core - Catalyst based application

=head1 SYNOPSIS

    script/daedalus_core_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Daedalus::Core::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

1;
