# Tiled 5K60 Tile Shape Probe

| Case | Tile grid | Tile resolution | Frames | Effective fps | Avg logical ms | P95 logical ms | Steady p95 ms | Steady max-tile p95 ms | Payload bytes | Result |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| 1x4_30mbps_per_tile | 1x4 | 5120x720 | 300 | 59.553 | 25.659 | 44.927 | 43.199 | 42.026 | 1325066 | FAIL |
| 2x2_30mbps_per_tile | 2x2 | 2560x1440 | 300 | 59.559 | 25.343 | 44.095 | 42.847 | 41.814 | 1391053 | FAIL |
| 2x4_15mbps_per_tile | 2x4 | 2560x720 | 300 | 59.322 | 31.410 | 84.981 | 51.302 | 50.120 | 1558336 | FAIL |
| 4x1_30mbps_per_tile | 4x1 | 1280x2880 | 300 | 59.567 | 25.087 | 45.874 | 44.961 | 43.695 | 1476775 | FAIL |
| 4x2_15mbps_per_tile | 4x2 | 1280x1440 | 300 | 59.396 | 31.421 | 83.656 | 56.191 | 55.537 | 1661452 | FAIL |
