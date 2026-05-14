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
