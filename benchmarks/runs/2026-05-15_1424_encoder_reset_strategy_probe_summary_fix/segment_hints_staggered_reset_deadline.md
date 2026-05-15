# Tiled Deadline Analysis — segment_hints_staggered_reset_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 360 |
| avg_group_latency_ms | 13.300 |
| p95_group_latency_ms | 14.243 |
| max_group_latency_ms | 113.596 |
| effective_logical_fps | 60.016 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 360 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 285 | 79.167% | 0, 17, 20, 21, 24, 25, 26, 27, 28, 29, 30, 31, ... |
| 16.67 | 8 | 2.222% | 0, 154, 180, 210, 240, 270, 283, 341 |
| 20.00 | 6 | 1.667% | 0, 154, 180, 210, 240, 270 |
| 33.33 | 4 | 1.111% | 0, 180, 210, 240 |
| 50.00 | 3 | 0.833% | 0, 180, 210 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 13.431 | 14.089 | 113.596 |
| 300-359 | 12.645 | 14.693 | 17.575 |
