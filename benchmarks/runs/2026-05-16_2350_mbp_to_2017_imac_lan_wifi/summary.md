# MBP To 2017 iMac LAN/Wi-Fi Probe

Date: 2026-05-16

## Setup

- Source: MacBook Pro M1 Max, macOS Tahoe 26.5.
- Receiver candidate: 2017 21.5-inch iMac, macOS Sequoia through OCLP.
- Wi-Fi: both machines on 5GHz local network.
- Ethernet: MacBook Pro USB 10/100/1000 LAN adapter directly connected to the
  2017 iMac Ethernet port.

## Discovered Interfaces

| Path | MacBook Pro interface | MacBook Pro IP | iMac IP | Link / note |
|---|---|---|---|---|
| Ethernet direct | `en9` | `169.254.6.144` | `169.254.63.68` | `1000baseT <full-duplex>` |
| Wi-Fi 5GHz local | `en0` | `192.168.31.29` | `192.168.31.249` | local router path |

## Ping Results

| Path | Packets | Loss | Min / Avg / Max / Stddev |
|---|---:|---:|---|
| Ethernet direct | 100/100 | 0.0% | `0.425 / 0.810 / 1.379 / 0.235 ms` |
| Wi-Fi 5GHz local | 100/100 | 0.0% | `3.706 / 53.842 / 409.182 / 70.703 ms` |

## Port Checks

| Target | Port | Result |
|---|---:|---|
| `169.254.63.68` | 22 | refused |
| `192.168.31.249` | 22 | refused |
| `169.254.63.68` | 5201 | refused |
| `192.168.31.249` | 5201 | refused |

## Interpretation

- Direct Ethernet is already good enough for the next transport gate. The ping
  path is stable and low-jitter.
- Current 5GHz Wi-Fi is reachable but far too jittery for display-profile
  decisions in this room/network state.
- Remote Login is not enabled on the iMac yet, and `iperf3` server is not
  running. Throughput measurement is blocked until the receiver opens SSH or
  starts `iperf3 -s` locally.

## Next Action

On the 2017 iMac:

```bash
sudo systemsetup -setremotelogin on
brew install iperf3
iperf3 -s
```

Then run from the MacBook Pro:

```bash
RUN_ROOT=benchmarks/runs/2026-05-16_2350_mbp_to_2017_imac_lan_wifi DURATION=20 \
  scripts/mac_network_matrix.sh --case 1gbe-2017-imac --receiver-ip 169.254.63.68
```
