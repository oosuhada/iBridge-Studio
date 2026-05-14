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
