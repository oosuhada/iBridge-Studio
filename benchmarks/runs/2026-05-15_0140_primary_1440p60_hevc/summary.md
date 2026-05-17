# Experiment Report — Primary Synthetic 1440p60 HEVC Encode

Date: 2026-05-15 01:40 KST
Prompt: `prompts/05_PRIMARY_MACOS_IMPLEMENTATION.md`
Branch: `feat/plan-a-5k60-benchmark`
Hardware: MacBook Air M1, macOS 14.5
Mode: synthetic BGRA source, VideoToolbox HEVC

## Goal

Verify that the macOS Primary CLI can generate synthetic 2560x1440 frames at 60fps target and encode them with VideoToolbox HEVC while writing diagnostics CSV.

## Command

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec hevc --csv benchmarks/runs/2026-05-15_0140_primary_1440p60_hevc/primary_stats.csv
```

## Results

| Metric | Value |
|---|---:|
| frames requested | 120 |
| frames encoded | 120 |
| failed frames | 0 |
| avg generate | 4.892 ms |
| avg encode latency | 133.649 ms |
| p95 encode latency | 162.608 ms |
| max encode latency | 169.744 ms |
| payload bytes | 43,277,169 |

## Interpretation

The HEVC path is functional and writes diagnostics. In this first run it had slightly higher callback latency than H.264. The payload size was similar to H.264 for the synthetic pattern, so codec quality/bitrate decisions need screen-content tests rather than this pattern alone.

## Decision

- [x] Continue Primary implementation
- [ ] Accept current latency for product use
- [x] Needs low-latency tuning and screen-content tests
