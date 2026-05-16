# LAN High Quality Synthetic Smoke

Date: 2026-05-17

Receiver: 2017 4K iMac over direct 1GbE, `169.254.70.114:48320`.

| Case | Resolution | FPS | Mbps | Encoded | Sender drops | Send failures | Avg encode ms | P95 encode ms | Avg send ms | P95 send ms |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2560x1440_30fps_35mbps | 2560x1440 | 30 | 35 | 150/150 | 0 | 0 | 14.516 | 25.772 | 0.060 | 0.098 |
| 2560x1440_60fps_45mbps | 2560x1440 | 60 | 45 | 300/300 | 0 | 0 | 22.340 | 41.191 | 0.067 | 0.153 |
| 3200x1800_30fps_50mbps | 3200x1800 | 30 | 50 | 150/150 | 90 | 0 | 39.968 | 74.514 | 57.962 | 0.381 |
| 3200x1800_60fps_60mbps | 3200x1800 | 60 | 60 | 300/300 | 0 | 0 | 22.998 | 39.214 | 0.046 | 0.076 |

Interpretation:
- Direct LAN transport is stable in these short synthetic runs: send failures stayed at 0.
- `2560x1440@30 35Mbps` is the current wired readability default because it improves text resolution over 1080p while keeping the 30fps frame budget mostly realistic in the current encoder state.
- `3200x1800` and 60Hz higher-detail modes remain experimental until the encoder slow-state/backpressure problem is solved.
