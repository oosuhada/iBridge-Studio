# Tiled 5K60 PTS Fix Probe

| Case | Frames | Effective fps | Avg logical ms | P95 logical ms | Steady avg ms | Steady p95 ms | Steady max-tile p95 ms | Payload bytes | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 120mbps_inflight1_5s | 300 | 43.869 | 20.507 | 33.718 | 20.825 | 33.718 | 31.407 | 1963652 | FAIL |
| 120mbps_unlimited_5s | 300 | 59.521 | 24.841 | 44.951 | 23.708 | 43.664 | 42.498 | 1963652 | FAIL |
| 30mbps_inflight1_5s | 300 | 44.157 | 19.992 | 32.797 | 20.291 | 32.797 | 30.955 | 1391053 | FAIL |
| 30mbps_unlimited_5s | 300 | 59.533 | 24.948 | 43.802 | 23.942 | 43.094 | 41.982 | 1391053 | FAIL |
| 60mbps_unlimited_5s | 300 | 59.517 | 24.671 | 43.489 | 23.766 | 42.844 | 41.588 | 1629483 | FAIL |
