# Experiment Report — Plan A 5K60 Pending Benchmark

Date: 2026-05-14 22:20 KST
Prompt: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`
Branch: `feat/plan-a-5k60-benchmark`
Commit: pending
Hardware: local MacBook Air M1 for calculation/scaffold only; Windows iMac unavailable in this session
Transport: pending LAN / Thunderbolt Bridge measurement
Mode: Plan A 5120x2880 @ 60

## Goal

Start Plan A at 5120x2880 @ 60Hz raw/near-raw feasibility. Do not downshift until calculation, local render benchmark path, and transport measurements are recorded.

## Setup

Local machine:

- MacBook Air, MacBookAir10,1
- Apple M1, 8 GB memory
- macOS 14.5 build 23F79

Receiver target:

- Windows-booted iMac 5K is required for the synthetic D3D11 renderer benchmark.
- Receiver hardware was not available from this MacBook Air session.

## Commands

Calculation verification:

```bash
WIDTH=5120; HEIGHT=2880; FPS=60
printf 'pixels_per_frame=%d\n' $((WIDTH*HEIGHT))
printf 'pixels_per_second=%d\n' $((WIDTH*HEIGHT*FPS))
printf 'rgb24_bps=%d\n' $((WIDTH*HEIGHT*FPS*24))
printf 'yuv420_bps=%d\n' $((WIDTH*HEIGHT*FPS*12))
printf 'bgra32_bps=%d\n' $((WIDTH*HEIGHT*FPS*32))
printf 'rgb24_bytes_per_frame=%d\n' $((WIDTH*HEIGHT*3))
printf 'yuv420_bytes_per_frame=%d\n' $((WIDTH*HEIGHT*3/2))
printf 'bgra32_bytes_per_frame=%d\n' $((WIDTH*HEIGHT*4))
```

Local build probe:

```bash
cmake --version
clang++ -std=c++17 -fsyntax-only apps/receiver-windows/src/main.cpp
```

Windows receiver benchmark to run on the iMac:

```powershell
cmake -S apps/receiver-windows -B apps/receiver-windows/build -G "Visual Studio 17 2022" -A x64
cmake --build apps/receiver-windows/build --config Release
mkdir benchmarks\runs\YYYY-MM-DD_HHMM_plan_a_synthetic_5k60
apps\receiver-windows\build\Release\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --csv benchmarks\runs\YYYY-MM-DD_HHMM_plan_a_synthetic_5k60\receiver_stats.csv
```

Transport benchmark to run after receiver IP is known:

```bash
scripts/mac_network_probe.sh <receiver-ip>
```

## Results

| Metric | Value |
|---|---:|
| target fps | 60 |
| frame budget | 16.667 ms |
| resolution | 5120x2880 |
| pixels per frame | 14,745,600 |
| pixels per second | 884,736,000 |
| raw RGB24 bitrate | 21.234 Gbps |
| raw RGB24 bytes/frame | 44.237 MB |
| YUV 4:2:0 8-bit bitrate | 10.617 Gbps |
| YUV 4:2:0 bytes/frame | 22.118 MB |
| BGRA32 app buffer bitrate | 28.312 Gbps |
| BGRA32 bytes/frame | 58.982 MB |
| actual receiver fps | pending Windows iMac run |
| render latency | pending Windows iMac run |
| network latency | pending receiver IP / transport run |
| dropped frames | pending Windows iMac run |

## Local Build Probe Result

- `cmake --version` failed on this MacBook Air because `cmake` is not installed.
- `clang++ -std=c++17 -fsyntax-only apps/receiver-windows/src/main.cpp` failed on this MacBook Air because the Windows SDK header `windows.h` is not available.
- This is expected for a Win32/D3D11 receiver target and is not a product-code failure. The receiver scaffold must be built on Windows with Visual Studio Build Tools or an equivalent Windows toolchain.

## Interpretation

Raw RGB24 5K60 is above the nominal Thunderbolt 2 20Gbps-class data rate before overhead. YUV 4:2:0 8-bit is below the nominal Thunderbolt 2 figure but still far above 1GbE and requires real conversion/copy/transport/render measurements.

Plan A is not declared impossible yet because the required local benchmark path now exists but has not run on the Windows iMac.

## Decision

- [x] Continue current plan
- [ ] Downshift to next plan
- [x] Needs retest on Windows iMac

## Next

1. Build and run `ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen` on the Windows iMac.
2. Run LAN `iperf3` and ping with `scripts/mac_network_probe.sh <receiver-ip>`.
3. Run Thunderbolt Bridge `iperf3` and ping if the adapter/cable path is available.
4. Write the measured run summary under `benchmarks/runs/YYYY-MM-DD_HHMM_plan_a_synthetic_5k60/summary.md`.
