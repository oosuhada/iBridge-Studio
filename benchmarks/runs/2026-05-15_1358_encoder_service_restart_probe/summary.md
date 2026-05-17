# Encoder Service Restart Recovery Probe

This probe checks whether restarting the user `VTEncoderXPCService` clears the slow single-stream state observed after tiled 5K60.

| Probe | Avg ms | P95 ms | Max ms | Result |
|---|---:|---:|---:|---|
| 4096x2304 after encoder service restart | 25.928 | 46.532 | 55.227 | Still slow |
| 4096x2304 after 60s wait | 25.692 | 46.544 | 47.904 | Still slow |
| 4096x2304 after 60s wait, speed unset | 25.724 | 46.719 | 47.720 | Still slow |
| 3200x1800 after restart, solo | 23.746 | 41.839 | 79.181 | Still slow |
| 2560x1440 after restart | 7.851 | 10.808 | 42.851 | Safe |

Conclusion: `VTEncoderXPCService` restart alone does not recover high-detail fallback performance after tiled contamination. Use `2560x1440@60` as the safest emergency fallback until a stronger reset is proven.
