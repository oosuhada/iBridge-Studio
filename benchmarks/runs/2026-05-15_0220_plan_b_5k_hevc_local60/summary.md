# Plan B 5K60 HEVC Local Encode

Prompt: `prompts/03_PLAN_B_5K60_PRACTICAL.md`

Command:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 5120x2880 --fps 60 --duration 1 --codec hevc --csv benchmarks/runs/2026-05-15_0220_plan_b_5k_hevc_local60/primary_stats.csv
```

Result:

| Metric | Value |
|---|---:|
| Frames requested | 60 |
| Failed frames | 0 |
| Payload bytes | 87,013,939 |
| Avg synthetic generation | 18.945 ms |
| Avg encode callback latency | 116.081 ms |
| P95 encode callback latency | 187.861 ms |
| Max encode callback latency | 193.921 ms |
| Wall time | 1.49 s |

Classification:

- `encode latency bottleneck`: HEVC can encode 5K frames, but callback latency is already far above a 16.667 ms 60Hz frame budget.
- `bitrate pressure`: default bitrate emitted about 87 MB for one second of synthetic 5K60 frames.

