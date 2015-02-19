Vyatta CLI for the Anyfi Gateway
================================

This package provides a Vyatta (and EdgeOS) CLI for the
[Anyfi Gateway](http://www.anyfinetworks.com/products/gateway).

# Functionality Overview

The Gateway allows an operator to design and implement a carrier Wi-Fi service
in the trusted and predictable environment of a data center. It is configured
in much the same way as a carrier-grade access point, but with the important
difference that it doesn't come with antennas. Instead it sends and receives
IEEE 802.11 frames through Wi-Fi over IP tunnels, automatically set up by a
[Controller](http://www.anyfinetworks.com/products/controller).

The typical interfaces of the gateway is IP for the control plane and data plane
tunnels, IEEE 802.3 Ethernet for client traffic and RADIUS for AAA. The Vyatta
CLI however also allows for further processing the client traffic, after it has
has been put on the specified bridge but before it leaves the Gateway. VLAN
tagging, L2oGRE tunneling or even acting as a full IP gateway with DHCP and IP
routing functionality is supported. 

For a more complete overview see the Gateway's
[Datasheet](http://www.anyfinetworks.com/files/anyfi-gateway-datasheet.pdf).

# Installation Instructions

This package (together with the required anyfi-gateway software) can be
installed from Anyfi Networks' software repository by following the
instructions below.

More detailed instructions are provided in the
[Reference Guide](http://www.anyfinetworks.com/files/anyfi-gateway-refguide-r1f.pdf)
for the Gateway. Complete example integrations of the Gateway in a virtualized
Wi-Fi core can be downloaded at http://www.anyfinetworks.com/download.

## Adding Anyfi Networks' Repository

Use the below commands to add Anyfi Networks' software repository as a package
source on any Vyatta based system.

```
  $ configure
  # edit system package repository anyfi
  # set url http://packages.anyfinetworks.com/vyatta
  # set components "main contrib non-free"
  # set distribution r1f
  # commit
  # save
  # exit
  $ wget http://packages.anyfinetworks.com/vyatta/pubkey.gpg -O anyfi.gpg
  $ sha1sum anyfi.gpg
  b5a3a3233e3348ef555ba4fae11941f2339bbb88 anyfi.gpg
  $ sudo apt-key add anyfi.gpg
```

## Installing the Software

Once you have added Anyfi Networks' repository as a package source on your
system you can install the software with the below command.

```
  $ sudo apt-get install -y vyatta-anyfi-gateway anyfi-gateway
```

## Upgrading the Software

The software can be upgraded with the below commands.

```
  $ sudo apt-get update
  $ sudo apt-get upgrade
  $ restart anyfi gateway <NAME>
```

Upgrading the software will not break backward compatibility with your
configuration or any network protocols.

## Upgrading to a New Release

Upgrading to a new release requires more planning as it may break backward
compatibility. In general you should plan to upgrade all of your core
infrastructure at the same time.

Once you are ready to upgrade to a new release you can use the below commands.

```
  $ configure
  # set system package repository anyfi distribution <RELEASE>
  # commit
  # save
  # exit
  $ sudo apt-get update
  $ sudo apt-get upgrade
  $ restart anyfi gateway <NAME>
```

# Command Overview

For more complete documentation see the
[Reference Guide](http://www.anyfinetworks.com/files/anyfi-gateway-refguide-r1f.pdf)
for the Gateway.

## Configuration Commands

    service
      anyfi
        gateway <txt: NAME>
          controller <ipv4: CONTROLLER ADDRESS>
            key <sha256: RSA KEY FINGERPRINT>
          ssid <txt: SERVICE SET ID>
          uuid <txt: SDWN SERVICE UUID>
          bridge <txt: BRIDGE INTERFACE NAME>
          wpa
            ciphers
              tkip
              ccmp
          wpa2
            ciphers
              tkip
              ccmp
            preassociation
            pmksa-cache-size <int: CACHE SIZE>
            key-derivation
              sha1
              sha256
          ft
            mobility-domain <int: MOBILITY DOMAIN>
            over-the-ds
            reassociation-timeout <int: TIMEOUT>
          rekey-interval <int: INTERVAL>
          strict-rekey
          authentication
            eap
              radius-server <ipv4: RADIUS SERVER ADDRESS>
                secret <txt: RADIUS SHARED SECRET>
                port <int: RADIUS UDP PORT>
            psk
              passphrase <txt: PRE-SHARED PASSPHRASE>
          authorization
            radius-server <ipv4: RADIUS SERVER ADDRESS>
              secret <txt: RADIUS SHARED SECRET>
              port <int: RADIUS UDP PORT>
          accounting
            radius-server <ipv4: RADIUS SERVER ADDRESS>
              secret <ipv4: RADIUS SHARED SECRET>
              port <int: RADIUS UDP PORT>
          isolation
          port-range <txt: SDWN UDP PORT RANGE>

## Operational Commands

    show anyfi license             # Show license information.
    show anyfi gateway <NAME> ...  # Show information about a gateway instance.
    restart anyfi gateway <NAME>   # Restart a gateway instance.

