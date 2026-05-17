# Tiled Deadline Analysis — baseline_simultaneous_reset_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 360 |
| avg_group_latency_ms | 13.199 |
| p95_group_latency_ms | 14.330 |
| max_group_latency_ms | 132.700 |
| effective_logical_fps | 60.011 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 360 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 240 | 66.667% | 0, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, ... |
| 16.67 | 7 | 1.944% | 0, 180, 233, 277, 278, 286, 337 |
| 20.00 | 5 | 1.389% | 0, 180, 233, 278, 286 |
| 33.33 | 2 | 0.556% | 0, 180 |
| 50.00 | 2 | 0.556% | 0, 180 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 13.240 | 14.320 | 132.700 |
| 300-359 | 12.995 | 14.335 | 18.142 |
