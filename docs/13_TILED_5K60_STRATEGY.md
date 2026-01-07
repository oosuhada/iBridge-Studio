# Tiled 5K60 Strategy

Date: 2026-05-15

## Question

Can iBridge continue toward full logical `5120x2880 @ 60Hz` by splitting the frame into independently encoded tiles?

## Short Answer

Yes, as the next prototype path. The current evidence says 2x2 tiled HEVC is feasible enough to continue, but it is not yet a smooth display solution.

The best current encode-only profile is:

```text
source=synthetic-nv12-tiled
logical_resolution=5120x2880
tile_grid=2x2
tile_resolution=2560x1440
codec=hevc
encoder_id=com.apple.videotoolbox.videoencoder.ave.hevc
bitrate=30Mbps per tile
data_rate_limit=30Mbps per tile
tile_reset_every_frames=180
tile_max_inflight_logical_frames=1
```

This sustained 30 seconds at effective `60.009fps`, average logical encode latency `12.100ms`, and p95 `12.690ms`. The remaining problem is max spike: reset frames still reach about `135.530ms`.

## Evidence

| Probe | Duration | Effective fps | Avg logical ms | P95 logical ms | Max logical ms | Late >16.67ms |
|---|---:|---:|---:|---:|---:|---:|
| reset150, inflight1 | 30s | 60.002 | 12.374 | 12.920 | 132.944 | 25 / 1800 |
| reset180, inflight1 | 30s | 60.009 | 12.100 | 12.690 | 135.530 | 18 / 1800 |

Artifacts:

- `benchmarks/runs/2026-05-15_1213_tiled_5k60_reset_sustain_30s/summary.md`
- `benchmarks/runs/2026-05-15_1220_tiled_5k60_reset_interval_probe/summary.md`
- `benchmarks/runs/2026-05-15_1222_tiled_5k60_reset180_sustain_30s/summary.md`
- `benchmarks/runs/2026-05-15_1222_tiled_5k60_reset180_sustain_30s/deadline_analysis.md`

## What Changed The Result

1. Per-tile PTS correction.
   - Earlier in-process tiled probes used global interleaved frame IDs as timestamps, so each tile session saw PTS values like `0, 4, 8...`.
   - The benchmark now gives each tile session logical PTS values like `0, 1, 2...`.

2. Bounded in-flight logical frames.
   - `--tile-max-inflight-logical-frames 1` prevents the encoder from accumulating a long hidden queue.

3. Periodic tile-session reset.
   - No-reset probes still climb after roughly 180 logical frames.
   - Resetting around frame 180 keeps p95 low, but introduces reset-frame spikes.

## Why This Matches Current Encoding Trends

Modern hardware encoders increasingly use split-frame or multi-instance strategies for very high resolutions. NVIDIA documents Multi NVENC Split Frame Encoding for HEVC and AV1: a frame is partitioned into independent strips and encoded simultaneously by separate encoder engines, increasing single-stream speed at quality cost. [내용 출처 : https://docs.nvidia.com/video-technologies/video-codec-sdk/13.0/nvenc-video-encoder-api-prog-guide/index.html#multi-nvenc-split-frame-encoding-in-hevc-and-av1]

NVIDIA's 8K60 split-frame writeup also distinguishes HEVC slices from AV1 tiles and documents explicit split-frame control in Video Codec SDK 12.1. [내용 출처 : https://developer.nvidia.com/blog/video-encoding-at-8k60-with-split-frame-encoding-and-nvidia-ada-lovelace-architecture/]

iBridge cannot directly enable NVENC SFE through VideoToolbox, but the local 2x2 tiled approach is conceptually similar: it manually partitions one logical frame into multiple independent encoder sessions.

## What Not To Chase Yet

- AV1: useful industry direction, but not the current iBridge path on this MacBook Pro plus 2015 iMac Windows receiver. The local VideoToolbox encoder list used in this repo does not show an AV1 encoder, and receiver decode support is already uncertain for 5K HEVC/H.264.
- Lookahead or temporal filtering: NVIDIA documents these as quality/bitrate tools with latency and performance tradeoffs, so they are not first-choice controls for an interactive display path. [내용 출처 : https://developer.nvidia.com/blog/improving-video-quality-with-nvidia-video-codec-sdk-12-2-for-hevc/]
- More tiles by default: 4x2 and 2x4 probes did not beat 2x2; they increased tail risk in the current MacBook Pro VideoToolbox path.

## Next Prototype Design

The receiver should not wait for all tiles indefinitely.

Recommended presentation policy:

1. Keep a previous decoded texture for each tile.
2. For each display vsync, composite the newest tile available before the deadline.
3. If a tile misses the deadline, reuse the previous tile for that region.
4. Count stale-tile presentations in the HUD.
5. Treat a full logical frame as smooth if the presented surface updates at 60Hz and stale tiles stay rare.

Based on `reset180` 30-second deadline analysis:

| Deadline | Late logical frames |
|---:|---:|
| 16.67ms | 18 / 1800 |
| 20ms | 12 / 1800 |
| 33.33ms | 10 / 1800 |

This suggests that stale-tile presentation could hide the reset spikes better than blocking the whole logical frame.

## Next Experiments

1. Add a tiled transport header extension:
   - tile columns/rows
   - tile index
   - logical frame ID
   - tile width/height
   - keyframe/config flags
   - end-of-logical-frame marker

2. Build receiver-side recomposition without decode first:
   - synthetic colored tile packets
   - D3D11 texture-per-tile composition
   - stale-tile HUD counters

3. Then add four HEVC decode sessions.

4. Only after synthetic tiled receiver works, connect macOS Primary tiled HEVC output to the receiver.

5. Keep single-session `3840x2160 @ 60` and `4096x2304 @ 60` as fallback branches.
