# Tiled Deadline Analysis — segment_hints_tiled_first_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 600 |
| avg_group_latency_ms | 12.643 |
| p95_group_latency_ms | 14.417 |
| max_group_latency_ms | 127.892 |
| effective_logical_fps | 60.025 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 600 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 205 | 34.167% | 0, 44, 46, 48, 49, 50, 51, 52, 54, 56, 58, 78, ... |
| 16.67 | 9 | 1.500% | 0, 88, 158, 180, 214, 274, 360, 444, 540 |
| 20.00 | 5 | 0.833% | 0, 180, 274, 360, 540 |
| 33.33 | 4 | 0.667% | 0, 180, 360, 540 |
| 50.00 | 4 | 0.667% | 0, 180, 360, 540 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 12.572 | 13.897 | 120.435 |
| 300-599 | 12.714 | 14.504 | 127.892 |
