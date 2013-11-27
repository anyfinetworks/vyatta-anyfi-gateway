#!/usr/bin/perl
#
# vyatta-anyfi-gateway.pl: myfid config generator
#
# Maintainer: Daniil Baturin <daniil@baturin.org>
#
# Copyright (C) 2013 SO3Group
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

use lib "/opt/vyatta/share/perl5/";

use strict;
use warnings;
use Vyatta::Config;
use Getopt::Long;

my $conf_dir = "/etc/";

sub error
{
    my $msg = shift;
    print "Error configuring AnyFi gateway: $msg\n";
    exit(1);
}

sub generate_config
{
    my $instance = shift;
    my $config = new Vyatta::Config();
    $config->setLevel("service anyfi gateway $instance");

    my $config_string = "";

    # Bridge
    my $bridge = $config->returnValue("bridge");
    if( ! check_bridge($bridge) )
    {
        error("Bridge $bridge does not exist");
    }
    else
    {
        $config_string .= "bridge = $bridge\n";
    }

    # SSID
    my $ssid = $config->returnValue("ssid");
    if( $ssid )
    {
        $config_string .= "ssid = $ssid\n";
    }
    else
    {
        error("Must specify SSID");
    }

    # Local AP
    my $local_ap = $config->returnValue("local-ap");
    if( $local_ap )
    {
        $config_string .= "local_ap = $local_ap\n";
    }

    # Rekey interval
    my $rekey_interval = $config->returnValue("rekey-interval");
    if( $rekey_interval )
    {
        $config_string .= "group_rekey = $rekey_interval\n";
    }

    # Strict rekey
    if( $config->exists("strict-rekey") )
    {
        $config_string .= "strict_rekey = 1\n";
    }

    # Authentication settings
    my $auth_mode = $config->returnValue("authentication mode");
    my $auth_proto = $config->returnValue("authentication protocol");

    if( (! $auth_proto) || (! $auth_mode) )
    {
        error("Must specify authentication mode and protocol");
    }

    if( ($auth_proto eq 'open') && ($auth_mode) )
    {
        error("Can't specify authentication mode if authentication protocol is \"open\"");
    }

    # $auth_proto is later used in ciphers
    if( $auth_proto eq 'wpa2' )
    {
        $auth_proto = 'rsn';
    }
    elsif( $auth_proto eq 'both' )
    {
        $auth_proto = 'wpa+rsn';
    }
    $config_string .= "auth_proto = $auth_proto\n";
    $config_string .= "auth_mode = $auth_mode\n";

    # Ciphers
    my $ciphers = $config->returnValue("authentication ciphers");
    if( $ciphers )
    {
        if( $auth_proto eq 'open' )
        {
            error("Can't specify ciphers if authentication protocol is \"open\"");
        }

        if( $ciphers eq 'both' )
        {
            $ciphers = 'tkip+ccmp';
        }

        # Have I gotten this right?
        if( $auth_proto eq 'wpa+rsn' )
        {
            $config_string .= "wpa_ciphers = $ciphers\n";
            $config_string .= "rsn_cipher = $ciphers\n";
        }

        $config_string .= $auth_proto . "_ciphers = $ciphers\n";
    }

    # Passphrase
    my $passphrase = $config->returnValue("authentication passphrase");
    if( $passphrase )
    {
        if( $auth_mode ne 'psk' )
        {
            error("Can't specify passphrase if authentication mode is not 'psk'");
        }

        $config_string .= "passphrase = $passphrase\n";
    }

    # RADIUS server
    my $radius_server = $config->returnValue("authentication radius-server");
    if( $radius_server )
    {
        if( $auth_mode ne 'eap' )
        {
            error("Can't specify RADIUS server if authentication mode is not 'eap'");
        }

        $config_string .= "radius_auth_server = $radius_server\n";
    }

    return($config_string);
}

sub check_bridge
{
    my $config = new Vyatta::Config();
    my $bridge = shift;

    return( $config->isEffective("interfaces bridge $bridge") );
}

sub apply_config
{
    my ($instance, $config_file) = @_;
    my $config = generate_config($instance);
    open(HANDLE, ">$config_file") || error("Could not open $config_file for write");
    print HANDLE $config;
    close(HANDLE);
}

my $instance;
my $config_file;

GetOptions(
    "instance=s" => \$instance,
    "config=s" => \$config_file
);

if( (! $instance) || (! $config_file ) )
{
    error("Usage: --instance=<instance name> --config=</path/to/config_file>");
}

apply_config($instance, $config_file);
