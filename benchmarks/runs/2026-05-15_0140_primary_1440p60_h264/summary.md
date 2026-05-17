# Experiment Report — Primary Synthetic 1440p60 H.264 Encode

Date: 2026-05-15 01:40 KST
Prompt: `prompts/05_PRIMARY_MACOS_IMPLEMENTATION.md`
Branch: `feat/plan-a-5k60-benchmark`
Hardware: MacBook Air M1, macOS 14.5
Mode: synthetic BGRA source, VideoToolbox H.264

## Goal

Verify that the macOS Primary CLI can generate synthetic 2560x1440 frames at 60fps target and encode them with VideoToolbox H.264 while writing diagnostics CSV.

## Command

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec h264 --csv benchmarks/runs/2026-05-15_0140_primary_1440p60_h264/primary_stats.csv
```

## Results

| Metric | Value |
|---|---:|
| frames requested | 120 |
| frames encoded | 120 |
| failed frames | 0 |
| avg generate | 4.894 ms |
| avg encode latency | 119.916 ms |
| p95 encode latency | 151.081 ms |
| max encode latency | 157.933 ms |
| payload bytes | 44,277,068 |

## Interpretation

The H.264 path is functional and writes diagnostics, but the measured callback latency is too high for an external-display target. The next Primary revision should tune VideoToolbox for lower latency and measure whether per-frame completion, lower queue depth, or additional compression properties reduce callback delay.

## Decision

- [x] Continue Primary implementation
- [ ] Accept current latency for product use
- [x] Needs low-latency tuning
