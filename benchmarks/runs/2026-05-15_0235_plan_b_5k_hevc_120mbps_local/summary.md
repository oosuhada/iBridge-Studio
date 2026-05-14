# Plan B 5K60 HEVC 120Mbps Local Encode

Prompt: `prompts/03_PLAN_B_5K60_PRACTICAL.md`

Command:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 5120x2880 --fps 60 --duration 1 --codec hevc --bitrate-mbps 120 --csv benchmarks/runs/2026-05-15_0235_plan_b_5k_hevc_120mbps_local/primary_stats.csv
```

Result:

| Metric | Value |
|---|---:|
| Frames requested | 60 |
| Failed frames | 0 |
| Payload bytes | 15,356,893 |
| Avg synthetic generation | 17.878 ms |
| Avg encode callback latency | 149.548 ms |
| P95 encode callback latency | 207.439 ms |
| Max encode callback latency | 207.771 ms |
| Wall time | 2.34 s |

Classification:

- `encode latency bottleneck`: bitrate limiting reduces payload size, but encode callback latency remains far beyond the 60Hz budget.

