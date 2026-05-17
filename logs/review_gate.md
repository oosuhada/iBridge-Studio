# Review Gate

## 2026-05-15 01:20 — Prompt 09 after Prompt 02

Prompt reviewed: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`

## Summary

Pass with follow-up isolation required.

Prompt 02 stayed on Plan A and did not downshift to lower resolutions. It produced the required bandwidth theory, Windows synthetic renderer scaffold, transport benchmark plan, and a measured Windows iMac synthetic 5K60 run. The measured dynamic CPU-filled BGRA32 full-frame upload path failed the 5K60 receiver-side gate, but Plan A as a whole is not fully closed until static-frame/no-vsync isolation tests separate CPU fill cost from upload/present cost.

## Changed Files

- `apps/receiver-windows/CMakeLists.txt`
- `apps/receiver-windows/README.md`
- `apps/receiver-windows/src/main.cpp`
- `benchmarks/theory/5k60_bandwidth.md`
- `benchmarks/plans/windows_synthetic_renderer.md`
- `benchmarks/plans/transport_benchmark.md`
- `benchmarks/runs/2026-05-14_2220_plan_a_pending/summary.md`
- `benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/*`
- `logs/experiments.md`
- `logs/questions.md`
- `logs/worklog.md`

## Verification Commands / Results

```bash
git diff --check
```

Result: passed.

```powershell
apps\receiver-windows\build\manual\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --csv "%RUN_DIR%\receiver_stats.csv"
```

Result: ran from the Windows iMac interactive desktop and wrote `receiver_stats.csv`.

## Benchmarks

Plan A synthetic local render on iMac Windows:

| Metric | Value |
|---|---:|
| target fps | 60 |
| actual fps | 36.034 |
| frames | 2163 |
| p95 total frame | 29.0890 ms |
| max total frame | 54.9967 ms |
| missed frames | 2163 / 2163 |
| avg fill | 14.5120 ms |
| avg upload | 12.9730 ms |
| avg draw/present | 0.2519 ms |

## Known Failures

- Dynamic 5120x2880 CPU-filled BGRA32 full-frame upload misses every 16.667 ms frame budget.
- SSH-launched D3D11 swapchain creation fails with `0x887a0022`; benchmarks must run from the active Windows console session.
- LAN and Thunderbolt Bridge transport measurements are still pending.

## Review Questions

1. Did this stage only do the requested goal? Yes.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes; Windows build and interactive desktop benchmark were run.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No; unresolved transport tests remain pending.
7. Was Plan downshift measured? No downshift yet; measured pressure is recorded.

## Next Prompt To Run

`prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md`

## 2026-05-15 01:35 — Prompt 09 after Prompt 06

Prompt reviewed: `prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md`

## Summary

Pass for receiver local benchmark milestone; remaining receiver networking/decode work is explicitly open.

The Windows Receiver now builds on the iMac, opens fullscreen from the active Windows desktop, runs synthetic benchmark modes, logs actual fps and frame timings to CSV, and displays a lightweight HUD overlay. The local D3D11 renderer has been measured at 5K with dynamic, static, GPU-pattern, and uncapped modes.

## Changed Files

- `apps/receiver-windows/README.md`
- `apps/receiver-windows/src/main.cpp`
- `benchmarks/runs/2026-05-15_0126_receiver_isolation_suite/*`
- `logs/experiments.md`
- `logs/worklog.md`

## Verification Commands / Results

Windows iMac build:

```cmd
cl /nologo /EHsc /std:c++17 /O2 /W4 /DUNICODE /D_UNICODE /DNOMINMAX /DWIN32_LEAN_AND_MEAN apps\receiver-windows\src\main.cpp /Fe:apps\receiver-windows\build\manual\ibridge-receiver.exe /link d3d11.lib dxgi.lib d3dcompiler.lib user32.lib gdi32.lib
```

Result: passed.

Interactive desktop smoke test:

```cmd
ibridge-receiver.exe --synthetic --resolution 1280x720 --fps 30 --duration 3 --fullscreen --gpu-pattern --csv receiver_stats.csv
```

Result: exited 0, `hud=on`, 62.304 fps, 0 missed frames against a 30fps budget.

## Benchmarks

| Mode | Actual fps | Avg fill ms | Avg upload ms | Avg draw/present ms | P95 total ms | Missed frames |
|---|---:|---:|---:|---:|---:|---:|
| dynamic_5k60 | 29.979 | 14.4046 | 18.6822 | 0.2685 | 34.2572 | 1799 / 1799 |
| static_once_upload_5k60 | 61.749 | 0.0040 | 0.0168 | 16.1721 | 16.8029 | 1684 / 3705 |
| gpu_pattern_5k60 | 61.140 | 0.0000 | 0.0000 | 16.3543 | 16.7943 | 1724 / 3669 |
| gpu_pattern_uncapped_5k60 | 290.663 | 0.0000 | 0.0000 | 3.4389 | 9.0732 | 0 / 4362 |

## Known Failures

- Dynamic CPU-filled 5K BGRA full-frame upload is not viable for 5K60.
- SSH-launched D3D11 windows still cannot substitute for interactive desktop tests.
- Network receive, H.264 decode, HEVC decode, and scaling comparison remain open receiver work.
- HUD is lightweight and smoke-tested, but not yet visually screenshot-verified.

## Review Questions

1. Did this stage only do the requested goal? Yes, within Windows Receiver scope.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes, on the Windows iMac.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No.
7. Was Plan downshift measured? Only receiver-path failure pressure was recorded; no full Plan downshift yet.

## Next Prompt To Run

`prompts/05_PRIMARY_MACOS_IMPLEMENTATION.md`

## 2026-05-15 01:45 — Prompt 09 after Prompt 05

Prompt reviewed: `prompts/05_PRIMARY_MACOS_IMPLEMENTATION.md`

## Summary

Pass for Primary synthetic encode milestone; ScreenCaptureKit capture and transport remain open.

The macOS Primary now has a SwiftPM CLI that generates synthetic BGRA frames, encodes with VideoToolbox H.264 or HEVC, and writes diagnostics CSV. Both H.264 and HEVC encoded 120/120 frames at a 2560x1440 @ 60fps target over a 2-second run.

## Changed Files

- `.gitignore`
- `apps/primary-macos/Package.swift`
- `apps/primary-macos/README.md`
- `apps/primary-macos/Sources/iBridgePrimary/main.swift`
- `benchmarks/runs/2026-05-15_0140_primary_1440p60_h264/*`
- `benchmarks/runs/2026-05-15_0140_primary_1440p60_hevc/*`
- `logs/experiments.md`
- `logs/worklog.md`

## Verification Commands / Results

```bash
swift build --package-path apps/primary-macos -c release
```

Result: passed.

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec h264 --csv benchmarks/runs/2026-05-15_0140_primary_1440p60_h264/primary_stats.csv
```

Result: encoded 120/120 frames, 0 failed frames.

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec hevc --csv benchmarks/runs/2026-05-15_0140_primary_1440p60_hevc/primary_stats.csv
```

Result: encoded 120/120 frames, 0 failed frames.

## Benchmarks

| Codec | Frames | Failed | Avg generate ms | Avg encode latency ms | P95 encode latency ms | Max encode latency ms | Payload bytes |
|---|---:|---:|---:|---:|---:|---:|---:|
| H.264 | 120 | 0 | 4.894 | 119.916 | 151.081 | 157.933 | 44,277,068 |
| HEVC | 120 | 0 | 4.892 | 133.649 | 162.608 | 169.744 | 43,277,169 |

## Known Failures

- Encode callback latency is too high for external-display use.
- ScreenCaptureKit capture is not implemented yet.
- Transport client is not implemented yet.
- Virtual display research remains intentionally separate.

## Review Questions

1. Did this stage only do the requested goal? Yes, within the synthetic encode milestone.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes, on the MacBook Air.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No.
7. Was Plan downshift measured? No downshift occurred.

## Next Prompt To Run

`prompts/07_PROTOCOL_AND_TRANSPORT.md`

## 2026-05-15 01:56 — Prompt 09 after Prompt 07

Prompt reviewed: `prompts/07_PROTOCOL_AND_TRANSPORT.md`

## Summary

Pass for protocol v0 definition and parser-test milestone.

Protocol v0 now has a concrete TCP control handshake, UDP frame channel shape, TCP frame fallback, ping/echo clock-offset estimate, and fixed binary frame header. The shared parser test locks the 80-byte header layout and verifies wrong magic/wrong version rejection before payload acceptance.

## Changed Files

- `apps/shared-protocol/README.md`
- `apps/shared-protocol/protocol_v0.py`
- `apps/shared-protocol/test_protocol_v0.py`
- `specs/protocol_v0.md`
- `logs/worklog.md`

## Verification Commands / Results

```bash
python3 apps/shared-protocol/test_protocol_v0.py
```

Result: passed, 8 tests.

```bash
git diff --check
```

Result: passed.

## Benchmarks

No performance benchmark was required for Prompt 07. This was a protocol/schema/test milestone.

## Known Failures

- Protocol v0 is not yet wired into the macOS Primary sender.
- Protocol v0 is not yet wired into the Windows Receiver.
- UDP fragmentation/reassembly, TCP frame fallback runtime code, and clock-probe runtime code are specified but not implemented.
- End-to-end latency cannot be measured until Prompt 03 transport integration exists.

## Review Questions

1. Did this stage only do the requested goal? Yes.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes, parser tests ran locally.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No hardware claims were added.
7. Was Plan downshift measured? No downshift occurred.

## Next Prompt To Run

`prompts/03_PLAN_B_5K60_PRACTICAL.md`

## 2026-05-15 02:45 — Prompt 09 after Prompt 03

Prompt reviewed: `prompts/03_PLAN_B_5K60_PRACTICAL.md`

## Summary

Pass with known decode/render gap.

Prompt 03 made a real 5K compressed attempt instead of downshifting directly. The macOS Primary can now send protocol v0 TCP frame payloads, and the Windows Receiver can run a no-GUI protocol v0 TCP sink. H.264 5K60 failed at encode with zero payloads. HEVC 5K60 encoded, but latency was far above the 60Hz budget, and the current Tailscale TCP path was far too slow for even a 120Mbps 5K60 compressed stream.

## Changed Files

- `apps/primary-macos/README.md`
- `apps/primary-macos/Sources/iBridgePrimary/main.swift`
- `apps/receiver-windows/CMakeLists.txt`
- `apps/receiver-windows/README.md`
- `apps/receiver-windows/src/main.cpp`
- `benchmarks/runs/2026-05-15_0210_plan_b_5k_h264_tcp/*`
- `benchmarks/runs/2026-05-15_0220_plan_b_5k_hevc_local60/*`
- `benchmarks/runs/2026-05-15_0235_plan_b_5k_hevc_120mbps_local/*`
- `benchmarks/runs/2026-05-15_0238_plan_b_5k_hevc_120mbps_tcp/*`
- `logs/experiments.md`
- `logs/worklog.md`

## Verification Commands / Results

```bash
swift build --package-path apps/primary-macos -c release
```

Result: passed.

```bash
python3 apps/shared-protocol/test_protocol_v0.py
```

Result: passed, 8 tests.

```bash
git diff --check
```

Result: passed.

Windows iMac MSVC build:

```cmd
cl /nologo /EHsc /std:c++17 /O2 /W4 /DUNICODE /D_UNICODE /DNOMINMAX /DWIN32_LEAN_AND_MEAN apps\receiver-windows\src\main.cpp /Fe:apps\receiver-windows\build\manual\ibridge-receiver.exe /link d3d11.lib dxgi.lib d3dcompiler.lib user32.lib gdi32.lib ws2_32.lib
```

Result: passed.

## Benchmarks

| Test | Frames | Failed | Payload bytes | Main result |
|---|---:|---:|---:|---|
| H.264 5K60 TCP | 60 | 60 | 0 | VideoToolbox status -10279 for every frame. |
| HEVC 5K60 local default bitrate | 60 | 0 | 87,013,939 | Avg encode callback latency 116.081 ms. |
| HEVC 5K60 local 120Mbps | 60 | 0 | 15,356,893 | Avg encode callback latency 149.548 ms. |
| HEVC 5K60 TCP 120Mbps | 60 | 0 | 15,356,893 | Receiver got 60/60 frames, but wall time was 38.60 s and measured receive throughput was 3.092 Mbps. |

## Known Failures

- Windows compressed decode is not implemented yet, so decode/render latency is not measured.
- H.264 5K60 did not produce payloads on this Primary path.
- HEVC 5K60 encode callback latency is too high for external-display use.
- TCP over the current Tailscale path is too slow for 5K60 compressed streaming.
- Blocking send occurs inside the encode callback and inflates latency; sender queueing is required before any fair end-to-end latency claim.
- Code editor, terminal scroll, and mouse movement visual tests could not be performed because decode/render is not implemented.

## Review Questions

1. Did this stage only do the requested goal? Yes, within the Plan B compressed path.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes; macOS build, Windows build, and iMac TCP sink runs were executed.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No; measured results are separated from unmeasured decode/render gaps.
7. Was Plan downshift measured? Yes. Plan C is now justified by H.264 encode failure, HEVC latency, and current transport throughput.

## Next Prompt To Run

`prompts/04_PLAN_C_60HZ_SCALED_MODES.md`

## 2026-05-15 03:02 — Prompt 09 after Prompt 04

Prompt reviewed: `prompts/04_PLAN_C_60HZ_SCALED_MODES.md`

## Summary

Pass for engineering-mode comparison, with visual quality pending.

Prompt 04 added receiver source/output resolution separation and `nearest|linear` scaling, then measured the required fallback resolutions against 5120x2880 output. It also measured Primary HEVC 120Mbps local encode cost for each fallback source mode. All receiver static scaled-render runs sustained about 60fps. `3200x1800 @ 60fps, linear` is the temporary engineering default based on the best short-run encode latency, but it is not yet a user-facing default because text screenshots and compressed decode/render are missing.

## Changed Files

- `apps/receiver-windows/README.md`
- `apps/receiver-windows/src/main.cpp`
- `benchmarks/runs/2026-05-15_0255_plan_c_scaled_modes/*`
- `logs/experiments.md`
- `logs/worklog.md`
- `specs/protocol_v0.md`

## Verification Commands / Results

```bash
swift build --package-path apps/primary-macos -c release
```

Result: passed.

```bash
python3 apps/shared-protocol/test_protocol_v0.py
```

Result: passed, 8 tests.

```bash
git diff --check
```

Result: passed.

Windows iMac MSVC build:

```cmd
cl /nologo /EHsc /std:c++17 /O2 /W4 /DUNICODE /D_UNICODE /DNOMINMAX /DWIN32_LEAN_AND_MEAN apps\receiver-windows\src\main.cpp /Fe:apps\receiver-windows\build\manual\ibridge-receiver.exe /link d3d11.lib dxgi.lib d3dcompiler.lib user32.lib gdi32.lib ws2_32.lib
```

Result: passed.

## Benchmarks

Receiver scaled-render to 5120x2880:

| Mode | Receiver fps | P95 total ms | Max total ms |
|---|---:|---:|---:|
| 1440p nearest | 59.881 | 17.476 | 25.163 |
| 1440p linear | 59.994 | 17.459 | 23.271 |
| 3200x1800 linear | 59.885 | 17.477 | 31.456 |
| 4K linear | 59.840 | 17.418 | 35.613 |
| 4096x2304 linear | 59.777 | 17.473 | 38.184 |

Primary HEVC 120Mbps local encode:

| Mode | Avg generate ms | Avg encode latency ms | P95 encode latency ms |
|---|---:|---:|---:|
| 1440p | 5.389 | 16.876 | 40.792 |
| 3200x1800 | 8.520 | 14.738 | 23.529 |
| 4K | 10.963 | 21.164 | 38.249 |
| 4096x2304 | 12.332 | 27.231 | 48.630 |

## Known Failures

- No compressed decode/render path yet, so mode comparison is not end-to-end.
- No screenshot samples or subjective text scores yet.
- Bicubic/sharpen scaling is not implemented; only nearest and linear are available.
- Static scaled-render runs measure present/scaling cost, not video decode cost.

## Review Questions

1. Did this stage only do the requested goal? Yes, except screenshot scoring was explicitly left pending because decode/render is absent.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes; Windows iMac and macOS runs were executed.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No.
7. Was Plan downshift measured? Yes; Plan C followed measured Plan B failures.

## Next Prompt To Run

`prompts/08_POWER_PROBE.md`

## 2026-05-15 03:12 — Prompt 09 after Prompt 08

Prompt reviewed: `prompts/08_POWER_PROBE.md`

## Summary

Pass for probe setup, with physical cable tests pending.

Prompt 08 added a macOS power collection script and `logs/power_probe.md` with a manual test matrix for no cable, iMac USB-A, iMac TB2-to-TB3 adapter, and PD hub baseline. The current MacBook Air snapshot was measured as battery power at 98%, not charging, with no AC charger connected.

## Changed Files

- `.gitignore`
- `logs/power_probe.md`
- `logs/worklog.md`
- `scripts/mac_power_probe.sh`

## Verification Commands / Results

```bash
scripts/mac_power_probe.sh
```

Result: passed; wrote ignored raw artifacts under `logs/power/2026-05-15_082738/`.

```bash
pmset -g batt
```

Result: Battery Power, 98%, discharging.

```bash
system_profiler SPPowerDataType
```

Result: AC charger connected: No; charging: No.

```bash
ioreg -rn AppleSmartBattery
```

Result: `ExternalConnected` No and `ExternalChargeCapable` No in current baseline snapshot.

## Benchmarks

No drain-rate benchmark completed because cable changes require physical intervention.

## Known Failures

- USB-A and TB2 power cases are not measured yet.
- Idle vs streaming drain-rate comparisons are not measured yet.
- No wattage can be claimed for iMac USB-A or TB2.
- The current result is only a no-cable/current-state baseline snapshot, not a full power conclusion.

## Review Questions

1. Did this stage only do the requested goal? Yes.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes; macOS power commands and script ran locally.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No; cable tests are pending.
7. Was Plan downshift measured? Not applicable.

## Next Prompt To Run

`prompts/10_PACKAGING_AND_RELEASE.md` is blocked until compressed decode/render and at least one end-to-end display mode work. Recommended next engineering prompt is a focused decoder/render integration spike, not packaging.

## 2026-05-15 08:54 — Prompt 09 after focused Plan C pipeline spike setup

Prompt reviewed: user-requested sender queue, network matrix, low-latency encoder, and decode/render spike setup

## Summary

Pass for macOS sender/encoder and benchmark-prep work; partial for Windows decode/render because implementation exists but Windows build/run validation is pending.

This spike correctly did not proceed to packaging and did not re-center 5K60 single-stream work. It classified earlier transport results as Tailscale / likely Wi-Fi 2.4GHz / TCP early data, added LAN/Thunderbolt matrix scripts for later physical testing, separated VideoToolbox callback timing from TCP send timing, added low-latency encoder specification at session creation, and added an offline Media Foundation decode/render path for the Windows Receiver.

## Changed Files

- `apps/primary-macos/README.md`
- `apps/primary-macos/Sources/iBridgePrimary/main.swift`
- `apps/receiver-windows/CMakeLists.txt`
- `apps/receiver-windows/README.md`
- `apps/receiver-windows/src/main.cpp`
- `benchmarks/plans/network_matrix.md`
- `benchmarks/runs/2026-05-15_0854_encoder_lowlatency/*`
- `docs/04_SOURCE_LEDGER.md`
- `docs/current-work.md`
- `logs/experiments.md`
- `logs/worklog.md`
- `scripts/mac_network_matrix.sh`
- `scripts/mac_plan_c_encode_matrix.sh`
- `scripts/windows_network_matrix.ps1`

## Verification Commands / Results

```bash
swift build --package-path apps/primary-macos -c release
```

Result: passed.

```bash
apps/primary-macos/.build/release/ibridge-primary --list-encoders
```

Result: passed and recorded `benchmarks/runs/primary_encoder_list_latest.txt`.

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 1280x720 --fps 60 --duration 1 --codec hevc --bitrate-mbps 20 --send-host 127.0.0.1 --send-port 48320 --sender-queue-depth 4
```

Result: loopback TCP drain sent 60/60 frames with no sender drops or send failures.

```bash
LIMIT_CASES=1 DURATION=1 RUN_ROOT=benchmarks/runs/2026-05-15_encoder_matrix_smoke scripts/mac_plan_c_encode_matrix.sh
```

Result: passed one matrix case and wrote summary artifacts.

Windows MSVC build: skipped. SSH to `100.86.52.88` failed with `Permission denied`, and the MacBook Air does not have Windows SDK headers/libraries.

## Benchmarks

| Test | Frames | Failed | Avg encode ms | P95 encode ms | Max encode ms | Payload bytes |
|---|---:|---:|---:|---:|---:|---:|
| HEVC 2560x1440 @ 60, 120Mbps, 5s | 300 | 0 | 13.783 | 13.295 | 103.114 | 14,103,635 |
| HEVC 3200x1800 @ 60, 120Mbps, 5s | 300 | 0 | 24.293 | 65.947 | 110.441 | 22,315,381 |
| H.264 5120x2880 @ 60, 120Mbps, 1s | 60 | 60 | 9.321 | 10.073 | 75.755 | 0 |

## Known Failures

- 3200x1800 HEVC did not meet avg encode latency < 20ms in the local sequential run.
- H.264 5K still produced zero payloads.
- Windows compressed file decode/render is implemented but unbuilt/unmeasured on the iMac.
- Protocol v0 live compressed TCP decode/render is not implemented yet.
- LAN, 5GHz Wi-Fi, 1GbE, and Thunderbolt Bridge measurements remain pending physical setup.

## Review Questions

1. Did this stage only do the requested goal? Yes; packaging, UDP, tiled 5K, ScreenCaptureKit, and virtual display work were not started.
2. Did it start the next prompt early? No.
3. Was build/run verification real? macOS verification was real; Windows verification is explicitly pending.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No; LAN/TB and Windows decoder support are pending.
7. Was Plan downshift measured? Existing Plan B failures remain recorded; this spike keeps Plan C as the immediate path.

## Next Prompt To Run

Focused Windows receiver decode validation and live protocol v0 TCP decode/render integration. Do not run `prompts/10_PACKAGING_AND_RELEASE.md`.

## 2026-05-15 10:12 — Prompt 09 after MacBook Pro Primary comparison

Prompt reviewed: user-requested MacBook Pro clone and environment tests

## Summary

Pass for MacBook Pro Primary baseline and display/capture smoke testing; live receiver validation remains blocked by Windows iMac SSH/auth and receiver startup.

The branch was cloned to `/Users/gabriel/Development/iBridge` on the M1 Max MacBook Pro. Local Swift build and protocol tests passed. Current displays include built-in XDR, external portrait display, Sidecar, and external FHD display; all four were captured with `screencapture`. Automatic VideoToolbox low-latency selection was poor on this MBP, but forcing `com.apple.videotoolbox.videoencoder.ave.hevc` while disabling low-latency rate-control produced the best Plan C encode result so far.

## Changed Files

- `apps/primary-macos/README.md`
- `apps/primary-macos/Sources/iBridgePrimary/main.swift`
- `benchmarks/runs/2026-05-15_0950_mbp_environment_baseline/*`
- `benchmarks/runs/2026-05-15_0952_mbp_encoder_baseline/*`
- `benchmarks/runs/2026-05-15_1000_mbp_encoder_id_probe/*`
- `benchmarks/runs/2026-05-15_1005_mbp_to_imac_tailscale_probe/*`
- `benchmarks/runs/2026-05-15_1010_mbp_display_capture_smoke/*`
- `benchmarks/runs/2026-05-15_1012_mbp_display_resolution_encode/*`
- `docs/current-work.md`
- `logs/experiments.md`
- `logs/worklog.md`

## Verification Commands / Results

```bash
swift build --package-path apps/primary-macos -c release
```

Result: passed.

```bash
python3 apps/shared-protocol/test_protocol_v0.py
```

Result: passed, 8 tests.

```bash
apps/primary-macos/.build/release/ibridge-primary --list-encoders
```

Result: passed and recorded encoder IDs.

```bash
screencapture -x -D <display> benchmarks/runs/2026-05-15_1010_mbp_display_capture_smoke/display_<display>.png
```

Result: captured built-in, external portrait, Sidecar, and external FHD displays.

## Benchmarks

| Test | Avg encode ms | P95 encode ms | Result |
|---|---:|---:|---|
| HEVC 3200x1800 120Mbps, automatic low-latency | 96.271 | 196.283 | failed for Plan C |
| HEVC 3200x1800 120Mbps, forced `ave.hevc`, no low-latency RC | 16.612 | 16.777 | strongest Plan C signal |
| HEVC 3840x2160 120Mbps, forced `ave.hevc`, no low-latency RC | 21.884 | 22.839 | close but above 20ms avg |
| H.264 5120x2880 120Mbps | 8.309 | 8.684 | failed, payload 0 |

Display-resolution forced `ave.hevc` probe:

| Source | Resolution | Avg encode ms | P95 encode ms |
|---|---:|---:|---:|
| Built-in XDR | 3024x1964 | 16.941 | 17.235 |
| External portrait | 1080x1920 | 9.718 | 9.559 |
| Sidecar | 2360x1640 | 16.205 | 17.276 |
| External FHD | 1920x1080 | 9.498 | 9.485 |

## Known Failures

- `--encoder-id` combined with `EnableLowLatencyRateControl` returned `VTCompressionSessionCreate -12902` on this MBP.
- `hevc.vcp` forced encoder had very high latency and is not suitable.
- Windows iMac port 22 is open, but SSH auth from the MBP is blocked.
- Receiver port `48320` was not listening during the probe.
- ScreenCaptureKit live capture is still not implemented in iBridge.

## Review Questions

1. Did this stage only do the requested goal? Yes; it stayed on MBP environment testing and did not start packaging.
2. Did it start the next prompt early? No.
3. Was build/run verification real? Yes for MBP local tests; Windows live receiver remains pending.
4. Are logs saved? Yes.
5. Were failures hidden? No.
6. Were hardware facts guessed? No; display state and Tailscale behavior were measured.
7. Was Plan downshift measured? Plan C remains the active path; MBP adds a stronger Plan C encode result.

## Next Prompt To Run

Authorize MBP SSH to the Windows iMac or manually start the receiver, then run live TCP Plan C using forced `ave.hevc`. Do not run `prompts/10_PACKAGING_AND_RELEASE.md`.
