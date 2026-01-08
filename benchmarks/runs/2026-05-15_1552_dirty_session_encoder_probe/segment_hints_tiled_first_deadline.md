# Tiled Deadline Analysis — segment_hints_tiled_first_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 360 |
| avg_group_latency_ms | 12.320 |
| p95_group_latency_ms | 13.765 |
| max_group_latency_ms | 109.591 |
| effective_logical_fps | 60.032 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 360 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 98 | 27.222% | 0, 5, 22, 23, 25, 26, 28, 37, 44, 45, 47, 50, ... |
| 16.67 | 7 | 1.944% | 0, 168, 180, 282, 284, 286, 287 |
| 20.00 | 4 | 1.111% | 0, 168, 180, 282 |
| 33.33 | 2 | 0.556% | 0, 180 |
| 50.00 | 2 | 0.556% | 0, 180 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 12.419 | 13.906 | 109.591 |
| 300-359 | 11.826 | 13.361 | 14.559 |
