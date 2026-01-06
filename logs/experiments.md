# Experiments

Summaries of benchmark runs.

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
