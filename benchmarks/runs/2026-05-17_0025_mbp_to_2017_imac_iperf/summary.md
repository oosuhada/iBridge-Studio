# MBP To 2017 iMac iPerf Matrix

Date: 2026-05-17

## Setup

- Source: MacBook Pro M1 Max, macOS Tahoe 26.5.
- Receiver: 2017 21.5-inch iMac, macOS Sequoia through OCLP.
- Receiver `iperf3 -s` was started manually on the iMac for the first matrix.
- Remote Login was repaired later by generating OpenSSH host keys and adding
  the MacBook Pro public key to the iMac user's `authorized_keys`.
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

SSH is now working from the MacBook Pro to the 2017 iMac.

- `100.89.104.119:22`: open and authenticated.
- `192.168.31.249:22`: open.
- `169.254.70.114:22`: open and authenticated.

The iMac's SSH non-login shell does not include Homebrew in `PATH`; use
`/usr/local/bin/iperf3` explicitly when starting the server remotely.

Follow-up remote prep completed:

- `caffeinate -dimsu` is running to prevent system/display sleep during tests.
- `/usr/local/bin/iperf3 -s` is listening on TCP `5201`.
- A short post-repair 1GbE TCP check reached `937.86 Mbps` received over
  `169.254.70.114`.
