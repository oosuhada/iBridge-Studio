# Tiled Deadline Analysis — baseline_simultaneous_reset_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 360 |
| avg_group_latency_ms | 13.283 |
| p95_group_latency_ms | 16.335 |
| max_group_latency_ms | 122.915 |
| effective_logical_fps | 60.025 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 360 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 220 | 61.111% | 0, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 47, ... |
| 16.67 | 17 | 4.722% | 0, 33, 38, 51, 57, 69, 76, 180, 230, 290, 295, 305, ... |
| 20.00 | 3 | 0.833% | 0, 38, 180 |
| 33.33 | 2 | 0.556% | 0, 180 |
| 50.00 | 2 | 0.556% | 0, 180 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 13.258 | 15.278 | 122.915 |
| 300-359 | 13.410 | 17.220 | 17.942 |
