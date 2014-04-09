#!/usr/bin/perl
#
# vyatta-anyfi-gateway.pl: anyfi-gateway config generator
#
# Maintainer: Anyfi Networks <eng@anyfinetworks.com>
#
# Copyright (C) 2013-2014 Anyfi Networks AB. All Rights Reserved.
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

# XXX: At the moment "service anyfi gateway $VAR(@) port-range"
# is handled in the templates and is not reflected here in any way

use lib "/opt/vyatta/share/perl5/";

use strict;
use warnings;
use Vyatta::Config;
use Getopt::Long;

my $conf_dir = "/etc/";

sub error
{
    my $msg = shift;
    print "Error configuring anyfi gateway: $msg\n";
    exit(1);
}

sub setup_port_range
{
    # Port range
    # XXX: at this point only the first port is actually used
    
    my $port_range = shift;
    my $port_range_string .= "bind_port = $port_range \n";

    return($port_range_string);
}

sub setup_bridge
{
    my $bridge = shift;
    my $bridge_string = "bridge = $bridge \n";

    return($bridge_string);
}

sub setup_ssid
{
    my $ssid = shift;
    my $ssid_string = "ssid = $ssid \n";

    return($ssid_string);
}

sub setup_uuid
{
    my $uuid = shift;
    my $uuid_string = "uuid = $uuid \n";

    return($uuid_string);
}

sub setup_rekey_interval
{
    my $rekey_interval = shift;
    my $rekey_interval_string = "group_rekey = $rekey_interval \n";

    return($rekey_interval_string);
}

sub setup_strict_rekey
{
    my $strict_rekey_string = "strict_rekey = 1 \n";

    return($strict_rekey_string);
}

sub setup_auth_proto
{
    my $auth_proto = shift;
    my $auth_proto_string = "";

    $auth_proto_string .= "auth_proto = $auth_proto \n";

    return($auth_proto_string);
}

sub setup_auth_mode
{
    my $auth_mode = shift;
    my $auth_mode_string = "auth_mode = $auth_mode \n";

    return($auth_mode_string);
}

sub setup_ciphers
{
    my $auth_proto = shift;
    my $ciphers = shift;
    my $ciphers_string = "";

    $ciphers_string .= $auth_proto . "_ciphers = $ciphers\n";
 
    return($ciphers_string);
}

sub setup_passphrase
{
    my $passphrase = shift;
    my $passphrase_string = "passphrase = $passphrase \n";

    return($passphrase_string);
}

sub setup_radius_server
{
    my $server = shift;
    my $port = shift;
    my $secret = shift;
    my $role = shift; # auth/acct/autz

    my $radius_string = "radius_" . $role . "_server = $server\n";

    if( defined($port) )
    {
        $radius_string .= "radius_" . $role . "_port = $port\n";
    }

    $radius_string .= "radius_" . $role . "_secret = $secret\n";

    return($radius_string);
}

sub setup_isolation
{
    return("isolation = 1\n");
}

sub get_ciphers
{
    my $config = shift;
    my $level = shift;
    my @ciphers = ("ccmp", "tkip");

    @ciphers = $config->listNodes("$level ciphers") if $config->exists("$level ciphers");

    return \@ciphers;
}

sub generate_config
{
    my $instance = shift;
    my $config = new Vyatta::Config();
    $config->setLevel("service anyfi gateway $instance");

    my $config_string = "";

    # Bridge
    my $bridge = $config->returnValue("bridge");
    if(! $bridge )
    {
        error("Must specify Bridge");
    }
    elsif (! check_bridge($bridge) )
    {
        error("Bridge $bridge does not exist");
    }
    $config_string .= setup_bridge($bridge);

    # SSID
    my $ssid = $config->returnValue("ssid");
    if( $ssid )
    {
        $config_string .= setup_ssid($ssid);
    }
    else
    {
        error("Must specify SSID");
    }

    # UUID
    my $uuid = $config->returnValue("uuid");
    if( $uuid )
    {
        $config_string .= setup_uuid($uuid);
    }

    # Rekey interval
    my $rekey_interval = $config->returnValue("rekey-interval");
    if( $rekey_interval )
    {
        $config_string .= setup_rekey_interval($rekey_interval);
    }

    # Strict rekey
    if( $config->exists("strict-rekey") )
    {
        $config_string .= setup_strict_rekey();
    }

    # Authentication settings
    if( $config->exists("authentication eap") && $config->exists("authentication psk") )
    {
        error("Can not configure both RADIUS and pre-shared key authentication at the same time!");
    }

    if( $config->exists("authentication eap") )
    {
        $config_string .= setup_auth_mode("eap");

        my $primary_server = $config->returnValue("authentication eap radius-server");
        my $primary_port = $config->returnValue("authentication eap radius-port");
        my $primary_secret = $config->returnValue("authentication eap radius-secret");
        if( !defined($primary_server) )
        {
            error("Must specify RADIUS server address in authentication!");
        }
        elsif( !defined($primary_secret) )
        {
            error("Must specify RADIUS secret in authentication");
        }
        else
        {
            $config_string .= setup_radius_server($primary_server, $primary_port, $primary_secret, "auth");
        }
    }
    elsif( $config->exists("authentication psk") )
    {
        my $passphrase = $config->returnValue("authentication psk passphrase");
        if( !defined($passphrase) )
        {
            error("Must specify passphrase!");
        }
        elsif( length($passphrase) < 8 )
        {
            error("Passphrase must be at least 8 characters long!");
        }
        else
        {
            $config_string .= setup_auth_mode("psk");
            $config_string .= setup_passphrase($passphrase);
        }
    }
    else
    {
        # Implicit default to open
        $config_string .= setup_auth_proto("open");
    }

    # Authorization
    if( $config->exists("authorization") )
    {
        my $primary_server = $config->returnValue("authorization radius-server");
        my $primary_port = $config->returnValue("authorization radius-port");
        my $primary_secret = $config->returnValue("authorization radius-secret");
        if( !defined($primary_server) )
        {
            error("Must specify primary RADIUS server address in authorization!");
        }
        elsif( !defined($primary_secret) )
        {
            error("Must specify primary RADIUS secret in authorization");
        }
        else
        {
            $config_string .= setup_radius_server($primary_server, $primary_port, $primary_secret, "autz");
        }
    }

    # Accounting settings
    if( $config->exists("accounting") )
    {
        my $primary_server = $config->returnValue("accounting radius-server");
        my $primary_port = $config->returnValue("accounting radius-port");
        my $primary_secret = $config->returnValue("accounting radius-secret");
        if( !defined($primary_server) )
        {
            error("Must specify primary RADIUS server address in accounting!");
        }
        elsif( !defined($primary_secret) )
        {
            error("Must specify primary RADIUS secret in accounting");
        }
        else
        {
            $config_string .= setup_radius_server($primary_server, $primary_port, $primary_secret, "acct");
        }
    }

    # Second RADIUS accounting server
    if( $config->exists("accounting second") )
    {
        my $primary_server = $config->returnValue("accounting second radius-server");
        my $primary_port = $config->returnValue("accounting second radius-port");
        my $primary_secret = $config->returnValue("accounting second radius-secret");
        if( !defined($primary_server) )
        {
            error("Must specify second RADIUS server address!");
        }
        elsif( !defined($primary_secret) )
        {
            error("Must specify second RADIUS secret");
        }
        else
        {
            $config_string .= setup_radius_server($primary_server, $primary_port, $primary_secret, "acct2");
        }
    }

    # WPA/WPA2 Security

    if( $config->exists("authentication") && !($config->exists("wpa") || $config->exists("wpa2")) )
    {
        error("authentication requires wpa or wpa2 security.");
    }
    if( !$config->exists("authentication") && ($config->exists("wpa") || $config->exists("wpa2")) )
    {
        error("wpa/wpa2 security requires authentication.");
    }

    my %security = ();

    $security{"wpa"} = get_ciphers($config, "wpa") if ($config->exists("wpa"));
    $security{"rsn"} = get_ciphers($config, "wpa2") if ($config->exists("wpa2"));

    $config_string .= setup_auth_proto(join('+', keys %security) || "open");
    foreach my $proto (keys %security)
    {
        my @ciphers = @{$security{$proto}};

        if (scalar(@ciphers) == 0) {
            error("must configure at least one $proto cipher.");
        }

        $config_string .= setup_ciphers($proto, join('+', @ciphers));
    }

    # Isolation
    if( $config->exists("isolation") )
    {
        $config_string .= setup_isolation();
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
