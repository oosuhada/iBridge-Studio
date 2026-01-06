# MacBook Pro Encoder ID Probe

Prompt: MacBook Pro Primary comparison after MacBook Air / iMac tests.

## Key Findings

- Combining `--encoder-id` with `EnableLowLatencyRateControl` failed session creation with `VTCompressionSessionCreate -12902` for the tested encoder IDs.
- Forcing `com.apple.videotoolbox.videoencoder.ave.hevc` while disabling low-latency rate-control produced the best Plan C results so far.
- Forcing `com.apple.videotoolbox.videoencoder.hevc.vcp` produced very high latency and should not be used for this pipeline.

## Useful Results

| Test | Frames | Failed | Avg encode ms | P95 encode ms | Max encode ms | Payload bytes |
|---|---:|---:|---:|---:|---:|---:|
| HEVC 2560x1440 120Mbps, `ave.hevc`, no low-latency RC | 120 | 0 | 17.096 | 41.361 | 81.606 | 30,486,622 |
| HEVC 3200x1800 120Mbps, `ave.hevc`, no low-latency RC | 180 | 0 | 16.612 | 16.777 | 74.412 | 45,558,452 |
| HEVC 3840x2160 120Mbps, `ave.hevc`, no low-latency RC | 180 | 0 | 21.884 | 22.839 | 64.816 | 45,189,586 |
| HEVC 4096x2304 120Mbps, `ave.hevc`, no low-latency RC | 180 | 0 | 24.969 | 32.502 | 62.966 | 45,446,158 |
| HEVC 2560x1440 120Mbps, `hevc.vcp`, no low-latency RC | 120 | 0 | 643.025 | 706.557 | 726.675 | 7,050,668 |
| H.264 3840x2160 120Mbps, `ave.avc`, no low-latency RC | 120 | 0 | 202.079 | 236.803 | 238.827 | 23,554,835 |

## Decision

For MacBook Pro Primary testing, prefer:

```bash
--codec hevc --disable-low-latency-rate-control --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc
```

This is a measured machine-specific result, not yet a universal default.
