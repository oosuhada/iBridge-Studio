# Current Work

Date: 2026-05-15

Branch: `feat/plan-a-5k60-benchmark`

Draft PR: https://github.com/oosuhada/iBridge/pull/1

## Current Goal

Build and measure the macOS Primary -> Windows iMac Receiver path for using a 2015 27-inch iMac Retina 5K as a software external display.

## Current Status

- Prompt 00, 01, 02, 06, 05, 07, 03, 04, and 08 have been run with 09 review gates after implementation prompts.
- Windows iMac SSH over Tailscale works at `100.86.52.88`.
- Windows Receiver can run D3D11 fullscreen synthetic benchmarks from the active Windows console session.
- macOS Primary can generate synthetic frames and encode H.264/HEVC via VideoToolbox.
- Protocol v0 has a fixed 80-byte header and parser tests.
- Plan B 5K60 compressed mode was attempted and currently fails practical gates due to H.264 encode failure, HEVC latency, and slow TCP/Tailscale transport.
- Plan C scaled modes have an engineering comparison; `3200x1800 @ 60fps` is the temporary engineering default, but text quality is not validated.
- Current transport results are classified as Tailscale / likely Wi-Fi 2.4GHz / TCP early experiments and are not representative of LAN or Thunderbolt Bridge.
- macOS Primary now separates VideoToolbox output callback timing from TCP socket send timing with a bounded async sender queue.
- Windows Receiver has a new offline Media Foundation compressed file decode/render smoke path, but live TCP compressed decode/render is still pending Windows-side validation.
- MacBook Pro `MacBookPro18,4` / M1 Max has now been tested as a Primary candidate on branch `feat/plan-a-5k60-benchmark`.
- On the MacBook Pro, forcing `com.apple.videotoolbox.videoencoder.ave.hevc` and disabling low-latency rate-control produced the best Plan C encode results so far.
- A local ignored `reference/` workspace has been created for clean-room study of mature capture, encode, transport, decode, and frame-pacing implementations.
- The reference scope has been widened beyond macOS-to-Windows. Mac-to-Mac routes are now explicitly in scope if an older macOS install on the iMac creates a stronger technical path.
- Nested `.git` directories have been removed from the ignored `reference/` clones so VS Code only sees the outer iBridge repository.
- Reference analysis now points to concrete next spikes: VT property matrix, Annex-B fixture path, bounded receiver pacing, GPU-native decode/render, and a local Mac virtual-display smoke.
- iMac setup prep is documented with a Windows inventory script and a conservative remote-vs-physical-access boundary for Boot Camp/macOS work.
- Primary VideoToolbox encoding has been rechecked with reference-informed controls. Plan B 5K60 still fails before any receiver dependency; 3200x1800 and 3840x2160 are the current strongest encode-only candidates.
- Primary encoding now has source strategy probes for synthetic BGRA, synthetic NV12, static-frame skipping, ScreenCaptureKit capture, 5K45/5K30, and 2x2 tiled HEVC sessions.

## Key Results

- Plan A dynamic 5K60 CPU-filled BGRA upload on iMac: 29.979-36.034fps depending on run; not viable.
- Receiver GPU/static 5K present path: about 61fps; iMac can present 5K60 when full-frame CPU upload is removed.
- Primary 1440p60 H.264/HEVC encode works but initial callback latency is high.
- H.264 5120x2880 @ 60 target produced status `-10279` for every frame in the current VideoToolbox path.
- HEVC 5120x2880 @ 60 target encoded, but 120Mbps TCP to Windows sink took 38.60s for 1s of frames.
- Plan C receiver static scaled-render modes all reached about 60fps.
- MacBook Pro HEVC 3200x1800 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC: avg encode 16.612 ms, p95 16.777 ms.
- MacBook Pro HEVC 3200x1800 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, DataRateLimits: 5s sustained avg 11.583 ms, p95 11.766 ms.
- MacBook Pro HEVC 3840x2160 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, DataRateLimits: 5s sustained avg 15.457 ms, p95 15.831 ms.
- MacBook Pro HEVC 4096x2304 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, DataRateLimits: 5s sustained avg 17.292 ms, p95 17.231 ms.
- MacBook Pro HEVC 5120x2880 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, speed priority: 5s sustained avg 100.617 ms, p95 119.982 ms.
- MacBook Pro synthetic NV12 HEVC 3840x2160 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 11.557 ms, p95 11.906 ms.
- MacBook Pro synthetic NV12 HEVC 4096x2304 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 12.898 ms, p95 13.245 ms.
- MacBook Pro ScreenCaptureKit HEVC 3840x2160 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 16.363 ms, p95 18.412 ms.
- MacBook Pro ScreenCaptureKit HEVC 5120x2880 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 302.354 ms, p95 360.042 ms.
- MacBook Pro synthetic NV12 HEVC 5120x2880 @ 30, forced `ave.hevc`, DataRateLimits: 3s avg 19.296 ms, p95 19.824 ms.
- MacBook Pro 2x2 tiled-session approximation for 5120x2880 @ 60 using four 2560x1440 NV12 HEVC sessions: per-tile avg 6.496-9.528 ms, p95 10.568-11.254 ms; recomposition is unimplemented.
- MacBook Pro display-sized synthetic sources for built-in XDR, external portrait display, Sidecar iPad, and HDMI FHD display all encoded successfully with forced `ave.hevc`.
- MacBook Pro to iMac Tailscale path is reachable, but ping is jittery: 20-packet ICMP min/avg/max/stddev 14.484/108.629/423.525/96.505 ms.

## Files Likely Relevant Next

- `apps/primary-macos/Sources/iBridgePrimary/main.swift`
- `apps/receiver-windows/src/main.cpp`
- `benchmarks/plans/network_matrix.md`
- `scripts/mac_network_matrix.sh`
- `scripts/windows_network_matrix.ps1`
- `scripts/mac_plan_c_encode_matrix.sh`
- `scripts/mac_vt_property_matrix.sh`
- `scripts/mac_encode_strategy_matrix.sh`
- `benchmarks/runs/2026-05-15_1056_vt_property_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1058_vt_targeted_sustain/summary.md`
- `benchmarks/runs/2026-05-15_1129_encode_strategy_matrix/summary.md`
- `apps/shared-protocol/protocol_v0.py`
- `specs/protocol_v0.md`
- `benchmarks/runs/2026-05-15_0238_plan_b_5k_hevc_120mbps_tcp/summary.md`
- `benchmarks/runs/2026-05-15_0255_plan_c_scaled_modes/mode_comparison.md`
- `benchmarks/runs/2026-05-15_1000_mbp_encoder_id_probe/summary.md`
- `benchmarks/runs/2026-05-15_1012_mbp_display_resolution_encode/summary.md`
- `logs/review_gate.md`
- `logs/worklog.md`
- `reference/README.md`
- `docs/11_REFERENCE_TECH_ANALYSIS.md`
- `docs/12_IMAC_SETUP_PREP.md`
- `scripts/windows_imac_setup_inventory.ps1`

## Commands Run

- `swift build --package-path apps/primary-macos -c release`
- `python3 apps/shared-protocol/test_protocol_v0.py`
- `bash -n scripts/mac_encode_strategy_matrix.sh`
- `DURATION=3 scripts/mac_encode_strategy_matrix.sh`
- Windows MSVC `cl` build for `ibridge-receiver.exe`
- Windows iMac Task Scheduler D3D11 fullscreen benchmark runs
- `scripts/mac_power_probe.sh`

## Known Issues

- Plan B 5K60 compressed encode is still not viable on the current MBP Primary path.
- Compressed decode/render on Windows is not implemented.
- UDP frame transport is specified but not implemented.
- ScreenCaptureKit capture is implemented as a benchmark source, but not yet connected to live receiver transport/decode/render.
- Text-quality screenshots are pending.
- Power cable/drain-rate tests require physical cable changes.
- LAN/Thunderbolt Bridge throughput tests require physical cable changes and `iperf3` on both machines.
- Windows compressed file decode/render code needs MSVC build/run validation on the iMac.
- MacBook Pro SSH auth to Windows iMac is blocked; port 22 is open but the MBP key is not accepted.
- Forced encoder ID plus low-latency rate-control currently fails `VTCompressionSessionCreate` with `-12902`; forced `ave.hevc` works when low-latency rate-control is disabled.
- `prompts/10_PACKAGING_AND_RELEASE.md` is blocked until at least one end-to-end display mode works.

## Next Steps

1. Decide whether the next Plan B spike is tiled 5K60, or whether to prioritize single-session 4096x2304/3840x2160 @ 60 first.
2. If preserving 5K logical resolution matters, design tiled protocol metadata, receiver decode sessions, sync, and recomposition.
3. If single-session quality is preferred, run live TCP at 4096x2304 or 3840x2160 before any UDP work.
4. Implement dirty-region/cursor-separate logic after a live capture path exists, because static skipping alone only proves the encoder-side principle.
5. Only after encode remains stable, build and run the Windows `--decode-file` smoke path on the iMac with a known-good H.264/HEVC sample.
6. Extend receiver decode from offline file to protocol v0 TCP payloads.
7. Run network matrix after LAN and Thunderbolt Bridge cables are attached.
8. Capture screenshots and text-quality scoring after compressed decode/render works.
9. Compare Mac-Mac virtual-display and receiver options before assuming the Windows receiver is the long-term best path.
10. Run `scripts/windows_imac_setup_inventory.ps1` on the iMac from RDP or an existing authorized remote shell before any boot-volume or macOS install decision.
