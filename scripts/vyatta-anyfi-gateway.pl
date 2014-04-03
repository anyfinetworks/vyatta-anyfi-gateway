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
    print "Error configuring Anyfi Gateway: $msg\n";
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
    my $ciphers = shift;
    my $auth_proto = shift;
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
    my $rekey_interval = $config->returnValue("security rekey-interval");
    if( $rekey_interval )
    {
        $config_string .= setup_rekey_interval($rekey_interval);
    }

    # Strict rekey
    if( $config->exists("security strict-rekey") )
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

    # Security protocol
    if( $config->exists("authentication psk") || $config->exists("authentication eap") )
    {
        my $auth_proto = undef;

        if( $config->exists("wpa") && $config->exists("wpa2") )
        {
            $auth_proto = "wpa+rsn";
        }
        elsif( $config->exists("wpa") )
        {
            $auth_proto = "wpa";
        }
        elsif( $config->exists("wpa2") )
        {
            $auth_proto = "rsn";
        } else {
	    error("no security protocol set, you need to set either wpa or wpa2 or both under \"service anyfi gateway $instance\"")
	}

        $config_string .= setup_auth_proto($auth_proto);
        my $wpa_ciphers = join("+", $config->returnValues("wpa ciphers"));
        my $rsn_ciphers = join("+", $config->returnValues("wpa2 ciphers"));

        if( $auth_proto eq "wpa+rsn" )
        {
            $config_string .= setup_ciphers($wpa_ciphers, "wpa") if $wpa_ciphers;
            $config_string .= setup_ciphers($rsn_ciphers, "rsn") if $rsn_ciphers;
        }
        elsif( $auth_proto eq "wpa" )
        {
            $config_string .= setup_ciphers($wpa_ciphers, "wpa") if $wpa_ciphers;
        }
        elsif( $auth_proto eq "wpa2" )
        {
            $config_string .= setup_ciphers($rsn_ciphers, "rsn") if $rsn_ciphers;
        }
    } else {
	if( $config->exists("wpa") || $config->exists("wpa2") )
        {
	    error("wpa or wpa2 set without any authentication method, you need to set an authentication method under \"service anyfi gateway $instance authentication\"")
        }      
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
