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
- Tiled 5K60 has a stronger encode-only path after deeper investigation: per-tile PTS was corrected, and `2x2 30Mbps/tile reset180 inflight1` sustained 30 seconds at 60.009 effective fps with p95 12.690 ms. Reset-frame max spikes around 100-136 ms remain unresolved, but deadline analysis shows only 18/1800 logical frames exceeded 16.67 ms.
- Direction corrected: before building Windows tiled receiver composition, iBridge should finish sender-side transmission profiles for M1 Max/M1 Air and wired/wireless paths. Windows/macOS receiver decode should be tested later after the iMac has both OS environments available.
- Added a transmission profile matrix and encode-first script. Latest M1 Max quick retest keeps the 2x2 tiled HEVC 5K60 path promising, while current single-stream 4096x2304/3200x1800 retests missed the 60Hz encode budget and need repeat isolation/profile tuning.
- Re-isolated M1 Max single-stream profiles. When run without tiled 5K60 first, 4096x2304, 3840x2160, 3200x1800, and 2560x1440 all passed p95 <=16.67ms across 3/3 repeats. The slow quick-matrix fallback results are now attributed to tiled 5K60 contaminating immediate follow-up single-stream VideoToolbox state.
- Restarting the user `VTEncoderXPCService` did not recover post-tiled 4096x2304/3200x1800 performance. After tiled contamination, 2560x1440 remained inside budget and is the current safest emergency fallback.
- M1 MacBook Air `MacBookAir10,1` sender profile matrix has now been run locally for 30 seconds per case. Only `2560x1440 @ 60` synthetic NV12 HEVC passed the 16.67 ms p95 encode budget; `3200x1800`, `3840x2160`, and 2x2 tiled 5K60 missed the sender-only 60Hz budget.

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
- MacBook Pro 2x2 tiled HEVC 5120x2880 @ 60, corrected per-tile PTS, 30Mbps/tile, reset every 180 logical frames, max 1 in-flight logical frame: 30s sustained avg 12.100 ms, p95 12.690 ms, effective 60.009 fps, max 135.530 ms on reset frames.
- MacBook Pro transmission profile quick retest, 2x2 tiled HEVC 5120x2880 @ 60, 30Mbps/tile, reset180, inflight1: 5s avg 12.501 ms, p95 13.222 ms, effective 60.040 fps, max 123.935 ms; only 2/300 logical frames exceeded 16.67 ms.
- Same quick retest, single HEVC 4096x2304 @ 60, 120Mbps: avg 25.717 ms, p95 46.742 ms; current session missed the 60Hz encode budget despite earlier stronger runs.
- Same quick retest, single HEVC 3200x1800 @ 60, 60Mbps: avg 23.614 ms, p95 41.764 ms; lower-bandwidth wireless-style profile did not reduce encode latency in this run.
- Re-isolated single-stream stability, `PRIORITIZE_SPEED=unset`, 3 repeats: 4096x2304 median p95 13.050 ms, 3840x2160 11.669 ms, 3200x1800 11.250 ms, 2560x1440 10.636 ms.
- Re-isolated single-stream stability, `PRIORITIZE_SPEED=on`, 3 repeats: 4096x2304 median p95 13.087 ms, 3840x2160 11.668 ms, 3200x1800 11.218 ms, 2560x1440 6.455 ms.
- Post-tiled recovery probe: restarting `VTEncoderXPCService` did not recover 4096x2304; p95 stayed around 46.5 ms immediately and after 60 seconds. 3200x1800 solo also stayed slow at p95 41.839 ms, while 2560x1440 stayed safe at p95 10.808 ms.
- M1 Air HEVC 2560x1440 @ 60, 25Mbps: avg 8.145 ms, p95 9.296 ms, max 20.146 ms; passes p95 encode budget and is the realistic Air default.
- M1 Air HEVC 3200x1800 @ 60, 35Mbps: avg 18.873 ms, p95 38.897 ms, max 325.872 ms; fails 60Hz encode budget.
- M1 Air HEVC 3840x2160 @ 60, 45Mbps: avg 18.727 ms, p95 54.584 ms, max 233.527 ms; fails 60Hz encode budget.
- M1 Air 2x2 tiled HEVC 5120x2880 @ 60, 25Mbps/tile, reset180, inflight1: effective 41.599 fps, avg 23.626 ms, p95 23.718 ms, max 72.096 ms; all 1800 logical frames exceeded 16.67 ms, so this is not worth continuing on M1 Air without a major new strategy.
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
- `benchmarks/runs/2026-05-15_1213_tiled_5k60_reset_sustain_30s/summary.md`
- `benchmarks/runs/2026-05-15_1212_tiled_5k60_reset_sustain_10s/summary.md`
- `benchmarks/runs/2026-05-15_1222_tiled_5k60_reset180_sustain_30s/summary.md`
- `docs/13_TILED_5K60_STRATEGY.md`
- `docs/14_TRANSMISSION_PROFILE_MATRIX.md`
- `scripts/mac_transmission_profile_matrix.sh`
- `scripts/mac_single_stream_stability_matrix.sh`
- `benchmarks/runs/2026-05-15_1258_transmission_profile_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1306_transmission_profile_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1330_single_stream_stability_unset/aggregate.md`
- `benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on/aggregate.md`
- `benchmarks/runs/2026-05-15_1358_encoder_service_restart_probe/`
- `scripts/analyze_tiled_deadline.py`
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
- `DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 RUN_ROOT=benchmarks/runs/2026-05-15_1258_transmission_profile_matrix scripts/mac_transmission_profile_matrix.sh`
- `DEVICE_PROFILE=m1air PROFILE_SET=air DURATION=30 scripts/mac_transmission_profile_matrix.sh`
- `REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=unset RUN_ROOT=benchmarks/runs/2026-05-15_1330_single_stream_stability_unset scripts/mac_single_stream_stability_matrix.sh`
- `REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=on RUN_ROOT=benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on scripts/mac_single_stream_stability_matrix.sh`
- `pkill -x VTEncoderXPCService` followed by 4096x2304, 3200x1800, and 2560x1440 fallback probes.
- Windows MSVC `cl` build for `ibridge-receiver.exe`
- Windows iMac Task Scheduler D3D11 fullscreen benchmark runs
- `scripts/mac_power_probe.sh`

## Known Issues

- Plan B 5K60 compressed encode is still not viable on the current MBP Primary path.
- Tiled 5K60 encode-only p95 is now promising, but reset-frame spikes around 100-133 ms would likely be visible unless the receiver hides, drops, or staggers them.
- Single-stream fallback results are stable when isolated, but become pessimistic when run immediately after tiled 5K60. Benchmark and product profile switching should not run tiled first and then immediately judge single-stream fallback performance.
- `VTEncoderXPCService` restart alone does not clear the post-tiled slow state for 4096x2304/3200x1800. Treat 2560x1440 as the current safest post-tiled emergency fallback until a stronger reset strategy is proven.
- M1 Air should not default above `2560x1440 @ 60` based on current encode-only evidence.
- M1 Air tiled 5K60 is substantially below target in the current probe; do not spend receiver implementation time on Air-specific tiled 5K60 unless a new sender strategy changes this signal.
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

1. Use M1 Air `2560x1440 @ 60` HEVC as the realistic default candidate; only retest `3200x1800 @ 60` after profile tuning or thermal isolation.
2. Run wired sender tests on the M1 Max after Thunderbolt Bridge or 1GbE is physically connected; pair with `scripts/mac_network_matrix.sh` to classify link latency/throughput.
3. Keep 4096x2304, 3840x2160, 3200x1800, and 2560x1440 as viable isolated single-stream fallback profiles; retest them on actual wired/wireless links after cables arrive.
4. Keep 2x2 tiled HEVC 5K60 as the top full-resolution M1 Max + best-wired candidate, but do not carry that assumption to M1 Air; solve/reset-hide the reset spikes before calling it display-smooth.
5. Investigate a stronger safe reset strategy before allowing product-mode switching from tiled 5K60 down to high-detail single-stream fallback; user-level `VTEncoderXPCService` restart alone was not enough.
6. After macOS is installed on the iMac, test receiver decode separately on iMac Windows and iMac macOS: Media Foundation/D3D11 versus VideoToolbox/Metal.
7. Only after sender profiles and OS-specific decode candidates are settled, build tiled protocol metadata and receiver recomposition.
8. Implement dirty-region/cursor-separate logic after a live capture path exists, because static skipping alone only proves the encoder-side principle.
9. Capture screenshots and text-quality scoring after compressed decode/render works.
