# Encoder Reset / Session Strategy

Date: 2026-05-15

## Problem

The M1 Max `2x2` tiled HEVC path can keep 5K60 encode-only p95 inside the 16.67 ms frame budget, but it leaves two related risks:

- Reset frames still produce visible-sized spikes around the session boundary.
- After tiled 5K60 runs, immediate high-detail single-stream fallbacks such as `4096x2304@60` and `3200x1800@60` can remain slow even after a user `VTEncoderXPCService` restart.

This means tiled 5K60 cannot safely switch down to high-detail single-stream fallback until reset/session behavior is controlled.

## Reference Findings

- Apple documents the normal `VTCompressionSession` lifecycle as create, configure, encode, optionally complete pending frames, then invalidate the session when finished. [내용 출처 : https://developer.apple.com/documentation/videotoolbox/vtcompressionsession-api-collection]
- Apple documents `VTCompressionSessionPrepareToEncodeFrames` as a way for the encoder to allocate resources before the first encode call; iBridge already calls this in `configure(...)`. [내용 출처 : https://developer.apple.com/documentation/videotoolbox/1428283-vtcompressionsessionpreparetoenc]
- Apple documents parallel encoding configuration as requiring `MoreFramesBeforeStart`, `MoreFramesAfterEnd`, and `SourceFrameCount`. This is not exactly the same as iBridge spatial tiling, but it is directly relevant to per-tile temporal reset segments. [내용 출처 : https://developer.apple.com/documentation/videotoolbox/kvtcompressionpropertykey_recommendedparallelizationlimit]
- `MoreFramesBeforeStart` / `MoreFramesAfterEnd` tell the encoder that separate sessions will be concatenated before/after the current session, helping smooth segment joins and avoid data-rate spikes. [내용 출처 : https://developer.apple.com/documentation/videotoolbox/kvtcompressionpropertykey_moreframesbeforestart] [내용 출처 : https://developer.apple.com/documentation/videotoolbox/kvtcompressionpropertykey_moreframesafterend]
- `SourceFrameCount` is an encoder hint for the number of source frames when known. [내용 출처 : https://developer.apple.com/documentation/videotoolbox/compression-properties]
- FFmpeg's VideoToolbox encoder exposes similar `frames_before` and `frames_after` options and calls `VTCompressionSessionPrepareToEncodeFrames` before encoding. Local reference: `reference/FFmpeg/libavcodec/videotoolboxenc.c`.
- OBS's macOS VideoToolbox encoder also prepares the session before use and invalidates/releases on teardown. Local reference: `reference/obs-studio/plugins/mac-videotoolbox/encoder.c`.

## Implemented Probe Controls

`apps/primary-macos/Sources/iBridgePrimary/main.swift` now has experiment controls for:

- `--more-frames-before-start` / `--no-more-frames-before-start`
- `--more-frames-after-end` / `--no-more-frames-after-end`
- `--source-frame-count N`
- `--tile-segment-hints`
- `--tile-reset-stagger-frames N`

For tiled mode, `--tile-segment-hints` automatically sets per-segment hints:

- first segment: `MoreFramesBeforeStart=false`
- middle segments: `MoreFramesBeforeStart=true`, `MoreFramesAfterEnd=true`
- final benchmark segment: `MoreFramesAfterEnd=false`
- `SourceFrameCount` equals the segment length unless overridden

`scripts/mac_encoder_reset_strategy_probe.sh` compares:

1. baseline simultaneous tile reset
2. segment hints with simultaneous tile reset
3. segment hints with staggered per-tile reset

## Initial M1 Max Probe

Run:

```bash
DURATION=6 RUN_FALLBACK=0 RUN_ROOT=benchmarks/runs/2026-05-15_1424_encoder_reset_strategy_probe_summary_fix scripts/mac_encoder_reset_strategy_probe.sh
```

Results:

| Case | Effective fps | Avg ms | P95 ms | Max ms | >16.67ms | >33.33ms |
|---|---:|---:|---:|---:|---:|---:|
| baseline simultaneous reset | 60.011 | 13.199 | 14.330 | 132.700 | 7/360 | 2/360 |
| segment hints simultaneous reset | 59.995 | 13.362 | 14.158 | 134.008 | 4/360 | 2/360 |
| segment hints staggered reset | 60.016 | 13.300 | 14.243 | 113.596 | 8/360 | 4/360 |

Interpretation:

- Segment hints are a positive signal. They reduced logical frames over the 16.67 ms budget in both short probes.
- Staggered reset lowers the worst simultaneous reset spike, but spreads reset misses across multiple logical frames. This is not the default sender strategy yet.
- The current best next sender candidate is `2x2 tiled HEVC 5K60 + reset180 + inflight1 + tile segment hints + simultaneous reset`.

## Fallback Recovery Status

Run:

```bash
DURATION=6 RUN_FALLBACK=1 RUN_ROOT=benchmarks/runs/2026-05-15_1415_encoder_reset_strategy_probe scripts/mac_encoder_reset_strategy_probe.sh
```

Post-probe fallback results:

| Fallback | Avg ms | P95 ms | Max ms | Interpretation |
|---|---:|---:|---:|---|
| `4096x2304@60` | 25.838 | 46.578 | 47.764 | still unsafe after tiled |
| `3200x1800@60` | 23.846 | 42.273 | 84.630 | still unsafe after tiled |
| `2560x1440@60` | 10.345 | 16.866 | 30.266 | borderline in this run, still the safest emergency fallback |

Because the machine was already in a post-tiled slow state before this probe, treat these fallback numbers as confirmation of the problem rather than a clean A/B comparison.

## Current Decision

- Keep high-detail single-stream fallback profiles as valid only when run in isolation or after a known-clean encoder state.
- Do not switch product mode directly from tiled 5K60 to `4096x2304@60` or `3200x1800@60` until a stronger reset boundary is proven.
- Use `2560x1440@60` as the conservative emergency fallback after tiled 5K60.
- Next clean-session test should start from a fresh login or reboot, run segment-hints tiled first, then immediately test 4096/3200 fallback to see whether hints reduce contamination.
