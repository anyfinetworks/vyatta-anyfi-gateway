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


[See local wireless interface configuration](http://mirror.symnds.com/software/vyatta/vc6.0/docs/Vyatta_LANInterfacesRef_R6.0_v01.pdf)
as a comparison. Only difference here is that we don't have a channel and that
there can be any number of physical access points behind an interface, i.e. in
IEEE parlase an anyfi interface represents a potentially large number of Basic
Service Sets (BSS) all part of the same Extended Service Set (ESS).

    interfaces
        anyfi <txt: INTERFACE NAME>
            description <txt: DESCRIPTION>
            ssid <txt: SSID>
            bridge-group
                ...
            qos-policy
                ...
            firewall
                ...
            security
                ...
                wpa-mixed
                    ...
                group-rekey
                    interval <int: INTERVAL IN SECONDS>
                    strict-rekey

# Operational Commands

    show interfaces anyfi   # Lists all anyfi services (with myfidctl output).

