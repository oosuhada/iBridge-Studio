# Encode Follow-up: NV12 and Tiled 5K60

## Purpose

Follow up the source strategy matrix by separating three questions:

- Is single-session NV12 3840x2160 / 4096x2304 sustained enough for 60Hz encode?
- Does 2x2 tiled 5K60 still pass when measured inside one synchronized process?
- Does ScreenCaptureKit deliver enough frames and encode headroom at 3840x2160 / 4096x2304?

## Results

| Case | Duration | Frames | Avg encode ms | P95 encode ms | Result |
|---|---:|---:|---:|---:|---|
| synthetic NV12 3840x2160 @ 60 solo | 5s | 300/300 | 11.297 | 11.665 | Passes encode budget. |
| synthetic NV12 4096x2304 @ 60 solo | 5s | 300/300 | 12.629 | 12.957 | Passes encode budget. |
| ScreenCaptureKit 3840x2160 @ 60 | 5s | 250/300 | 16.705 | 19.357 | Encode close, capture did not emit 60fps on static screen. |
| ScreenCaptureKit 4096x2304 @ 60 | 5s | 161/300 | 18.489 | 20.792 | Too thin for reliable 60Hz capture path in this static-screen probe. |
| in-process 2x2 HEVC tiled 5K60, fresh NV12 tiles | 3s | 180/180 logical | 19.135 | 19.677 | Tile encode is fast, sequential tile generation pushes group latency over budget. |
| in-process 2x2 HEVC tiled 5K60, reused tile buffers | 3s | 180/180 logical | 14.931 | 38.202 | Steady post-warmup avg 11.993, p95 14.726; short-run lower bound passes. |
| in-process 2x2 HEVC tiled 5K60, reused buffers | 5s | 300/300 logical | 57.748 | 136.894 | Fails sustained run after about 3 seconds due to accumulating VT latency. |
| in-process 2x2 H.264 tiled 5K60, reused buffers | 5s | 300/300 logical | 197.613 | 285.391 | H.264 tiled path is not viable. |

## Interpretation

- `3840x2160 @ 60` and `4096x2304 @ 60` are the best single-session encode candidates.
- `4096x2304 @ 60` is better than the earlier BGRA result once NV12 input is used.
- ScreenCaptureKit on a static desktop naturally emits fewer frames than the target fps, so it must be evaluated as a changed-frame source rather than a forced full-frame clock.
- Tiled 5K60 is not ready as Plan B. It has a promising short-run lower bound, but the sustained 5-second run shows VideoToolbox latency accumulation with four simultaneous HEVC sessions.
- If 5K60 remains a goal, the next tiled spike needs backpressure/drop policy, staggered keyframes, or lower tile count/quality before receiver work.

## Artifacts

- `benchmarks/runs/2026-05-15_1138_inprocess_tiled_5k60/tiled_2x2_5k60.txt`
- `benchmarks/runs/2026-05-15_1140_inprocess_tiled_reuse_5k60/tiled_2x2_reuse_5k60.txt`
- `benchmarks/runs/2026-05-15_1141_inprocess_tiled_reuse_steady_5k60/tiled_2x2_reuse_steady_5k60.txt`
- `benchmarks/runs/2026-05-15_1141_inprocess_tiled_long_gop_5k60/tiled_2x2_long_gop_5k60.txt`
- `benchmarks/runs/2026-05-15_1142_inprocess_tiled_h264_5k60/tiled_2x2_h264_5k60.txt`
- `benchmarks/runs/2026-05-15_1143_sck_4096x2304_duration_5s/sck_4096x2304_60.txt`
- `benchmarks/runs/2026-05-15_1144_sck_3840x2160_duration_5s/sck_3840x2160_60.txt`
- `benchmarks/runs/2026-05-15_1144_nv12_3840x2160_5s_solo/nv12_3840x2160_60.txt`
- `benchmarks/runs/2026-05-15_1144_nv12_4096x2304_5s_solo/nv12_4096x2304_60.txt`
