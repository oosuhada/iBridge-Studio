# Tiled 5K60 Session Reset Probe

| Case | Reset every | Inflight | Frames | Effective fps | Avg logical ms | P95 logical ms | Steady p95 ms | Steady max-tile p95 ms | Payload bytes | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 30mbps_no_reset | 0 | 0 | 300 | 59.543 | 24.733 | 42.688 | 41.922 | 41.328 | 1391053 | FAIL |
| 30mbps_reset120 | 120 | 0 | 300 | 60.014 | 20.909 | 71.783 | 71.783 | 66.559 | 2614696 | FAIL |
| 30mbps_reset150 | 150 | 0 | 300 | 60.003 | 17.509 | 65.848 | 57.918 | 51.309 | 2003860 | FAIL |
| 30mbps_reset150_inflight1 | 150 | 1 | 300 | 60.040 | 12.255 | 12.937 | 12.937 | 11.325 | 2003860 | PASS |
| 30mbps_reset90 | 90 | 0 | 300 | 60.028 | 24.350 | 71.822 | 71.822 | 66.455 | 3222397 | FAIL |
| 60mbps_reset150 | 150 | 0 | 300 | 60.027 | 16.801 | 60.790 | 50.410 | 46.270 | 2479566 | FAIL |
