# VideoToolbox Targeted Sustained Probe

Date: 2026-05-15

Machine: MacBookPro18,4 / M1 Max / 32 GB

Command shape:

```bash
ibridge-primary --synthetic --fps 60 --duration 5 --codec hevc --bitrate-mbps 120 \
  --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc \
  --disable-low-latency-rate-control \
  --allow-temporal-compression \
  --disable-frame-reordering \
  --disable-open-gop
```

The 3200x1800, 3840x2160, and 4096x2304 cases also used:

```bash
--data-rate-limit-mbps 120 --data-rate-window 1.0
```

The 5120x2880 case used:

```bash
--prioritize-speed
```

## Results

| Mode | Frames | Failed | Avg encode ms | P95 encode ms | Max encode ms | Payload bytes |
|---|---:|---:|---:|---:|---:|---:|
| 3200x1800 datarate | 300 | 0 | 11.583 | 11.766 | 64.125 | 52,564,637 |
| 3840x2160 datarate | 300 | 0 | 15.457 | 15.831 | 62.353 | 52,474,335 |
| 4096x2304 datarate | 300 | 0 | 17.292 | 17.231 | 76.561 | 52,536,912 |
| 5120x2880 speed | 300 | 0 | 100.617 | 119.982 | 123.135 | 75,570,913 |

## Interpretation

- `3200x1800` and `3840x2160` fit a 60 Hz encode budget on this synthetic
  source with the forced `ave.hevc`, no low-latency rate control, temporal
  compression enabled, frame reordering disabled, and DataRateLimits set.
- `4096x2304` is very close but still over the 16.667 ms frame budget on
  average/p95 in this run.
- `5120x2880` is not close. Even with `PrioritizeEncodingSpeedOverQuality`,
  5K HEVC encode is still far outside a 60 Hz frame budget.
- `MaxFrameDelayCount` returned `-12900` on these runs and should be treated as
  unsupported on this path unless a different encoder/session combination
  proves otherwise.

## Decision

Before any iMac receiver dependency, Plan B 5K60 compressed encode is still not
viable on the current MBP Primary path. The strongest encoding-only candidates
are now 3200x1800 and 3840x2160 HEVC with forced `ave.hevc` plus
DataRateLimits.
