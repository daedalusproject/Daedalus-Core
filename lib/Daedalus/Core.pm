package Daedalus::Core;

use 5.026_001;
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

Base library.

=head1 DESCRIPTION

Base library where configuration is loaded.

=head1 SEE ALSO

L<https://docs.daedalus-project.io/|Daedalus Project Docs>

=head1 VERSION

$VERSION

=head1 SUBROUTINES/METHODS
=head1 DIAGNOSTICS
=head1 CONFIGURATION AND ENVIRONMENT

If APP_TEST env is enabled, Core reads its configuration from t/ folder, by default config files we be read rom /etc/daedalus-core folder.

=head1 DEPENDENCIES

See debian/control

=head1 INCOMPATIBILITIES
=head1 BUGS AND LIMITATIONS
=head1 LICENSE AND COPYRIGHT

Copyright 2018-2020 Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>

Copying and distribution of this file, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved. This file is offered as-is, without any warranty.

=head1 AUTHOR

Álvaro Castellano Vela, alvaro.castellano.vela@gmail.com,,

=cut

1;
