# Tiled Deadline Analysis — segment_hints_staggered_reset_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 360 |
| avg_group_latency_ms | 13.572 |
| p95_group_latency_ms | 15.081 |
| max_group_latency_ms | 115.164 |
| effective_logical_fps | 60.025 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 360 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 282 | 78.333% | 0, 12, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, ... |
| 16.67 | 13 | 3.611% | 0, 19, 70, 97, 180, 210, 234, 240, 270, 271, 306, 311, ... |
| 20.00 | 5 | 1.389% | 0, 180, 210, 240, 270 |
| 33.33 | 5 | 1.389% | 0, 180, 210, 240, 270 |
| 50.00 | 4 | 1.111% | 0, 180, 210, 240 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 13.650 | 14.899 | 115.164 |
| 300-359 | 13.182 | 16.150 | 18.293 |
