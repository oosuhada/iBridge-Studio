# Tiled 5K60 Backpressure Probe

| Case | Frames | Effective fps | Avg logical ms | P95 logical ms | Steady avg ms | Steady p95 ms | Steady max-tile p95 ms | Payload bytes | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 120mbps_inflight1 | 300 | 44.043 | 20.083 | 32.267 | 20.400 | 32.267 | 30.592 | 5100530 | FAIL |
| 120mbps_inflight2 | 300 | 45.865 | 31.062 | 59.810 | 31.684 | 59.810 | 58.980 | 5100530 | FAIL |
| 120mbps_unlimited | 300 | 55.780 | 57.076 | 136.617 | 58.539 | 136.622 | 126.936 | 5100530 | FAIL |
| 30mbps_inflight1 | 300 | 44.966 | 19.152 | 31.159 | 19.413 | 31.159 | 30.361 | 3285466 | FAIL |
| 30mbps_inflight1_no_drl | 300 | 34.374 | 29.020 | 47.910 | 29.575 | 47.910 | 47.213 | 4169717 | FAIL |
| 30mbps_inflight2 | 300 | 45.879 | 30.667 | 59.554 | 31.264 | 59.554 | 59.055 | 3285466 | FAIL |
| 60mbps_inflight1 | 300 | 44.378 | 19.741 | 32.077 | 20.034 | 32.077 | 30.629 | 3991291 | FAIL |
