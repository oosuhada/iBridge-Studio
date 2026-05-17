# Plan B 5K60 H.264 TCP Attempt

Prompt: `prompts/03_PLAN_B_5K60_PRACTICAL.md`

Command:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 5120x2880 --fps 60 --duration 1 --codec h264 --send-host 100.86.52.88 --send-port 48320 --csv benchmarks/runs/2026-05-15_0210_plan_b_5k_h264_tcp/primary_stats.csv
```

Result:

| Metric | Value |
|---|---:|
| Frames requested | 60 |
| Failed frames | 60 |
| Status | -10279 for every frame |
| Payload bytes | 0 |
| Avg synthetic generation | 18.679 ms |
| Avg encode callback latency | 8.780 ms |
| Receiver frames | 0 |

Classification:

- `encode bottleneck`: H.264 5120x2880 frames did not produce compressed payloads on this MacBook Air VideoToolbox path.
- `transport/decode/render`: not reached for H.264 because payload bytes were zero.

