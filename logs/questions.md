# Questions

Open questions for the user.

## 2026-05-14 22:20 — Plan A hardware measurements

- What IP address should the MacBook Air use for the Windows iMac receiver when running `scripts/mac_network_probe.sh <receiver-ip>`?
- Is the Apple Thunderbolt 3 to Thunderbolt 2 adapter plus Thunderbolt 2 cable available for a Thunderbolt Bridge iperf3 run?
- Can the Windows iMac run Visual Studio Build Tools or CMake so `apps/receiver-windows` can be built directly on the receiver machine?

## 2026-05-17 01:56 — MacBook Air to 2015 iMac prep blockers

- Can the MacBook Air public key be added to the 2015 iMac `authorized_keys` for the active macOS user?
- Should `/opt/homebrew` on the MacBook Air be repaired/reset later so `iperf3` can be installed locally, or should throughput measurement use another prepared machine?
- Is the 2015 iMac intended to stay booted in macOS for the near-term receiver work, or should Windows receiver comparison remain the immediate target after Wi-Fi reachability?
