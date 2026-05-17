# iBridge Studio Network Setup

iBridge Studio works best when each receiver iMac has a stable path from the MacBook.

## Recommended two-iMac topology

```text
MacBook Pro Ethernet -> 2015 27-inch iMac Ethernet
MacBook Pro Thunderbolt / USB-C -> 2017 21.5-inch iMac Thunderbolt Bridge
```

Avoid sharing both iMacs over the same congested Wi-Fi path during first setup.

## Manual static IP example

Use private addresses that match your local environment. Do not commit personal IPs to the repository.

```text
MacBook Ethernet:          10.10.15.1
2015 iMac Ethernet:        10.10.15.2

MacBook Thunderbolt Bridge: 10.10.17.1
2017 iMac Thunderbolt:      10.10.17.2

Subnet mask: 255.255.255.0
Router/DNS: blank
Receiver port: 48320
```

## Receiver tab

On the receiver iMac:

1. Open iBridge Studio.
2. Go to Receiver.
3. Start Receiver on This Mac.
4. Copy the relevant address from This Mac addresses.
5. Paste that IP into the MacBook Sender card.

## Discovery strategy

Manual Receiver IP is the reliable alpha path. SSH Discovery is useful for advanced setups, but it requires a trusted SSH host and working key.

Future work will move discovery toward Bonjour/mDNS and Network.framework probes.

