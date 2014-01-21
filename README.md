Vyatta CLI for ANYFI GATEWAY
============================

# Goals and Objectives

Provide a Vyatta (and EdgeOS) CLI for ANYFI GATEWAY, allowing for large scale
centralized ANY80211 tunnel termination.

# Functional Specification

The user will be able to distribute virtual Wi-Fi network (a.k.a. "service" in
ANYFI terminology) from a gateway running the Vyatta Network OS. The virtual
network is configured with nearly identically to a physical access point: SSID,
authentication protocol, cipher and so on.

The integration also allows for further processing the client traffic by bridging
to an Ethernet interface, tunneling through L2oGRE or acting as a full IP gateway
with DHCP and IP router functionality. For one example of such further processing
see the [VC6 Wireless AccessPoint HOWTO](http://www.vyatta.org/node/3443).

For a more complete description see the
[ANYFI GATEWAY datasheet](http://www.anyfinetworks.com/files/anyfi-gateway-datasheet.pdf).

# Configuration Commands

    service
      anyfi
        gateway <txt: NAME>
          controller <ipv4: CONTROLLER ADDRESS>
          ssid <txt: SERVICE SET ID>
          uuid <txt: SERVICE SET UUID>
          bridge <txt: BRIDGE INTERFACE NAME>
          wpa
            ciphers
              tkip
              ccmp
          wpa2
            ciphers
              tkip
              ccmp
          authentication
            eap
              radius-server <ipv4: RADIUS SERVER ADDRESS>
              radius-secret <txt: RADIUS SHARED SECRET>
              radius-port <int: RADIUS UDP PORT>
              secondary
                radius-server <ipv4: RADIUS SERVER ADDRESS>
                radius-secret <txt: RADIUS SHARED SECRET>
                radius-port <int: RADIUS UDP PORT>
            psk
              passphrase <txt: PRE-SHARED PASSPHRASE>
          authorization
            radius-server <ipv4: RADIUS SERVER ADDRESS>
            radius-secret <txt: RADIUS SHARED SECRET>
            radius-port <int: RADIUS UDP PORT>
            secondary
              radius-server <ipv4: RADIUS SERVER ADDRESS>
              radius-secret <txt: RADIUS SHARED SECRET>
              radius-port <int: RADIUS UDP PORT>
          accounting
            radius-server <ipv4: RADIUS SERVER ADDRESS>
            radius-secret <ipv4: RADIUS SHARED SECRET>
            radius-port <int: RADIUS UDP PORT>
            secondary
              radius-server <ipv4: RADIUS SERVER ADDRESS>
              radius-secret <txt: RADIUS SHARED SECRET>
              radius-port <int: RADIUS UDP PORT>
          rekey-interval <int: INTERVAL>
          strict-rekey
          isolation             # Enable client device isolation.
          optimize
            arp                 # Rewrite ARP to unicast if possible.
            dhcp                # Rewrite DHCP to unicast if possible.
          port-range <txt: UDP PORT RANGE TO USE FOR THIS SERVICE>

# Operational Commands

    show anyfi license          # Show license information.
    show anyfi gateway <NAME>   # Show information about a gateway instance.

