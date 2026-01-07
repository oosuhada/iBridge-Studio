# VideoToolbox Property Matrix

- Duration per case: `2` seconds
- FPS target: `60`
- Codec: HEVC
- Forced encoder profile uses: `com.apple.videotoolbox.videoencoder.ave.hevc`
- Output CSV: `summary.csv`
- Encoder list: `video_encoders.txt`

## Purpose

This matrix tests encoder properties before any iMac receiver dependency:

- automatic low-latency rate control versus forced `ave.hevc`
- temporal compression on with frame reordering off
- closed GOP
- max frame delay count
- speed-priority hint
- DataRateLimits
- Annex-B payload extraction cost

Use this to decide whether Plan A/B encode itself is viable before continuing
receiver or transport work.

## Highlights

| Profile | Resolution | Avg encode ms | P95 encode ms | Result |
|---|---:|---:|---:|---|
| auto low-latency RC | 3200x1800 | 38.214 | 71.169 | too high |
| `ave.hevc`, no LLRC, DataRateLimits | 3200x1800 | 12.399 | 14.106 | passes encode budget |
| auto low-latency RC | 3840x2160 | 94.576 | 96.128 | too high |
| `ave.hevc`, no LLRC, DataRateLimits | 3840x2160 | 16.158 | 25.725 | average passes, p95 high |
| `ave.hevc`, no LLRC, speed priority | 5120x2880 | 47.842 | 65.002 | too high |
| `ave.hevc`, no LLRC, DataRateLimits | 5120x2880 | 318.266 | 356.824 | unusable |

## Decision

- The automatic low-latency RC path is not acceptable on this MBP.
- Forced `ave.hevc` with low-latency RC disabled remains the right base path.
- DataRateLimits improved 3200x1800 and 3840x2160, but not 5120x2880.
- Annex-B conversion did not materially change encode timing, so it is safe to
  keep as a receiver-facing payload option.
- Plan B 5K60 is still blocked at encode time.
