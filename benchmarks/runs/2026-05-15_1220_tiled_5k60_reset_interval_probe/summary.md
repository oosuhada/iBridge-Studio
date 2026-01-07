# Tiled 5K60 Reset Interval Probe

| Case | Reset every | Frames | Effective fps | Avg ms | P95 ms | Max ms | Late >16.67ms | Late >33.33ms | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| reset150_inflight1_20s | 150 | 1200 | 60.008 | 13.075 | 15.210 | 128.469 | 27 | 8 | PASS |
| reset180_inflight1_20s | 180 | 1200 | 60.010 | 11.991 | 12.632 | 131.582 | 8 | 7 | PASS |
| reset210_inflight1_20s | 210 | 1200 | 60.006 | 14.300 | 31.276 | 127.290 | 147 | 9 | FAIL |
