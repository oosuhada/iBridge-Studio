# Transmission Profile Matrix

Date: 2026-05-15

## Direction

The next step is not a Windows synthetic tiled renderer.

iBridge should first finish the sender-side decision tree: for each source Mac and connection class, choose the most plausible capture, encode, bitrate, and resolution profile. Receiver decode/render should be tested later on the 2015 iMac after both Windows and macOS receiver environments are available.

## Current Read

Plan A as "single 5120x2880 @ 60Hz stream" is not viable on the current M1 Max path. Single-session HEVC 5K60 is far beyond the frame budget, and ScreenCaptureKit 5K60 capture+encode is worse.

Plan A as "full logical 5K60 by split/tiled streams" is still viable enough to keep as the top full-resolution prototype path on the M1 Max MacBook Pro. The best current sender-only result is:

```text
source=synthetic-nv12-tiled
logical_resolution=5120x2880
tile_grid=2x2
tile_resolution=2560x1440
codec=hevc
encoder_id=com.apple.videotoolbox.videoencoder.ave.hevc
bitrate=30Mbps per tile
data_rate_limit=30Mbps per tile
tile_reset_every_frames=180
tile_max_inflight_logical_frames=1
```

This sustained 30 seconds at effective `60.009fps`, average logical encode latency `12.100ms`, and p95 `12.690ms`. The caveat is still important: reset frames spike to about `135.530ms`, so the display path must later hide, drop, or stagger those events.

## Hardware Reality

The local M1 Max MacBook Pro exposes hardware VideoToolbox encoders for H.264 and HEVC, and the current encoder list also shows hardware ProRes encoders. It does not expose an AV1 encoder in this repo's probe.

Apple's 2021 16-inch MacBook Pro technical specifications list M1 Max with two video encode engines and two ProRes encode/decode engines. [내용 출처 : https://support.apple.com/en-us/111901]

Apple's M1 launch material says M1 includes efficient media encode and decode engines, but the M1 Air is a much smaller thermal and media-engine target than M1 Max. [내용 출처 : https://www.apple.com/li/newsroom/2020/11/apple-unleashes-m1/]

Current Apple MacBook Pro specifications show the newer direction: current Max-class chips still list two video encode engines and add AV1 decode. That matters for receiver playback on newer Macs, but it does not create AV1 encode on the user's M1 Air or M1 Max. [내용 출처 : https://www.apple.com/macbook-pro/specs/]

## Connection Reality

The 2015 27-inch Retina 5K iMac has a 5120-by-2880 panel, two Thunderbolt 2 ports, Gigabit Ethernet, and 802.11ac Wi-Fi. [내용 출처 : https://support.apple.com/en-us/112035]

Apple's Thunderbolt 3-to-Thunderbolt 2 adapter supports Thunderbolt 2 data transfer up to 20Gbps, but it is not a Mini DisplayPort display adapter. For iBridge, this is useful as a network/data path, not as Target Display Mode. [내용 출처 : https://support.apple.com/en-us/111753]

Apple documents IP-over-Thunderbolt between two Macs using Thunderbolt Bridge. [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]

## Priority Matrix

| Source Mac | Connection | First profile | Why | Status |
|---|---|---|---|---|
| M1 Max MacBook Pro | Thunderbolt Bridge | 2x2 tiled HEVC 5K60, 30Mbps/tile | Only current full-5K60 sender path with p95 under budget | promising sender-only |
| M1 Max MacBook Pro | 1GbE | 4096x2304@60 HEVC or 3840x2160@60 HEVC | Isolated single-stream p95 passes, but product switching after tiled can poison encoder state | needs wired network test |
| M1 Max MacBook Pro | Wi-Fi | 3200x1800@60 HEVC, then 2560x1440@60 if latency matters | Wireless needs lower bitrate and adaptation before chasing full 5K | needs stable local Wi-Fi test |
| M1 Air | Thunderbolt Bridge | 2560x1440@60 HEVC | Air tiled 5K60 and 3200x1800 missed p95 budget; do not assume M1 Max headroom | sender-tested; transport pending |
| M1 Air | 1GbE | 2560x1440@60 HEVC | Air thermal/media budget plus 1GbE makes 5K60 unlikely as the default | sender-tested; transport pending |
| M1 Air | Wi-Fi | 2560x1440@60 HEVC | Best chance for stable interaction and text scaling | sender-tested; transport pending |

## Transfer Types To Build Toward

### Type A: Full 5K60 Tiled HEVC

Use for M1 Max plus the best wired path, especially Thunderbolt Bridge.

- Capture: eventually ScreenCaptureKit or virtual-display IOSurface path.
- Encode: four HEVC VideoToolbox sessions.
- Logical output: `5120x2880 @ 60`.
- Transport: independent tile streams or tile packets with logical frame IDs.
- Receiver rule later: present every vsync; reuse stale tile textures rather than stalling the full frame.

### Type B: High-Detail Single-Stream HEVC

Use for wired paths when full 5K tiled is too complex or too heavy.

- Candidate 1: `4096x2304 @ 60`.
- Candidate 2: `3840x2160 @ 60`.
- Encode is simpler: one HEVC session, one decoder, one texture.
- This is probably the fastest path to a usable wired app experience.

### Type C: Wireless Balanced HEVC

Use for Wi-Fi and Tailscale-like paths.

- Candidate 1: `3200x1800 @ 60`.
- Candidate 2: `2560x1440 @ 60`.
- Add adaptive bitrate before promising fixed 4K/5K wireless.
- Add dirty-region/cursor-separated updates after live capture exists.

### Type D: Mac-to-Mac Receiver Path

Use after macOS is installed on the iMac.

- The sender profile can stay the same.
- Decode choices should be tested separately: VideoToolbox decode on macOS versus Media Foundation / D3D11 decode on Windows.
- Thunderbolt Bridge becomes more attractive in this path because Apple officially supports IP over Thunderbolt between Macs.

## What To Avoid For Now

- Do not build Windows 4-tile synthetic composition as the next step. It is a receiver step, and the sender strategy is not fully settled across Mac/connection classes.
- Do not claim AV1 as a solution for M1 sender encoding. Current Apple specs show AV1 decode in newer Macs, while local M1 Max probing shows no AV1 encoder.
- Do not default to ProRes for wireless. ProRes hardware encode is worth a wired-only experiment later, but its bitrate profile is the opposite of Wi-Fi-friendly.
- Do not treat ScreenCaptureKit 5K60 as solved. The current 5K60 capture+encode result is a failure; capture strategy may need virtual-display sizing, dirty regions, or lower logical modes.
- Do not assume lower bitrate means lower latency. The latest quick retest shows lower-bandwidth single-stream HEVC profiles can spend more time encoding than earlier high-bitrate probes, likely because the encoder is working harder to compress.

## Latest Quick Retest

Command:

```bash
DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 RUN_ROOT=benchmarks/runs/2026-05-15_1258_transmission_profile_matrix scripts/mac_transmission_profile_matrix.sh
```

Result:

| Profile | Avg ms | P95 ms | Max ms | Read |
|---|---:|---:|---:|---|
| 2x2 tiled HEVC 5K60, 30Mbps/tile | 12.501 | 13.222 | 123.935 | Still the best full-5K60 sender path; reset spike remains |
| single HEVC 4096x2304@60, 120Mbps | 25.717 | 46.742 | 47.979 | Current run failed 60Hz budget; earlier strong result needs repeat isolation |
| single HEVC 3200x1800@60, 60Mbps | 23.614 | 41.764 | 82.782 | Current run failed 60Hz budget; wireless profile needs different tuning |

Deadline analysis for the tiled profile shows only 2/300 logical frames over 16.67ms in this 5-second quick run; both were reset/startup frames.

## Single-Stream Stability Re-Isolation

After the quick retest, single-stream profiles were re-isolated without running tiled encoding first.

Command:

```bash
REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=unset RUN_ROOT=benchmarks/runs/2026-05-15_1330_single_stream_stability_unset scripts/mac_single_stream_stability_matrix.sh
REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=on RUN_ROOT=benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on scripts/mac_single_stream_stability_matrix.sh
```

Result:

| Resolution | `prioritize_speed=unset` median p95 | `prioritize_speed=on` median p95 | Read |
|---|---:|---:|---|
| 4096x2304 | 13.050ms | 13.087ms | stable when isolated |
| 3840x2160 | 11.669ms | 11.668ms | stable when isolated |
| 3200x1800 | 11.250ms | 11.218ms | stable when isolated |
| 2560x1440 | 10.636ms | 6.455ms | stable when isolated |

The earlier slow quick-matrix single-stream results were reproduced when the matrix ran 2x2 tiled 5K60 first and then immediately ran single-stream profiles. A follow-up 4096x2304 single-stream run remained slow even after a 60-second wait. Treat this as a VideoToolbox encoder-service state effect until proven otherwise.

Practical rule:

- Do not benchmark single-stream fallbacks immediately after tiled 5K60.
- Run fallback profiles first, or run tiled profiles in a separate process/session after fallbacks.
- In the product, avoid switching from tiled 5K60 to single-stream fallback without an explicit encoder reset/restart strategy.

## Encoder Service Restart Probe

The next recovery check restarted the user `VTEncoderXPCService` and reran fallback probes.

Result:

| Probe | Avg ms | P95 ms | Read |
|---|---:|---:|---|
| 4096x2304 after `VTEncoderXPCService` restart | 25.928 | 46.532 | did not recover |
| 4096x2304 after 60s wait | 25.692 | 46.544 | did not recover |
| 4096x2304 after 60s wait, `prioritize_speed=unset` | 25.724 | 46.719 | did not recover |
| 3200x1800 after restart, solo | 23.746 | 41.839 | did not recover |
| 2560x1440 after restart | 7.851 | 10.808 | still safe |

Interpretation:

- The slow state is not cleared by restarting the user VideoToolbox encoder XPC service alone.
- The effect is probably below that service boundary, such as media-engine or driver state.
- Until a better reset is proven, a product fallback from tiled 5K60 should either restart the sender app in a clean process/session before measuring high-detail single-stream profiles, or fall all the way down to the safer `2560x1440@60` profile.
- Reboot/logout-level recovery was not tested in this repo run.

## M1 Air Sender Matrix

Command:

```bash
DEVICE_PROFILE=m1air PROFILE_SET=air DURATION=30 scripts/mac_transmission_profile_matrix.sh
```

Machine:

```text
Model Identifier: MacBookAir10,1
Chip: Apple M1
CPU: 8 cores, 4 performance and 4 efficiency
GPU: 7 cores
Memory: 8 GB
```

Result:

| Profile | Avg ms | P95 ms | Max ms | 16.67ms p95 budget | Read |
|---|---:|---:|---:|---|---|
| single HEVC 2560x1440@60, 25Mbps | 8.145 | 9.296 | 20.146 | pass | Realistic M1 Air default candidate |
| single HEVC 3200x1800@60, 35Mbps | 18.873 | 38.897 | 325.872 | fail | Not stable enough for Air default |
| single HEVC 3840x2160@60, 45Mbps | 18.727 | 54.584 | 233.527 | fail | Wired-only experiment at best, not default |
| 2x2 tiled HEVC 5120x2880@60, 25Mbps/tile | 23.626 | 23.718 | 72.096 | fail | Effective 41.599fps; not worth receiver work on M1 Air yet |

Deadline analysis for the M1 Air tiled probe shows `1800/1800` logical frames over 16.67ms. That is materially different from the M1 Max tiled result, where the misses were mostly startup/reset frames.

Interpretation:

- M1 Air should default to `2560x1440 @ 60` HEVC for now.
- `3200x1800 @ 60` can remain a retest/tuning target, but current p95 and max spikes make it unsuitable as the first Air profile.
- 2x2 tiled 5K60 should continue only as an M1 Max + best-wired path unless a new Air-side strategy changes the encode-only ceiling.

## Immediate Transport Gate

The MacBook Pro was updated to commit `a1f629d`, and its currently active path to the Windows iMac was rechecked over Tailscale:

```text
target=100.86.52.88
20 packets transmitted, 20 received, 0.0% loss
round-trip min/avg/max/stddev = 9.451/73.839/507.671/107.944 ms
```

This confirms reachability, but not display viability. The next real transport gate is still physical: Thunderbolt Bridge or 1GbE plus `scripts/mac_network_matrix.sh` and the Windows-side iperf server. Do not use the current Tailscale jitter to reject M1 Max wired tiled 5K60 or high-detail single-stream profiles.

A formal current-path matrix on the same Tailscale target then recorded:

```text
target=100.86.52.88
100 packets transmitted, 98 received, 2.0% loss
round-trip min/avg/max/stddev = 8.198/61.867/485.532/58.935 ms
```

The MBP shell did not have `iperf3` or `tailscale` CLI available, so this matrix could not measure throughput or direct-vs-DERP status. Treat this as a blocker for current-path display decisions, not as evidence against Thunderbolt Bridge or 1GbE.

## New Benchmark Entry Point

Use:

```bash
DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 scripts/mac_transmission_profile_matrix.sh
```

Recommended follow-ups:

```bash
DEVICE_PROFILE=m1max PROFILE_SET=wired DURATION=30 scripts/mac_transmission_profile_matrix.sh
DEVICE_PROFILE=m1max PROFILE_SET=wireless DURATION=30 scripts/mac_transmission_profile_matrix.sh
DEVICE_PROFILE=m1air PROFILE_SET=air DURATION=30 scripts/mac_transmission_profile_matrix.sh
```

The script writes a sanitized system profile, VideoToolbox encoder list, per-profile logs, and `summary.csv`. Tiled profiles also get deadline analysis when a logical CSV is produced.
