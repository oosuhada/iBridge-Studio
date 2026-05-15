# Tiled Deadline Analysis — segment_hints_simultaneous_reset_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 360 |
| avg_group_latency_ms | 13.362 |
| p95_group_latency_ms | 14.158 |
| max_group_latency_ms | 134.008 |
| effective_logical_fps | 59.995 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 360 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 286 | 79.444% | 0, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, ... |
| 16.67 | 4 | 1.111% | 0, 73, 167, 180 |
| 20.00 | 2 | 0.556% | 0, 180 |
| 33.33 | 2 | 0.556% | 0, 180 |
| 50.00 | 2 | 0.556% | 0, 180 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 13.523 | 14.158 | 134.008 |
| 300-359 | 12.560 | 14.117 | 15.969 |
