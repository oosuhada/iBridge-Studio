# Single Stream Stability Matrix

- Duration per run: `5` seconds
- Repeats per resolution: `3`
- Cooldown between cases: `3` seconds
- Codec: HEVC
- Source: synthetic NV12
- Bitrate/DataRateLimits: `120 Mbps`
- Forced encoder: `com.apple.videotoolbox.videoencoder.ave.hevc`
- Prioritize speed: `on`
- Main table: `summary.csv`
- Aggregate: `aggregate.md`

## Intent

This isolates single-stream sender latency variance for 4096x2304, 3840x2160,
3200x1800, and 2560x1440 before choosing wired or wireless fallback profiles.
