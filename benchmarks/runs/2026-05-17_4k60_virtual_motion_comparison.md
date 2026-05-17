# 4K60 Virtual Motion Latency Comparison

Date: 2026-05-17

Profile: `3840x2160@60`, HEVC, 80Mbps, direct 1GbE to `169.254.70.114:48320`.

| Case | capture max in-flight | submitted | skipped | encoded | failed | sender drops | send failures | avg encode ms | p95 encode ms | max encode ms | avg send ms | p95 send ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| backpressure1 | 1 | 74 | 406 | 74 | 0 | 0 | 0 | 16.628 | 19.090 | 52.020 | 0.494 | 1.801 |
| no_backpressure | 0 | 48 | 432 | 48 | 0 | 0 | 0 | 20.378 | 52.175 | 64.523 | 0.382 | 1.866 |

Interpretation:
- 4K60 over the current wired path sends without transport failures in both cases.
- Capture-side backpressure materially reduces tail encode latency in this run: p95 encode dropped from `52.175 ms` to `19.090 ms`.
- This confirms the app should prefer recency over completeness for 4K60. It is still not a final full-60fps quality pass because ScreenCaptureKit did not submit all 480 requested frames during this short motion smoke.
- Next product work should add a proper in-app motion/readability test scene and then move transport from TCP correctness mode toward a bounded UDP/RTP-style path.
