# MBP To 2017 iMac iPerf Matrix

Date: 2026-05-17

## Setup

- Source: MacBook Pro M1 Max, macOS Tahoe 26.5.
- Receiver: 2017 21.5-inch iMac, macOS Sequoia through OCLP.
- Receiver `iperf3 -s` was started manually on the iMac.
- Direct Ethernet current iMac link-local IP: `169.254.70.114`.
- Wi-Fi 5GHz iMac local IP: `192.168.31.249`.

## Results

| Path | Ping loss | Ping min/avg/max/stddev | TCP to iMac | TCP reverse | UDP 30M | UDP 60M | UDP 120M |
|---|---:|---|---:|---:|---:|---:|---:|
| 1GbE direct | 0.0% | `0.826/1.518/2.372/0.231 ms` | `939.14 Mbps` | `937.50 Mbps` | `30.00 Mbps, 0% loss` | `60.00 Mbps, 0% loss` | `120.00 Mbps, 0% loss` |
| 5GHz Wi-Fi | 0.0% | `3.663/56.773/261.386/70.416 ms` | `86.54 Mbps` | `68.66 Mbps` | `29.60 Mbps, 0.023% loss` | `59.28 Mbps, 0.017% loss` | `103.72 Mbps, 8.202% loss` |

## Interpretation

- The 1GbE direct path is the correct next display-transport path.
- The 5GHz Wi-Fi path is reachable, but jitter and the 120 Mbps UDP loss make it
  unsuitable for high-detail fixed-profile display tests in the current
  environment.
- Tailscale can remain a management/reachability path, but do not use it to
  choose display profiles while direct Ethernet is available.

## SSH Status

`iperf3` is working, but SSH is still closed:

- `100.89.104.119:22`: refused.
- `192.168.31.249:22`: refused.
- `169.254.70.114:22`: refused.

The iMac reported `sshd: no hostkeys available -- exiting`; generate host keys
on the iMac before expecting remote shell access.
