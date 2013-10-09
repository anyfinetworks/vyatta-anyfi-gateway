Vyatta/EdgeOS myfid integration
===============================

# Goals and Objectives

Provide CLI integration for AnyFi myfid tunnel termination daemon.

# Functional Specification

The user will be able to configure myfid tunnel integration daemon to use
specific system interfaces for client traffic bridge and specify wireless
network parameters, such as SSID, supported ciphers, or RADIUS server
settings for client authentication.

A Vyatta/EdgeOS routers should be used in conjunction with a system
running AnyFi radio frontend and a mobility server for the wireless network
to be operational.

# Configuration Commands

    service
        anyfi-ttp
            network <txt: NETWORK NAME>
                ssid <txt: SSID>
                bridge-interface <txt: BRIDGE INTERFACE>
                wlan-interface <txt: WIRELESS INTERFACE>
                group-rekey
                    interval <int: INTERVAL IN SECONDS>
                    strict-rekey
                encryption
                    wpa
                        cipher
                            ccmp
                            tkip
                    rsn
                        cipher
                            ccmp
                            tkip
                authentication
                    pre-shared
                        password <txt: WPA PASSPHRASE>
                    eap
                        radius
                            server <ipv4: RADIUS SERVER>
                            port <int: SERVER PORT>
                            password <txt: SERVER PASSWORD>
                accounting
                    radius
                        server <ipv4: RADIUS SERVER>
                        port <int: SERVER PORT>
                        password <txt: SERVER PASSWORD>

Accounting can be configured only if authentication is set to EAP.

# Operational Commands

    restart
        anyfi-ttp   # Restarts myfid

                            
