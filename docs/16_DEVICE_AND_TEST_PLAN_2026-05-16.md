# Device And Test Plan

Date: 2026-05-16

Purpose: keep the four-machine test inventory, connection order, and operator
setup instructions in the repository so the MacBook Pro, MacBook Air, and future
Codex Cloud sessions share the same source of truth.

## Current Device Inventory

| Role | Device | Memory | GPU / Media note | OS state | Current read |
|---|---|---:|---|---|---|
| Primary A | MacBook Pro 16-inch, M1 Max | 32 GB | M1 Max has stronger encode headroom than M1 Air in current iBridge probes | macOS Tahoe 26 | Preferred Primary for high-detail and tiled 5K experiments. |
| Primary B | MacBook Air, M1 | 8 GB | Current repo measurements show only `2560x1440 @ 60` HEVC passes the p95 encode budget | macOS Tahoe 26 | Use as the conservative/mobile Primary path; do not chase Air 5K60 first. |
| Receiver A | iMac 21.5-inch Retina 4K, 2017 | 8 GB | Radeon Pro 555 | macOS Sequoia via OCLP | Best first receiver because Thunderbolt 3, Ethernet, and macOS receiver path are available. |
| Receiver B | iMac 27-inch Retina 5K, Late 2015 | 8 GB | Radeon R9 M380 | macOS Sequoia via OCLP; Windows boot also available | Target 5K receiver; test macOS path first, keep Windows as receiver comparison path. |

## Hardware Interpretation

- The MacBook Pro should be treated as the stronger encoder source. Existing
  iBridge results show M1 Max profiles above `2560x1440` can pass when isolated,
  while M1 Air currently passes only the `2560x1440 @ 60` sender profile.
- The 2015 27-inch iMac has Gigabit Ethernet and Thunderbolt 2. Gigabit Ethernet
  is nominally lower bandwidth than Thunderbolt 2, but it is available and easy
  to test. Thunderbolt 2 should remain a later test because the cable/adapter
  chain is not currently available.
- The 2017 21.5-inch 4K iMac has Thunderbolt 3, Gigabit Ethernet, and macOS
  today. It should be the first wired receiver because it avoids the 2015 iMac's
  missing Thunderbolt 2 cable and Windows/macOS boot-state uncertainty.
- Current Tailscale/Wi-Fi data is reachability evidence only. Do not use it to
  reject Ethernet or Thunderbolt paths.
- AirPlay Receiver is not visible from the MacBook Pro to the iMacs in the
  current OCLP/Sequoia setup. Keep AirPlay as a comparison-only path and proceed
  with iBridge over Ethernet/Thunderbolt/Wi-Fi transport.

## Current Measured Path: MBP To 2017 iMac

| Path | iMac IP | Result | Read |
|---|---|---|---|
| Direct Ethernet | `169.254.70.114` | ping `0.826/1.518/2.372/0.231 ms`; TCP `939.14 Mbps` to iMac / `937.50 Mbps` reverse; UDP 30/60/120 Mbps 0% loss | Excellent next test path |
| 5GHz Wi-Fi | `192.168.31.249` | ping `3.663/56.773/261.386/70.416 ms`; TCP `86.54 Mbps` to iMac / `68.66 Mbps` reverse; UDP 120 Mbps had `8.202%` loss | Reachable but too jittery for display-profile decisions |

Current remote state: SSH is repaired on the 2017 iMac, `caffeinate -dimsu` is
running, and `/usr/local/bin/iperf3 -s` is listening on TCP `5201`.

Scope correction: the 2017 21.5-inch iMac is a 4K receiver target. Use it to
validate Mac-to-Mac receiver behavior up to `3840x2160@60`; reserve
`4096x2304`, 5K, and tiled 5K-style profiles for the 2015 27-inch Retina 5K
iMac.

## Ordered Test Matrix

Run in this exact order unless a physical cable or OS-state blocker changes:

| Order | Source | Receiver | Connection | Status / blocker | First profile |
|---:|---|---|---|---|---|
| 1 | MacBook Pro M1 Max | iMac 21.5 4K 2017 | Wireless / Tailscale or local Wi-Fi | reachable but current 5GHz Wi-Fi is jittery | `2560x1440@60`, then `3200x1800@60` if useful |
| 2 | MacBook Pro M1 Max | iMac 21.5 4K 2017 | Ethernet | SSH and `iperf3` ready; direct 1GbE measured good | `3840x2160@60` maximum |
| 3 | MacBook Pro M1 Max | iMac 21.5 4K 2017 | Thunderbolt Bridge | needs TB3/USB-C cable and IP setup | `3840x2160@60` maximum |
| 4 | MacBook Pro M1 Max | iMac 27 5K 2015 | Wireless / Tailscale or local Wi-Fi | Windows/macOS receiver state must be known | `3200x1800@60` then `2560x1440@60` |
| 5 | MacBook Pro M1 Max | iMac 27 5K 2015 | Ethernet | needs cable/hub and `iperf3` | `3840x2160@60` then `4096x2304@60` |
| 6 | MacBook Air M1 | iMac 21.5 4K 2017 | Wireless / Tailscale or local Wi-Fi | ready after receiver prep | `2560x1440@60` HEVC |
| 7 | MacBook Air M1 | iMac 21.5 4K 2017 | Ethernet | needs cable/hub; receiver SSH and `iperf3` are ready | `2560x1440@60`; retest `3200x1800@60` only if stable |
| 8 | MacBook Air M1 | iMac 21.5 4K 2017 | Thunderbolt Bridge | needs TB3/USB-C cable and IP setup | `2560x1440@60` |
| 9 | MacBook Air M1 | iMac 27 5K 2015 | Wireless / Tailscale or local Wi-Fi | receiver OS state must be known | `2560x1440@60` |
| 10 | MacBook Air M1 | iMac 27 5K 2015 | Ethernet | needs cable/hub and `iperf3` | `2560x1440@60` |
| 11 | MacBook Pro M1 Max | iMac 27 5K 2015 | Thunderbolt 2 / Thunderbolt Bridge | blocked until TB2 cable/adapter chain exists | `4096x2304@60`; then 2x2 tiled HEVC 5K60 |
| 12 | MacBook Air M1 | iMac 27 5K 2015 | Thunderbolt 2 / Thunderbolt Bridge | blocked until TB2 cable/adapter chain exists | `2560x1440@60`; no Air 5K60 unless sender strategy changes |

## Operator Setup Instructions

### Before Every Test

1. Put the source MacBook on AC power.
2. Put the receiver iMac on AC power and disable sleep for the session.
3. Keep both machines on the same local network when testing Wi-Fi/Ethernet.
4. Record the OS, connection type, IP addresses, and physical cable path in the
   run summary before interpreting display quality.
5. Run network measurement before live display measurement.

### Receiver iMac macOS Setup

Run on each iMac booted into macOS:

```bash
sudo systemsetup -setcomputersleep Never
sudo systemsetup -setdisplaysleep Never
sudo pmset -a sleep 0 displaysleep 0 disksleep 0 powernap 0 womp 1 tcpkeepalive 1
```

Then:

- Install and sign in to Tailscale if remote access is needed.
- Enable System Settings -> General -> Sharing -> Remote Login.
- Install `iperf3` if available through Homebrew, or document that throughput
  is blocked until it is installed.
- Keep the receiver app or benchmark server visible in the logged-in desktop
  session when testing presentation.

For the 2017 iMac right now:

```bash
sudo ssh-keygen -A
sudo /usr/sbin/sshd -t
sudo systemsetup -setremotelogin on
sudo launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
sudo launchctl enable system/com.openssh.sshd
sudo launchctl kickstart -k system/com.openssh.sshd
sudo lsof -nP -iTCP:22 -sTCP:LISTEN
iperf3 -s
```

### Receiver iMac Windows Setup

Run from PowerShell as Administrator when using the 2015 iMac in Windows:

```powershell
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
```

Then:

- Install/sign in to Tailscale.
- Confirm OpenSSH Server is installed and running if Codex needs remote shell.
- Authorize the MacBook Pro and MacBook Air SSH keys separately.
- Start `iperf3 -s` for network tests.
- Start the iBridge receiver before expecting port `48320` to listen.

### Ethernet Setup

- Connect the MacBook to Ethernet through USB-C/Thunderbolt hub if needed.
- Connect the iMac Ethernet port to the same switch/router, or directly to the
  MacBook adapter if doing a direct link.
- Prefer local IP addresses over Tailscale IPs for this test.
- Run `scripts/mac_network_matrix.sh --case 1gbe --receiver-ip <imac-local-ip>`.

### Thunderbolt Bridge Setup

- For the 2017 iMac: use a known-good Thunderbolt 3 / USB-C Thunderbolt cable.
- For the 2015 iMac: wait for the Thunderbolt 2 cable/adapter chain. Do not
  treat Mini DisplayPort-only cables as valid Thunderbolt data cables.
- On macOS, enable Thunderbolt Bridge in Network settings on both machines.
- Assign DHCP/self-assigned IPs or manual IPs, then run
  `scripts/mac_network_matrix.sh --case thunderbolt --receiver-ip <imac-tb-ip>`.

## Luna / BetterDisplay Direction

Luna Display uses a hardware dongle to make the Primary Mac believe an external
display exists. iBridge should not copy that hardware dependency as the default.
The preferred prototype direction is:

1. Create a software virtual display on the source Mac.
2. Force useful HiDPI modes without requiring a display dongle.
3. Capture that virtual display with ScreenCaptureKit or `CGDisplayStream`.
4. Encode with VideoToolbox and send to the receiver.
5. Use a USB hub only for networking/power/cable convenience, not as the core
   display-presence mechanism.

BetterDisplay is now tracked as `reference/BetterDisplay` through a Git
submodule on its `opensource` branch. Use it as a reference for display/HiDPI
behavior and historical virtual-screen behavior. Do not copy implementation code
without a separate license and clean-room review.

## Multi-Machine GitHub Handoff

- Main branch for current work: `feat/plan-a-5k60-benchmark`.
- MacBook Pro and MacBook Air should both work from GitHub, not from local Codex
  caches.
- Before switching machines: commit, push, and update `docs/current-work.md`.
- On the other machine:

```bash
git clone --recurse-submodules https://github.com/oosuhada/iBridge.git
cd iBridge
git checkout feat/plan-a-5k60-benchmark
git pull --rebase
git submodule update --init --recursive reference/BetterDisplay
```

If the repo is already cloned:

```bash
git fetch origin
git checkout feat/plan-a-5k60-benchmark
git pull --rebase
git submodule update --init --recursive reference/BetterDisplay
```
