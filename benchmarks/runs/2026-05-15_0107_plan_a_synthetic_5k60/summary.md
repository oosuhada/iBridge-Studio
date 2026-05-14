# Experiment Report — Plan A Synthetic 5K60 Render

Date: 2026-05-15 01:07 KST
Prompt: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`
Branch: `feat/plan-a-5k60-benchmark`
Commit: `8aac293`
Hardware: iMac Late 2015 Windows receiver, AMD Radeon R9 M380 2GB
Transport: none
Mode: synthetic local render, 5120x2880 @ 60 target, vsync on, dynamic frame fill

## Goal

Measure whether the Windows-booted iMac can locally generate, upload, draw, and present synthetic 5120x2880 frames at 60 fps without network, capture, or decode overhead.

## Setup

- Windows 10 Pro 22H2
- Display mode: 5120x2880 @ 60Hz
- GPU: AMD Radeon R9 M380
- Driver version: 15.201.2001.0
- Run launched from the iMac interactive Windows desktop using `Run iBridge Plan A 5K60 Benchmark.cmd`.

## Commands

```cmd
apps\receiver-windows\build\manual\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --csv "%RUN_DIR%\receiver_stats.csv"
```

## Results

| Metric | Value |
|---|---:|
| target fps | 60 |
| actual fps | 36.034 |
| frames | 2163 |
| frame budget | 16.667 ms |
| avg fill | 14.5120 ms |
| avg upload | 12.9730 ms |
| avg draw/present | 0.2519 ms |
| avg total frame | 27.7370 ms |
| p95 total frame | 29.0890 ms |
| max total frame | 54.9967 ms |
| missed frames | 2163 |
| missed frame rate | 100.00% |

## Artifacts

- `console.txt`
- `receiver_stats.csv`
- `run_status.txt`

## Interpretation

The receiver did not meet the Plan A local render gate. The run reached about 36 fps and every frame exceeded the 16.667 ms budget.

The dominant costs were synthetic CPU frame fill and full-frame D3D11 texture upload. Draw/present itself was small in this run, averaging about 0.252 ms, so the first measured bottleneck is getting a fresh full 5K frame into a presentable GPU texture every frame.

This does not yet measure capture, network, packetization, or decode. Those would add more cost on top of this local synthetic result.

## Decision

- [ ] Continue current Plan A raw/full-frame dynamic path
- [x] Downshift pressure recorded for Plan A dynamic full-frame upload
- [x] Needs follow-up isolation run

Plan A should not continue as a dynamic CPU-filled BGRA32 full-frame upload path. Before declaring all near-raw paths failed, run isolation tests:

- static frame with repeated upload, to isolate upload/present without CPU fill;
- no-vsync static frame ceiling, to estimate upload throughput;
- lower-copy or GPU-generated synthetic path if needed, to separate PCIe/upload limits from CPU fill.

## Next

Run `--static-frame` and `--no-vsync --static-frame` variants from the interactive iMac desktop. If upload/present still cannot approach 60 fps, record Plan A receiver-side failure and begin Plan B compressed 5K60.
