# Tiled Deadline Analysis — m1max_wired_full_5k60_tiled_hevc_synthetic_nv12_tiled_5120x2880_60fps_30mbps_logical.csv

| Metric | Value |
|---|---:|
| logical_frames | 300 |
| avg_group_latency_ms | 12.501 |
| p95_group_latency_ms | 13.222 |
| max_group_latency_ms | 123.935 |
| effective_logical_fps | 60.040 |
| tile_reset_every_frames | 180 |
| tile_max_inflight_logical_frames | 1 |

| Budget ms | Late frames | Late % | First late frame IDs |
|---:|---:|---:|---|
| 8.33 | 300 | 100.000% | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, ... |
| 12.00 | 95 | 31.667% | 0, 22, 23, 26, 28, 29, 31, 33, 35, 39, 49, 50, ... |
| 16.67 | 2 | 0.667% | 0, 180 |
| 20.00 | 2 | 0.667% | 0, 180 |
| 33.33 | 2 | 0.667% | 0, 180 |
| 50.00 | 2 | 0.667% | 0, 180 |

| Window | Avg ms | P95 ms | Max ms |
|---:|---:|---:|---:|
| 0-299 | 12.501 | 13.222 | 123.935 |
