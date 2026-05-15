# Tiled Deadline Analysis — segment_hints_simultaneous_reset_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 360 |
| avg_group_latency_ms | 13.468 |
| p95_group_latency_ms | 14.309 |
| max_group_latency_ms | 116.770 |
| effective_logical_fps | 59.980 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 360 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 312 | 86.667% | 0, 3, 4, 7, 8, 19, 20, 21, 22, 23, 24, 25, ... |
| 16.67 | 6 | 1.667% | 0, 106, 180, 214, 298, 359 |
| 20.00 | 4 | 1.111% | 0, 106, 180, 298 |
| 33.33 | 2 | 0.556% | 0, 180 |
| 50.00 | 2 | 0.556% | 0, 180 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 13.532 | 14.309 | 116.770 |
| 300-359 | 13.146 | 14.319 | 16.793 |
