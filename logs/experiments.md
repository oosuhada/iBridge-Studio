# Experiments

Summaries of benchmark runs.

## 2026-05-17 02:30 — MacBook Pro to 2017 iMac live macOS receiver smoke

Prompt: user request to continue until the MacBook screen can be extended to the 2017 4K iMac

Summary:
- Built the macOS receiver locally and on the Intel 2017 iMac.
- Restarted `ibridge-receiver-macos` on the iMac over SSH.
- Sent synthetic NV12 HEVC Annex-B protocol v0 streams from the MacBook Pro to the iMac over the measured direct 1GbE path at `169.254.70.114`.
- Added runtime receiver logging under `~/ibridge-remote/receiver-macos-runtime.log` because SSH-launched GUI stdout was not enough for reliable receiver evidence.

Measured results:

| Mode | Frames encoded | Sender drops | Send failures | Avg encode ms | P95 encode ms | Avg send ms | Receiver result |
|---|---:|---:|---:|---:|---:|---:|---|
| `1920x1080@60` HEVC | 300/300 | 0 | 0 | 13.325 | 19.448 | 0.074 | receiver logged 300 frames |
| `3840x2160@60` HEVC | 720/720 | 0 | 0 | 56.705 | 73.049 | 0.047 | receiver logged frame receipt through frame 660 before sender disconnect |

Artifacts:
- `benchmarks/runs/2026-05-17_ibridge_macos_receiver_live/summary.md`
- `benchmarks/runs/2026-05-17_ibridge_macos_receiver_live/primary_1080p_hevc.csv`
- `benchmarks/runs/2026-05-17_ibridge_macos_receiver_live/primary_4k_hevc_12s.csv`
- `docs/17_BETTERDISPLAY_AND_2017_4K_RECEIVER.md`

Decision:
- The live 2017 iMac macOS receiver plumbing works and the user saw the iMac screen change.
- Remote SSH `screencapture` did not reliably capture the AVSampleBufferDisplayLayer output, so do not use it as the deciding evidence for this path.
- The current 4K run proves live plumbing, not final smooth 4K60. Add sender backpressure/frame dropping and retest `2560x1440`, `3200x1800`, and `3840x2160`.

## 2026-05-14 22:20 — Plan A 5K60 theory and pending receiver benchmark

Prompt: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`

Summary:
- Calculated 5120x2880 @ 60 raw RGB24 at 21.234Gbps before overhead.
- Calculated 5120x2880 @ 60 YUV 4:2:0 8-bit at 10.617Gbps before overhead.
- Created the Windows D3D11 synthetic renderer benchmark path, but did not run it because this session is on macOS without the Windows SDK and without the Windows iMac receiver.

Artifacts:
- `benchmarks/theory/5k60_bandwidth.md`
- `benchmarks/plans/windows_synthetic_renderer.md`
- `benchmarks/plans/transport_benchmark.md`
- `benchmarks/runs/2026-05-14_2220_plan_a_pending/summary.md`

Decision:
- Continue Plan A until the Windows iMac local render benchmark and transport measurements exist.

## 2026-05-15 01:07 — Plan A Windows iMac synthetic 5K60 render

Prompt: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`

Summary:
- Built `ibridge-receiver.exe` on the Windows iMac with MSVC after Visual Studio Build Tools and Windows SDK were installed via GUI.
- Ran the 5120x2880 @ 60 synthetic fullscreen benchmark from the iMac interactive desktop.
- Measured actual fps at 36.034 with 2163/2163 missed frames.
- Average frame time was 27.7370 ms, p95 was 29.0890 ms, and max was 54.9967 ms.
- Average synthetic CPU fill was 14.5120 ms and average D3D11 upload was 12.9730 ms.

Artifacts:
- `benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/console.txt`
- `benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/receiver_stats.csv`
- `benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/run_status.txt`
- `benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/summary.md`

Decision:
- Plan A dynamic CPU-filled BGRA32 full-frame upload does not meet the receiver-side 5K60 gate.
- Run static-frame and no-vsync static-frame isolation tests before declaring all near-raw receiver paths failed.

## 2026-05-15 01:26 — Windows Receiver isolation suite

Prompt: `prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md`

Summary:
- Updated receiver synthetic modes so `--static-frame` uploads only once.
- Added `--gpu-pattern` to render a GPU-generated pattern without CPU fill or texture upload.
- Added `--uncapped` so no-vsync runs can measure ceiling instead of sleeping to target fps.
- Rebuilt on the Windows iMac with MSVC and ran the suite from the active console session via Task Scheduler.

Measured results:

| Mode | Actual fps | Avg fill ms | Avg upload ms | Avg draw/present ms | P95 total ms | Missed frames |
|---|---:|---:|---:|---:|---:|---:|
| dynamic_5k60 | 29.979 | 14.4046 | 18.6822 | 0.2685 | 34.2572 | 1799 / 1799 |
| static_once_upload_5k60 | 61.749 | 0.0040 | 0.0168 | 16.1721 | 16.8029 | 1684 / 3705 |
| gpu_pattern_5k60 | 61.140 | 0.0000 | 0.0000 | 16.3543 | 16.7943 | 1724 / 3669 |
| gpu_pattern_uncapped_5k60 | 290.663 | 0.0000 | 0.0000 | 3.4389 | 9.0732 | 0 / 4362 |

Decision:
- iMac D3D11 draw/present can sustain 5K60 when full-frame CPU fill/upload is removed.
- Dynamic CPU-filled BGRA32 full-frame upload is a failed Plan A receiver path.
- Receiver work should continue with low-copy/hardware surfaces and compressed decode paths rather than CPU-filled full-frame uploads.

## 2026-05-15 01:32 — Receiver HUD smoke test

Prompt: `prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md`

Summary:
- Added a lightweight top-left Win32 HUD overlay for receiver benchmark runs.
- Rebuilt `ibridge-receiver.exe` on the Windows iMac.
- Ran a short interactive desktop smoke test at 1280x720, 30fps target, GPU-pattern mode, HUD enabled.

Result:
- Process exited with code 0.
- Console output reported `hud=on`.
- Actual fps was 62.304 for the 3-second smoke test, with 0 missed frames against the 30fps frame budget.

Decision:
- HUD code does not block interactive fullscreen benchmark startup.
- Full 5K HUD overhead should be monitored in future benchmark runs.

## 2026-05-15 01:40 — Primary synthetic 1440p60 VideoToolbox encode

Prompt: `prompts/05_PRIMARY_MACOS_IMPLEMENTATION.md`

Summary:
- Added SwiftPM CLI scaffold for `apps/primary-macos`.
- Implemented synthetic BGRA frame generation and VideoToolbox H.264/HEVC encode paths.
- Wrote diagnostics CSV for generation time, encode callback latency, payload bytes, and status.

Measured results:

| Codec | Frames | Failed | Avg generate ms | Avg encode latency ms | P95 encode latency ms | Max encode latency ms | Payload bytes |
|---|---:|---:|---:|---:|---:|---:|---:|
| H.264 | 120 | 0 | 4.894 | 119.916 | 151.081 | 157.933 | 44,277,068 |
| HEVC | 120 | 0 | 4.892 | 133.649 | 162.608 | 169.744 | 43,277,169 |

Decision:
- Primary synthetic encode path is functional for both H.264 and HEVC at 1440p60.
- Current encode callback latency is too high for an external-display target and needs low-latency tuning before transport integration.

## 2026-05-15 02:38 — Plan B 5K60 compressed TCP attempts

Prompt: `prompts/03_PLAN_B_5K60_PRACTICAL.md`

Summary:
- Added protocol v0 TCP sending to the macOS Primary synthetic encoder.
- Added a no-GUI protocol v0 TCP sink to the Windows Receiver.
- Ran 5120x2880 @ 60 target H.264 and HEVC synthetic compressed tests.

Measured results:

| Test | Frames | Failed | Payload bytes | Key result |
|---|---:|---:|---:|---|
| H.264 5K60 TCP | 60 | 60 | 0 | VideoToolbox returned status -10279 for every frame. |
| HEVC 5K60 local default bitrate | 60 | 0 | 87,013,939 | Avg encode callback latency 116.081 ms. |
| HEVC 5K60 local 120Mbps | 60 | 0 | 15,356,893 | Avg encode callback latency 149.548 ms. |
| HEVC 5K60 TCP 120Mbps | 60 | 0 | 15,356,893 | Receiver got all 60 frames, but wall time was 38.60 s and measured receive throughput was 3.092 Mbps. |

Artifacts:
- `benchmarks/runs/2026-05-15_0210_plan_b_5k_h264_tcp/`
- `benchmarks/runs/2026-05-15_0220_plan_b_5k_hevc_local60/`
- `benchmarks/runs/2026-05-15_0235_plan_b_5k_hevc_120mbps_local/`
- `benchmarks/runs/2026-05-15_0238_plan_b_5k_hevc_120mbps_tcp/`

Decision:
- Plan B has been attempted at 5K60.
- H.264 fails at encode for this 5K synthetic path.
- HEVC encodes 5K60 but current latency is too high, and TCP over the current Tailscale path is a transport bottleneck.
- Decode/render remains unmeasured and must not be claimed as working.

## 2026-05-15 02:55 — Plan C scaled mode comparison

Prompt: `prompts/04_PLAN_C_60HZ_SCALED_MODES.md`

Summary:
- Added receiver source/output resolution split and `--scale-mode nearest|linear`.
- Ran iMac Windows D3D11 static scaled-render tests from the active console session.
- Ran macOS Primary HEVC 120Mbps local encode tests for each fallback source mode.

Measured receiver render results:

| Mode | Receiver fps | P95 total ms | Max total ms |
|---|---:|---:|---:|
| 1440p nearest | 59.881 | 17.476 | 25.163 |
| 1440p linear | 59.994 | 17.459 | 23.271 |
| 3200x1800 linear | 59.885 | 17.477 | 31.456 |
| 4K linear | 59.840 | 17.418 | 35.613 |
| 4096x2304 linear | 59.777 | 17.473 | 38.184 |

Measured Primary local encode results:

| Mode | Avg generate ms | Avg encode latency ms | P95 encode latency ms |
|---|---:|---:|---:|
| 1440p | 5.389 | 16.876 | 40.792 |
| 3200x1800 | 8.520 | 14.738 | 23.529 |
| 4K | 10.963 | 21.164 | 38.249 |
| 4096x2304 | 12.332 | 27.231 | 48.630 |

Decision:
- Temporary engineering default is 3200x1800 @ 60fps with linear scaling because it had the best encode latency in this sample while sustaining the receiver render test.
- Subjective text quality and screenshot samples remain pending until compressed decode/render exists.

## 2026-05-15 08:54 — Plan C sender queue and encoder low-latency probe

Prompt: focused Plan C end-to-end pipeline spike

Summary:
- Classified previous transport measurements as Tailscale / likely Wi-Fi 2.4GHz / TCP early experiments, not representative LAN or Thunderbolt Bridge results.
- Added a bounded async TCP sender queue so the VideoToolbox callback no longer performs blocking socket writes.
- Moved `kVTVideoEncoderSpecification_EnableLowLatencyRateControl` into the `VTCompressionSessionCreate` encoder specification.
- Added VideoToolbox encoder-list diagnostics and a Plan C encode matrix runner.
- Added an offline Windows Receiver Media Foundation compressed file decode/render smoke path; Windows build/run validation is pending because SSH to the iMac was not available from this session.

Measured local Primary results:

| Test | Frames | Failed | Avg encode ms | P95 encode ms | Max encode ms | Payload bytes |
|---|---:|---:|---:|---:|---:|---:|
| HEVC 2560x1440 @ 60, 120Mbps, 5s | 300 | 0 | 13.783 | 13.295 | 103.114 | 14,103,635 |
| HEVC 3200x1800 @ 60, 120Mbps, 5s | 300 | 0 | 24.293 | 65.947 | 110.441 | 22,315,381 |
| HEVC 3200x1800 @ 60, 80Mbps, KFI 120, 5s | 300 | 0 | 23.791 | 63.425 | 112.681 | 21,962,861 |
| H.264 5120x2880 @ 60, 120Mbps, 1s | 60 | 60 | 9.321 | 10.073 | 75.755 | 0 |

Transport smoke:
- Loopback TCP drain at 1280x720 HEVC sent 60/60 frames with `avg_send_ms=0.040`, `p95_send_ms=0.059`, `sender_dropped_frames=0`, and `send_failed_frames=0`.

Artifacts:
- `benchmarks/plans/network_matrix.md`
- `benchmarks/runs/2026-05-15_sender_queue_loopback_smoke/primary_stats.csv`
- `benchmarks/runs/2026-05-15_encoder_matrix_smoke/`
- `benchmarks/runs/2026-05-15_0854_encoder_lowlatency/summary.md`
- `benchmarks/runs/primary_encoder_list_latest.txt`

Decision:
- Plan C remains the next implementation path.
- 2560x1440 HEVC meets the requested avg encode latency target in this local run; 3200x1800 does not yet meet avg < 20ms after the new low-latency settings and needs additional tuning.
- H.264 5K remains a failed payload-producing path on this Primary and should not block HEVC Plan C.
- LAN and Thunderbolt Bridge tests remain pending physical setup and must be measured separately from Tailscale.

## 2026-05-15 10:12 — MacBook Pro Primary comparison

Prompt: user requested continuing iBridge from the MacBook Pro environment

Summary:
- Cloned `feat/plan-a-5k60-benchmark` under `/Users/gabriel/Development/iBridge` on `Gabriels-MacBook-Pro.local`.
- Confirmed machine is MacBook Pro `MacBookPro18,4`, Apple M1 Max, 32 GB memory, AC power.
- Current displays: built-in 3024x1964, external portrait 1080x1920, Sidecar 2360x1640, external FHD 1920x1080.
- `screencapture` captured all four displays successfully.
- Automatic low-latency encoder selection was poor on this MBP.
- Added `--encoder-id` to the Primary CLI and found forced `com.apple.videotoolbox.videoencoder.ave.hevc` with low-latency rate-control disabled gives the best Plan C signal so far.

Measured automatic encoder results:

| Test | Avg encode ms | P95 encode ms | Result |
|---|---:|---:|---|
| HEVC 2560x1440 120Mbps | 59.218 | 129.926 | too high |
| HEVC 3200x1800 120Mbps | 96.271 | 196.283 | too high |
| H.264 5120x2880 120Mbps | 8.309 | 8.684 | failed, payload 0 |

Measured forced encoder results:

| Test | Avg encode ms | P95 encode ms | Result |
|---|---:|---:|---|
| HEVC 2560x1440 120Mbps, `ave.hevc`, no low-latency RC | 17.096 | 41.361 | average passes, p95 high |
| HEVC 3200x1800 120Mbps, `ave.hevc`, no low-latency RC | 16.612 | 16.777 | strongest Plan C encode signal |
| HEVC 3840x2160 120Mbps, `ave.hevc`, no low-latency RC | 21.884 | 22.839 | near target, over 20ms avg |
| HEVC 4096x2304 120Mbps, `ave.hevc`, no low-latency RC | 24.969 | 32.502 | over target |
| HEVC 2560x1440 120Mbps, `hevc.vcp`, no low-latency RC | 643.025 | 706.557 | unusable |

Display-resolution encode probe:

| Source | Resolution | Avg encode ms | P95 encode ms |
|---|---:|---:|---:|
| Built-in XDR | 3024x1964 | 16.941 | 17.235 |
| External portrait | 1080x1920 | 9.718 | 9.559 |
| Sidecar iPad Air 5 | 2360x1640 | 16.205 | 17.276 |
| HDMI FHD | 1920x1080 | 9.498 | 9.485 |

Transport probe:
- Tailscale ping to `100.86.52.88` initially used DERP Tokyo, then direct `14.4.153.167:1050`.
- ICMP ping 20/20 received with min/avg/max/stddev `14.484/108.629/423.525/96.505 ms`.
- TCP port 22 is open, but SSH auth from this MBP is blocked because the MBP key is not accepted.

Artifacts:
- `benchmarks/runs/2026-05-15_0950_mbp_environment_baseline/summary.md`
- `benchmarks/runs/2026-05-15_0952_mbp_encoder_baseline/summary.md`
- `benchmarks/runs/2026-05-15_1000_mbp_encoder_id_probe/summary.md`
- `benchmarks/runs/2026-05-15_1005_mbp_to_imac_tailscale_probe/summary.md`
- `benchmarks/runs/2026-05-15_1010_mbp_display_capture_smoke/summary.md`
- `benchmarks/runs/2026-05-15_1012_mbp_display_resolution_encode/summary.md`

Decision:
- MacBook Pro Primary is a better candidate than the MacBook Air for Plan C HEVC if the encoder is forced to `ave.hevc`.
- Do not treat automatic low-latency encoder selection as acceptable on this MBP.
- Next live test needs Windows iMac receiver startup and/or SSH authorization from the MBP.

## 2026-05-15 10:58 — VideoToolbox reference-informed property matrix

Prompt: user pointed out that iMac connection is premature if encoding itself has only reached Plan C

Summary:
- Revisited Primary encoding using the reference analysis from Transcoding, OBS, FFmpeg, Sunshine, and Moonlight.
- Split VideoToolbox controls into explicit CLI options instead of treating machine-level speed tests as the main signal.
- Corrected the low-latency interpretation: frame reordering remains disabled, but temporal compression is now enabled by default so P-frames are allowed.
- Added optional controls for DataRateLimits, speed priority, open GOP, max frame delay count, and Annex-B payload extraction.
- Added `scripts/mac_vt_property_matrix.sh` and ran a HEVC property matrix before any iMac receiver dependency.

Measured 2-second matrix highlights:

| Mode | Avg encode ms | P95 encode ms | Result |
|---|---:|---:|---|
| 3200x1800 auto low-latency RC | 38.214 | 71.169 | too high |
| 3200x1800 `ave.hevc`, no LLRC, DataRateLimits | 12.399 | 14.106 | passes 60 Hz encode budget |
| 3840x2160 auto low-latency RC | 94.576 | 96.128 | too high |
| 3840x2160 `ave.hevc`, no LLRC, DataRateLimits | 16.158 | 25.725 | average passes, p95 high |
| 5120x2880 `ave.hevc`, no LLRC, speed priority | 47.842 | 65.002 | too high |

Measured 5-second sustained probes:

| Mode | Frames | Failed | Avg encode ms | P95 encode ms | Max encode ms |
|---|---:|---:|---:|---:|---:|
| 3200x1800 `ave.hevc`, no LLRC, DataRateLimits | 300 | 0 | 11.583 | 11.766 | 64.125 |
| 3840x2160 `ave.hevc`, no LLRC, DataRateLimits | 300 | 0 | 15.457 | 15.831 | 62.353 |
| 4096x2304 `ave.hevc`, no LLRC, DataRateLimits | 300 | 0 | 17.292 | 17.231 | 76.561 |
| 5120x2880 `ave.hevc`, no LLRC, speed priority | 300 | 0 | 100.617 | 119.982 | 123.135 |

Artifacts:
- `benchmarks/runs/2026-05-15_1056_vt_property_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1056_vt_property_matrix/summary.md`
- `benchmarks/runs/2026-05-15_1058_vt_targeted_sustain/summary.md`
- `scripts/mac_vt_property_matrix.sh`

Decision:
- The user's concern is correct: Plan B 5K60 is not satisfied before iMac connection. Current 5K HEVC encode remains far outside the 60 Hz frame budget.
- The strongest encoding-only path is now 3200x1800 or 3840x2160 HEVC with forced `ave.hevc`, low-latency rate-control disabled, temporal compression enabled, frame reordering disabled, and DataRateLimits set.
- `MaxFrameDelayCount` returned `-12900` in these probes and should be treated as unsupported for this encoder/session path.
- Next encoding work should focus on real ScreenCaptureKit/IOSurface input and possibly lower-motion/static-screen modes, not receiver connection.

## 2026-05-15 11:32 — ScreenCaptureKit, NV12, static skip, tiled, and 5K refresh matrix

Prompt: user requested all proposed encoding optimizations be tested before continuing iMac connection work

Summary:
- Added a source strategy matrix around the current best VideoToolbox profile: forced `com.apple.videotoolbox.videoencoder.ave.hevc`, low-latency rate-control disabled, temporal compression enabled, frame reordering disabled, DataRateLimits 120Mbps, speed priority on.
- Compared CPU BGRA synthetic input with synthetic NV12 input.
- Added real ScreenCaptureKit capture input.
- Simulated unchanged-screen behavior by submitting only changed frames.
- Tested 5K45 and 5K30.
- Tested a 2x2 tiled-session approximation by running four 2560x1440 HEVC sessions in parallel.

Measured 3-second highlights:

| Mode | Avg encode ms | P95 encode ms | Result |
|---|---:|---:|---|
| synthetic NV12 3840x2160 @ 60 | 11.557 | 11.906 | strong 4K60 encode-only signal |
| ScreenCaptureKit 3840x2160 @ 60 | 16.363 | 18.412 | real capture works, p95 slightly misses 60Hz budget |
| synthetic NV12 4096x2304 @ 60 | 12.898 | 13.245 | strong high-detail 60Hz candidate |
| synthetic NV12 5120x2880 @ 60 | 222.716 | 234.220 | single-session 5K60 fails |
| ScreenCaptureKit 5120x2880 @ 60 | 302.354 | 360.042 | real 5K60 capture+encode fails |
| synthetic NV12 5120x2880 @ 30 | 19.296 | 19.824 | usable for 30Hz budget, not 60Hz |
| 2x2 5K60 tile approximation | 6.496-9.528 | 10.568-11.254 | per-tile encode passes; recomposition unproven |

Artifacts:
- `benchmarks/runs/2026-05-15_1129_encode_strategy_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1129_encode_strategy_matrix/summary.md`
- `benchmarks/runs/2026-05-15_1129_encode_strategy_matrix/tile_2x2_5k60/summary.md`
- `benchmarks/runs/2026-05-15_1129_encode_strategy_matrix/targeted/sck_5k60.txt`
- `scripts/mac_encode_strategy_matrix.sh`

Decision:
- Single-session Plan B 5K60 HEVC is still not viable on the current MacBook Pro path, even with real ScreenCaptureKit input.
- NV12-style input materially improves 4K/4096x2304 encode results and should replace BGRA synthetic as the main encode benchmark path.
- The only current 5K60-shaped positive signal is tiled encoding; it requires protocol, receiver decode, synchronization, and recomposition work before it can count as a display solution.
- Recommended single-session quality candidates are now `4096x2304 @ 60` and `3840x2160 @ 60`; `5120x2880 @ 30` is a high-quality low-refresh fallback.

## 2026-05-15 12:13 — Tiled 5K60 deeper probe

Prompt: user asked to prioritize the promising 2x2 tiled 5K60 signal for Plan A/Plan B investigation.

Summary:
- Added tiled benchmark controls for logical-frame in-flight depth and periodic tile-session reset.
- Fixed tiled presentation timestamps so each tile encoder session receives 0, 1, 2... frame PTS instead of global interleaved frame IDs 0, 4, 8...
- Re-ran 2x2 tiled 5K60 with bitrate, backpressure, tile-shape, session-reset, 10-second, and 30-second sustain probes.

Key findings:
- PTS fix reduced the post-3-second no-reset failure from about 136 ms p95 to about 43 ms p95, but no-reset tiled 5K60 still fails the 16.67 ms budget after frame 180.
- Tile shape changes (`1x4`, `2x2`, `4x1`, `4x2`, `2x4`) did not remove the post-180-frame latency rise.
- Periodic session reset alone creates large reset-frame spikes and fails p95 in short 5-second runs.
- Periodic reset plus `--tile-max-inflight-logical-frames 1` is the first strong sustained tiled 5K60 encode-only pass.

Measured highlights:

| Case | Duration | Frames | Effective fps | Avg logical ms | P95 logical ms | Max logical ms | Result |
|---|---:|---:|---:|---:|---:|---:|---|
| 2x2 30Mbps/tile, no reset | 5s | 300 | 59.543 | 24.733 | 42.688 | 108.377 | Fail |
| 2x2 30Mbps/tile, reset150 | 5s | 300 | 60.003 | 17.509 | 65.848 | 111.154 | Fail |
| 2x2 30Mbps/tile, reset150, inflight1 | 5s | 300 | 60.040 | 12.255 | 12.937 | 112.592 | Pass p95, reset spike remains |
| 2x2 30Mbps/tile, reset150, inflight1 | 10s | 600 | 60.025 | 12.436 | 13.816 | 123.366 | Pass p95, reset spike remains |
| 2x2 60Mbps/tile, reset150, inflight1 | 10s | 600 | 60.005 | 12.428 | 13.814 | 127.576 | Pass p95, reset spike remains |
| 2x2 30Mbps/tile, reset150, inflight1 | 30s | 1800 | 60.002 | 12.374 | 12.920 | 132.944 | Pass p95, reset spike remains |

Artifacts:
- `benchmarks/runs/2026-05-15_1206_tiled_5k60_backpressure_probe/summary.md`
- `benchmarks/runs/2026-05-15_1207_tiled_5k60_pts_fix_probe/summary.md`
- `benchmarks/runs/2026-05-15_1209_tiled_5k60_tile_shape_probe/summary.md`
- `benchmarks/runs/2026-05-15_1211_tiled_5k60_session_reset_probe/summary.md`
- `benchmarks/runs/2026-05-15_1212_tiled_5k60_reset_sustain_10s/summary.md`
- `benchmarks/runs/2026-05-15_1213_tiled_5k60_reset_sustain_30s/summary.md`

Decision:
- Tiled 5K60 should move from "research only" to the next Plan B prototype candidate, but only with explicit caveats.
- The encode-only budget is now promising for p95, but reset-frame max spikes around 100-133 ms must be solved or hidden before calling it display-smooth.
- Next tiled work should investigate receiver protocol metadata, multi-stream decode/recomposition, and reset-spike mitigation such as staggered/prewarmed tile sessions or dropping/hiding reset frames.

## 2026-05-15 12:22 — Tiled reset interval and deadline policy

Prompt: user asked whether 2x2 tiled 5K60 can continue and whether other speed-reduction methods or current encoding trends suggest improvements.

Summary:
- Searched current primary/official encoding sources around split-frame encoding, low-latency controls, and ScreenCaptureKit queue behavior.
- Added `scripts/analyze_tiled_deadline.py` to convert tiled logical CSV results into deadline-miss counts.
- Tuned tiled session reset interval from 150 to 180 logical frames.
- Wrote `docs/13_TILED_5K60_STRATEGY.md`.

Measured reset-interval results:

| Case | Duration | Frames | Effective fps | Avg ms | P95 ms | Max ms | Late >16.67ms | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| reset150, inflight1 | 20s | 1200 | 60.008 | 13.075 | 15.210 | 128.469 | 27 | Pass |
| reset180, inflight1 | 20s | 1200 | 60.010 | 11.991 | 12.632 | 131.582 | 8 | Pass |
| reset210, inflight1 | 20s | 1200 | 60.006 | 14.300 | 31.276 | 127.290 | 147 | Fail |
| reset180, inflight1 | 30s | 1800 | 60.009 | 12.100 | 12.690 | 135.530 | 18 | Pass |

Deadline interpretation:
- In the reset180 30-second run, only 18/1800 logical frames exceeded 16.67 ms.
- Only 10/1800 logical frames exceeded 33.33 ms, matching the reset cadence.
- This supports a receiver presentation policy that reuses previous tile textures instead of stalling the full logical frame when one tile misses deadline.

Artifacts:
- `benchmarks/runs/2026-05-15_1220_tiled_5k60_reset_interval_probe/summary.md`
- `benchmarks/runs/2026-05-15_1222_tiled_5k60_reset180_sustain_30s/summary.md`
- `benchmarks/runs/2026-05-15_1222_tiled_5k60_reset180_sustain_30s/deadline_analysis.md`
- `docs/13_TILED_5K60_STRATEGY.md`
- `scripts/analyze_tiled_deadline.py`

Decision:
- Continue tiled 5K60 as the top full-resolution prototype path.
- Do not make the receiver wait for all tiles on every logical frame. Use deadline-based composition with stale-tile reuse and HUD counters.
- Keep single-session 3840x2160/4096x2304 as fallback paths while tiled receiver composition is built.

## 2026-05-15 12:54 — M1 Max sender profile quick retest

Prompt: user corrected the next step to sender/encoding profiles for M1 Max/M1 Air and wired/wireless combinations before receiver decode work.

Command:

```bash
DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 RUN_ROOT=benchmarks/runs/2026-05-15_1258_transmission_profile_matrix scripts/mac_transmission_profile_matrix.sh
```

Results:

| Profile | Avg ms | P95 ms | Max ms | Result |
|---|---:|---:|---:|---|
| M1 Max wired 2x2 tiled HEVC 5K60, 30Mbps/tile, reset180, inflight1 | 12.501 | 13.222 | 123.935 | Pass p95; reset spike remains |
| M1 Max wired single HEVC 4096x2304@60, 120Mbps | 25.717 | 46.742 | 47.979 | Fail current 60Hz budget |
| M1 Max wireless-style single HEVC 3200x1800@60, 60Mbps | 23.614 | 41.764 | 82.782 | Fail current 60Hz budget |

Deadline note:
- Tiled 5K60 had 2/300 logical frames over 16.67 ms in this quick run; both were startup/reset frames.

Interpretation:
- The full-resolution M1 Max wired path should stay focused on 2x2 tiled HEVC first.
- Single-stream fallback results are not stable across the day's runs. Re-isolate 4096x2304, 3840x2160, 3200x1800, and 2560x1440 before selecting a commercial default.
- Lower bitrate did not automatically reduce latency in this run; stronger compression can increase VideoToolbox work.

Artifacts:
- `benchmarks/runs/2026-05-15_1258_transmission_profile_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1258_transmission_profile_matrix/m1max_wired_full_5k60_tiled_hevc_synthetic_nv12_tiled_5120x2880_60fps_30mbps_deadline.md`
- `docs/14_TRANSMISSION_PROFILE_MATRIX.md`

## 2026-05-15 13:40 — M1 Max single-stream stability re-isolation

Prompt: user asked MBP Codex to continue with M1 Max single-stream instability analysis while waiting for cables and M1 Air results.

Commands:

```bash
REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=unset RUN_ROOT=benchmarks/runs/2026-05-15_1330_single_stream_stability_unset scripts/mac_single_stream_stability_matrix.sh
REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=on RUN_ROOT=benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on scripts/mac_single_stream_stability_matrix.sh
DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 RUN_ROOT=benchmarks/runs/2026-05-15_1338_transmission_profile_recheck scripts/mac_transmission_profile_matrix.sh
```

Isolated single-stream results:

| Resolution | prioritize_speed | Runs | Median p95 ms | Worst p95 ms | Pass p95 <=16.67 |
|---|---|---:|---:|---:|---:|
| 4096x2304 | unset | 3 | 13.050 | 13.059 | 3/3 |
| 3840x2160 | unset | 3 | 11.669 | 11.791 | 3/3 |
| 3200x1800 | unset | 3 | 11.250 | 11.274 | 3/3 |
| 2560x1440 | unset | 3 | 10.636 | 10.647 | 3/3 |
| 4096x2304 | on | 3 | 13.087 | 13.176 | 3/3 |
| 3840x2160 | on | 3 | 11.668 | 11.719 | 3/3 |
| 3200x1800 | on | 3 | 11.218 | 11.376 | 3/3 |
| 2560x1440 | on | 3 | 6.455 | 6.472 | 3/3 |

Order/state finding:
- Re-running the transmission quick matrix reproduced the slow fallback behavior after 2x2 tiled 5K60 ran first.
- In that mixed-order run, tiled 5K60 still passed p95: avg 12.542 ms, p95 12.741 ms.
- But immediate single-stream follow-ups were pessimistic: 4096x2304 p95 46.612 ms and 3200x1800 p95 41.956 ms.
- A direct 4096x2304 run after that was still slow after a 60-second wait: p95 46.544 ms.

Interpretation:
- Single-stream HEVC fallbacks are stable when measured in isolation.
- The instability is likely VideoToolbox encoder-service state after heavy tiled HEVC, not thermal throttling or the `prioritize_speed` flag by itself.
- Product-mode switching from tiled 5K60 down to single-stream fallback needs an explicit encoder reset/restart strategy or separate process/session boundary.

Artifacts:
- `benchmarks/runs/2026-05-15_1330_single_stream_stability_unset/aggregate.md`
- `benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on/aggregate.md`
- `benchmarks/runs/2026-05-15_1338_transmission_profile_recheck/summary.csv`
- `benchmarks/runs/2026-05-15_1341_post_tiled_recovery/`

## 2026-05-15 13:58 — Encoder service restart recovery probe

Prompt: continue MBP-side work after discovering tiled-first HEVC can poison immediate single-stream fallback results.

Summary:
- Restarted the user `VTEncoderXPCService` with `pkill -x VTEncoderXPCService`.
- Re-ran 4096x2304 fallback immediately after restart.
- Re-ran 4096x2304 after a 60-second wait.
- Re-ran 4096x2304 with `prioritize_speed=unset`.
- Checked lower fallback candidates after the slow state.

Results:

| Probe | Avg ms | P95 ms | Max ms | Result |
|---|---:|---:|---:|---|
| 4096x2304 after encoder service restart | 25.928 | 46.532 | 55.227 | Still slow |
| 4096x2304 after 60s wait | 25.692 | 46.544 | 47.904 | Still slow |
| 4096x2304 after 60s wait, speed unset | 25.724 | 46.719 | 47.720 | Still slow |
| 3200x1800 after restart, solo | 23.746 | 41.839 | 79.181 | Still slow |
| 2560x1440 after restart | 7.851 | 10.808 | 42.851 | Safe |

Interpretation:
- Restarting the user VideoToolbox encoder XPC service alone does not clear the post-tiled slow state.
- The state is likely below the user XPC process boundary, such as media-engine or driver state.
- Until a stronger reset is proven, product fallback from tiled 5K60 should either restart in a truly clean sender/session context or drop to `2560x1440@60` as the conservative emergency fallback.

Artifacts:
- `benchmarks/runs/2026-05-15_1358_encoder_service_restart_probe/`

## 2026-05-15 14:24 — VideoToolbox segment-hint reset strategy

Prompt: find a stronger encoder reset/session strategy using references.

Reference basis:
- Apple documents parallel compression sessions as requiring `MoreFramesBeforeStart`, `MoreFramesAfterEnd`, and `SourceFrameCount`.
- Apple documents `PrepareToEncodeFrames`; iBridge already calls it during compression-session configuration.
- FFmpeg and OBS VideoToolbox references also prepare compression sessions before encode.

Commands:

```bash
DURATION=6 RUN_FALLBACK=1 RUN_ROOT=benchmarks/runs/2026-05-15_1415_encoder_reset_strategy_probe scripts/mac_encoder_reset_strategy_probe.sh
DURATION=6 RUN_FALLBACK=0 RUN_ROOT=benchmarks/runs/2026-05-15_1424_encoder_reset_strategy_probe_summary_fix scripts/mac_encoder_reset_strategy_probe.sh
```

Clean summary-count run:

| Case | Effective fps | Avg ms | P95 ms | Max ms | >16.67ms | >33.33ms |
|---|---:|---:|---:|---:|---:|---:|
| baseline simultaneous reset | 60.011 | 13.199 | 14.330 | 132.700 | 7/360 | 2/360 |
| segment hints simultaneous reset | 59.995 | 13.362 | 14.158 | 134.008 | 4/360 | 2/360 |
| segment hints staggered reset | 60.016 | 13.300 | 14.243 | 113.596 | 8/360 | 4/360 |

Fallback probe after reset strategy run:

| Fallback | Avg ms | P95 ms | Max ms | Result |
|---|---:|---:|---:|---|
| 4096x2304@60 | 25.838 | 46.578 | 47.764 | still slow |
| 3200x1800@60 | 23.846 | 42.273 | 84.630 | still slow |
| 2560x1440@60 | 10.345 | 16.866 | 30.266 | borderline/safest |

Interpretation:
- VideoToolbox segment hints are a useful improvement for tiled reset frame counts.
- Staggered reset may help only if the receiver can hide stale tiles; otherwise it increases the number of reset-affected logical frames.
- This does not yet solve post-tiled high-detail fallback contamination.
- A fresh login/reboot A/B is needed because the machine was already in the slow post-tiled state before this probe.

Artifacts:
- `benchmarks/runs/2026-05-15_1415_encoder_reset_strategy_probe/`
- `benchmarks/runs/2026-05-15_1424_encoder_reset_strategy_probe_summary_fix/`

## 2026-05-15 15:53 — Clean-session fallback gate setup and dirty controls

Prompt: user asked to run the remaining clean-session test: segment-hints tiled first, then immediate 4096/3200 fallback.

Commands:

```bash
RUN_ROOT=benchmarks/runs/2026-05-15_1550_clean_session_probe_guard scripts/mac_clean_session_encoder_probe.sh
DURATION=6 FALLBACK_DURATION=5 REQUIRE_CLEAN_BOOT=0 RUN_ROOT=benchmarks/runs/2026-05-15_1552_dirty_session_encoder_probe scripts/mac_clean_session_encoder_probe.sh
DURATION=10 FALLBACK_DURATION=5 REQUIRE_CLEAN_BOOT=0 RUN_ROOT=benchmarks/runs/2026-05-15_1553_dirty_session_encoder_probe_repeat scripts/mac_clean_session_encoder_probe.sh
```

Guard result:
- The valid clean-session run was skipped because uptime was 2936 minutes and the boot time was `2026-05-13 14:55:23 +0900`.

Dirty current-session controls:

| Run | Tiled p95 ms | 4096 fallback p95 ms | 3200 fallback p95 ms | 2560 fallback p95 ms | Result |
|---|---:|---:|---:|---:|---|
| `2026-05-15_1552_dirty_session_encoder_probe` | 13.765 | 14.918 | 11.444 | 6.307 | high-detail fallback passed once |
| `2026-05-15_1553_dirty_session_encoder_probe_repeat` | 14.417 | 46.669 | 42.616 | 16.482 | high-detail fallback failed on repeat |

Interpretation:
- This is not the requested clean-session proof because the machine had been up for about two days.
- The dirty-control repeat is still useful: high-detail fallback after segment-hints tiled 5K60 is not stable enough to promote.
- Keep product fallback limited to `2560x1440@60` until a fresh-boot clean run and immediate repeat both pass.

Artifacts:
- `benchmarks/runs/2026-05-15_1550_clean_session_probe_guard/`
- `benchmarks/runs/2026-05-15_1552_dirty_session_encoder_probe/`
- `benchmarks/runs/2026-05-15_1553_dirty_session_encoder_probe_repeat/`

## 2026-05-15 13:18 — M1 Air sender profile matrix

Prompt: user asked to pull latest branch and run the sender-only Air profile matrix before receiver work

Command:

```bash
DEVICE_PROFILE=m1air PROFILE_SET=air DURATION=30 scripts/mac_transmission_profile_matrix.sh
```

Machine:
- `MacBookAir10,1`
- Apple M1, 8 CPU cores, 7 GPU cores, 8 GB memory

Results:

| Profile | Avg ms | P95 ms | Max ms | 16.67ms p95 budget | Result |
|---|---:|---:|---:|---|---|
| HEVC 2560x1440@60, 25Mbps | 8.145 | 9.296 | 20.146 | pass | Best M1 Air default |
| HEVC 3200x1800@60, 35Mbps | 18.873 | 38.897 | 325.872 | fail | Too spiky for default |
| HEVC 3840x2160@60, 45Mbps | 18.727 | 54.584 | 233.527 | fail | Too spiky for default |
| 2x2 tiled HEVC 5120x2880@60, 25Mbps/tile | 23.626 | 23.718 | 72.096 | fail | Effective 41.599 fps |

Tiled deadline note:
- `1800/1800` logical frames exceeded 16.67 ms.
- `10/1800` logical frames exceeded 33.33 ms, matching the reset cadence.

Interpretation:
- M1 Air should use `2560x1440 @ 60` HEVC as the realistic initial sender profile.
- `3200x1800 @ 60` is a retest/tuning target, not the default.
- 2x2 tiled 5K60 is not worth carrying into M1 Air receiver work based on this sender-only result; keep tiled 5K60 focused on M1 Max/best-wired unless a new encoder strategy appears.

Artifacts:
- `benchmarks/runs/2026-05-15_1306_transmission_profile_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1306_transmission_profile_matrix/m1air_wired_full_5k60_tiled_probe_hevc_synthetic_nv12_tiled_5120x2880_60fps_25mbps_deadline.md`
- `benchmarks/runs/2026-05-15_1306_transmission_profile_matrix/system_profile_sanitized.txt`

## 2026-05-15 13:45 — Next-step transport gate check

Prompt: user confirmed the M1 Air vs M1 Max tiled speed difference and asked to plan and proceed with the next step.

Plan:
- Lock M1 Air default to `2560x1440 @ 60` HEVC based on sender evidence.
- Keep M1 Max 2x2 tiled 5K60 as the only current full-resolution sender candidate.
- Before receiver work, verify whether the MacBook Pro has a usable physical transport path to the iMac.

Commands:

```bash
ssh macbook-pro 'cd ~/development/iBridge && git pull --rebase'
ssh macbook-pro 'networksetup -listallhardwareports; ifconfig ...'
ssh macbook-pro 'ping -c 20 100.86.52.88'
```

Results:
- MacBook Pro repo fast-forwarded to `a1f629d`.
- MacBook Pro active normal interface is Wi-Fi with `192.168.5.31`.
- Thunderbolt Bridge and USB/Ethernet adapter interfaces were present but inactive.
- Tailscale ping to Windows iMac `100.86.52.88`: 20/20 received, min/avg/max/stddev `9.451/73.839/507.671/107.944 ms`.

Interpretation:
- Current Tailscale path is reachable but too jittery for display-profile decisions.
- The next meaningful experiment is still a physical transport matrix: Thunderbolt Bridge first if available, otherwise 1GbE.
- Do not implement Windows tiled receiver yet; sender profile and transport gates are not both green.

Artifacts:
- `benchmarks/runs/2026-05-15_1344_mbp_current_path_probe/ping_20_imac_tailscale.txt`

## 2026-05-15 13:51 — Current Tailscale network matrix

Prompt: continue the next experiment after the transport gate check.

Command:

```bash
ssh macbook-pro 'cd ~/development/iBridge && DURATION=10 RUN_ROOT=benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix scripts/mac_network_matrix.sh --case tailscale --receiver-ip 100.86.52.88 --tailscale-name 100.86.52.88'
```

Results:
- Ping: 100 transmitted, 98 received, 2.0% packet loss.
- RTT min/avg/max/stddev: `8.198/61.867/485.532/58.935 ms`.
- `iperf3` was not installed on the MBP, so TCP/UDP throughput was not measured.
- `tailscale` CLI was not found in the MBP SSH shell, so direct/DERP status was not captured.

Interpretation:
- Current Tailscale path is reachable but not a credible display transport due to packet loss and high jitter/spikes.
- This does not downshift the M1 Max wired sender plan; it only says the current overlay path is not the right next validation path.
- Before the wired matrix, install or expose `iperf3` on both MBP and iMac, then connect Thunderbolt Bridge or 1GbE.

Artifacts:
- `benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix/tailscale/ping_100.txt`
- `benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix/tailscale/iperf3_missing.txt`
- `benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix/tailscale/tailscale_missing.txt`

## 2026-05-17 01:56 — MacBook Air to 2015 iMac Wi-Fi reachability

Prompt: user said MacBook Pro Codex is working on 2017 iMac connection and asked this MacBook Air to proceed in parallel on the 2015 iMac, focusing on 5GHz Wi-Fi because Ethernet is not connected.

Plan:
- Pull latest git state and avoid colliding with 2017 iMac work.
- Identify the 2015 iMac current Tailscale/local Wi-Fi target.
- Capture MacBook Air -> 2015 iMac Wi-Fi reachability, port state, and any throughput blockers.

Commands:

```bash
git pull --ff-only
tailscale status
ping -c 20 -i 0.2 100.84.32.31
tailscale ping --c 5 100.84.32.31
ping -c 20 -i 0.2 192.168.31.187
RUN_ROOT=benchmarks/runs/2026-05-17_0135_mba_to_2015_imac_wifi5 DURATION=10 scripts/mac_network_matrix.sh --case wifi5-2015-imac --receiver-ip 192.168.31.187 --tailscale-name 100.84.32.31
brew install iperf3
```

Results:
- Latest branch fast-forwarded from `bbc0c74` to `11d0904`.
- Tailscale identifies the 2015 iMac as `gabriels-imac27-2015` at `100.84.32.31`.
- Tailscale spot check reached it via local endpoint `192.168.31.187:41641`.
- Local Wi-Fi ping to `192.168.31.187`: 100/100 received, min/avg/max/stddev `3.819/51.446/420.666/88.334 ms`.
- TCP ports `22` and `5201` are open; TCP `48320` is refused.
- `iperf3` throughput was not measured because local MacBook Air `iperf3` is missing.
- `brew install iperf3` failed because local Homebrew cannot update cleanly and reports unsupported macOS `26.5`.
- SSH authentication to the 2015 iMac is blocked for tested users even though port 22 is open.

Interpretation:
- The MacBook Air -> 2015 iMac Wi-Fi path is reachable and appears local-direct, but current jitter is too high for display-profile decisions.
- Keep this path at reachability/prep status until SSH auth and throughput measurement are fixed.

Artifacts:
- `benchmarks/runs/2026-05-17_0135_mba_to_2015_imac_wifi5/wifi5-2015-imac/summary.md`
- `benchmarks/runs/2026-05-17_0135_mba_to_2015_imac_wifi5/wifi5-2015-imac/ping_100.txt`
- `benchmarks/runs/2026-05-17_0135_mba_to_2015_imac_wifi5/wifi5-2015-imac/port_probe.txt`
- `benchmarks/runs/2026-05-17_0135_mba_to_2015_imac_wifi5/wifi5-2015-imac/tailscale_ping_10.txt`

## 2026-05-17 02:08 — MacBook Air to 2015 iMac Wi-Fi throughput

Prompt: user repaired Homebrew enough to install `iperf3`, then ran the MacBook Air -> 2015 iMac Wi-Fi network matrix.

Command:

```bash
DURATION=20 RUN_ROOT=benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf scripts/mac_network_matrix.sh --case wifi5-2015-imac --receiver-ip 192.168.31.187 --tailscale-name 100.84.32.31
```

Results:
- Ping: 100/100 received, min/avg/max/stddev `3.690/30.495/258.942/44.687 ms`.
- TCP to receiver: `154.09 Mbps` received.
- TCP reverse from receiver: `129.43 Mbps` received.
- UDP 30Mbps: `29.99 Mbps` received, `0%` loss.
- UDP 60Mbps: `59.78 Mbps` received, `0.333%` loss.
- UDP 120Mbps: `119.95 Mbps` received, `0.003%` loss.

Interpretation:
- Throughput is adequate for conservative low-bitrate smoke tests such as the MacBook Air's `2560x1440@60` HEVC candidate.
- ICMP still has repeated 100-250ms latency spikes, so do not treat this Wi-Fi path as smooth-display evidence.
- Keep 5K, tiled 5K, and high-detail fallback decisions blocked on wired transport.

Artifacts:
- `benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf/wifi5-2015-imac/summary.md`
- `benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf/wifi5-2015-imac/iperf3_tcp_to_receiver.json`
- `benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf/wifi5-2015-imac/iperf3_tcp_from_receiver_reverse.json`
- `benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf/wifi5-2015-imac/iperf3_udp_30mbps.json`
- `benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf/wifi5-2015-imac/iperf3_udp_60mbps.json`
- `benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf/wifi5-2015-imac/iperf3_udp_120mbps.json`

## 2026-05-17 02:35 — MacBook Air to 2015 iMac 1440p60 HEVC visual smoke

Prompt: user asked to continue after MacBook Air SSH access to the 2015 iMac was fixed.

Plan:
- Build `apps/primary-macos` locally and `apps/receiver-macos` on the 2015 iMac.
- Run the macOS receiver on `oosu@100.84.32.31` listening on TCP `48320`.
- Send the conservative MacBook Air profile: `2560x1440 @ 60`, HEVC, Annex-B, 25Mbps, over local Wi-Fi to `192.168.31.187`.

Commands:

```bash
swift build --package-path apps/primary-macos -c release
swift build --package-path apps/receiver-macos -c release
ssh -i ~/.ssh/ibridge_imac_ed25519 oosu@100.84.32.31 'cd ~/development/iBridge && swift build --package-path apps/receiver-macos -c release'
ssh -i ~/.ssh/ibridge_imac_ed25519 oosu@100.84.32.31 'nohup ~/development/iBridge/apps/receiver-macos/.build/release/ibridge-receiver-macos --port 48320 --fullscreen ... &'
apps/primary-macos/.build/release/ibridge-primary --synthetic --source synthetic-nv12 --resolution 2560x1440 --fps 60 --duration 30 --codec hevc --bitrate-mbps 25 --data-rate-limit-mbps 25 --disable-low-latency-rate-control --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc --disable-frame-reordering --disable-open-gop --payload-format annex-b --send-host 192.168.31.187 --send-port 48320
```

Results:
- Receiver handshake succeeded with `selected_codec=hevc`, `width=2560`, `height=1440`, `fps=60`, `frame_transport=tcp`.
- Sender requested/submitted/encoded `1800/1800/1800` frames.
- Sender send failures: `0`.
- Sender queue drops: `2`.
- Sender p95 encode latency: `9.730 ms`; max encode latency: `34.592 ms`.
- Sender p95 send time: `0.096 ms`; max send time: `95.444 ms`.
- Receiver total frames: `1798`.
- Receiver missing-frame events: two 1-frame gaps before frames `1407` and `1437`.
- User reported visible change on the iMac panel during the smoke.

Interpretation:
- This proves the MacBook Air -> 2015 iMac macOS receiver path can encode, send, receive, and visibly affect the iMac display at conservative 1440p60 HEVC over Wi-Fi.
- This is not a smooth-display pass because the Wi-Fi path still has latency spikes and the smoke had 2 dropped/missing frames over 30 seconds.
- Keep 5K, tiled 5K, and high-detail fallback blocked on wired transport.

Artifacts:
- `benchmarks/runs/2026-05-17_0235_mba_to_2015_imac_1440p60_hevc_wifi_30s_visual/summary.md`
- `benchmarks/runs/2026-05-17_0235_mba_to_2015_imac_1440p60_hevc_wifi_30s_visual/primary_stats.csv`
- `benchmarks/runs/2026-05-17_0235_mba_to_2015_imac_1440p60_hevc_wifi_30s_visual/receiver_console.txt`

## 2026-05-17 02:53 — MacBook Air to 2015 iMac live capture script

Prompt: user asked whether any-quality external monitor use is possible and asked to complete the app path.

Results:
- Live screen capture over Wi-Fi works as a mirror-style display path.
- 10s direct live-capture smoke at `2560x1440@30` HEVC 15Mbps: sender `300/300` encoded, 0 send failures, 1 sender queue drop; receiver `299` frames.
- 3s helper-script validation at the same profile: sender `90/90` encoded, 0 send failures, 0 sender queue drops.
- Added helper scripts to start the 2015 iMac receiver, start a long-running MacBook Air live capture session, and stop the receiver.

Interpretation:
- MacBook Air can now connect to the 2015 iMac as a practical mirror/live-capture display over Wi-Fi.
- This is not yet a true macOS extended desktop. The next product milestone is adding or integrating a virtual display source on the MacBook Air, then capturing that display with the existing ScreenCaptureKit path.

Artifacts:
- `benchmarks/runs/2026-05-17_0248_mba_to_2015_imac_live_capture_1440p30_wifi/`
- `benchmarks/runs/2026-05-17_0253_script_live_capture_smoke/`
- `scripts/start_2015_imac_receiver_macos.sh`
- `scripts/start_mba_to_2015_imac_live_capture.sh`
- `scripts/stop_2015_imac_receiver_macos.sh`

## 2026-05-17 03:36 — Virtual 16:9 extended display target

Prompt: user configured macOS `Virtual 16:9` as an extended display at `1920x1080`.

Results:
- Local Wi-Fi IP `192.168.31.187` was temporarily unreachable from the MacBook Air, but Tailscale `100.84.32.31` reached the same receiver.
- `capture-display-index 1` successfully sent a `1920x1080@30` HEVC stream to the 2015 iMac receiver.
- Receiver logged protocol v0 handshake for `width=1920`, `height=1080`, `fps=30`.
- Default helper script profile changed to `Virtual 16:9`: display index `1`, `1920x1080@30`, HEVC 8Mbps, receiver `100.84.32.31`.
- 3s helper-script validation: requested/submitted/encoded `90/28/28`, failed frames `0`, send failures `0`, sender queue drops `0`.

Interpretation:
- iBridge now has an immediate extended-display-style workflow when the virtual display is already created by macOS/BetterDisplay/OCLP tooling: move windows to `Virtual 16:9`, then run the iBridge sender to show that virtual display on the iMac.
- Low submitted-frame count is expected when the virtual display is mostly static; move the cursor or a window on that display to force visible updates.

Artifacts:
- `benchmarks/runs/2026-05-17_0333_mba_virtual_1080p30_to_2015_imac_tailscale/`
- `benchmarks/runs/2026-05-17_0336_virtual_16_9_script_default_smoke/`
