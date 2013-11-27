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
        gateway <NAME>
          security
            ciphers <tkip|ccmp|both>
            authentication <psk|eap>
            protocol <wpa|wpa2|both|open>
            passphrase <txt>
            radius-server <ipv4>
            radius-secret <txt>
            rekey-interval <int>
            strict-rekey
          bridge <intf>
          ssid <txt>

# Operational Commands

    show interfaces anyfi   # Lists all anyfi services (with myfidctl output).

