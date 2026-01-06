# Encoder Low-Latency Probe

Prompt: focused Plan C end-to-end pipeline spike.

## Valid Sequential Results

| Test | Frames | Failed | Avg encode ms | P95 encode ms | Max encode ms | Payload bytes | Result |
|---|---:|---:|---:|---:|---:|---:|---|
| HEVC 2560x1440 @ 60, 120Mbps, 5s | 300 | 0 | 13.783 | 13.295 | 103.114 | 14,103,635 | meets avg < 20ms, but has startup/outlier spike |
| HEVC 3200x1800 @ 60, 120Mbps, 5s | 300 | 0 | 24.293 | 65.947 | 110.441 | 22,315,381 | does not meet avg < 20ms in this run |
| HEVC 3200x1800 @ 60, 80Mbps, KFI 120, 5s | 300 | 0 | 23.791 | 63.425 | 112.681 | 21,962,861 | does not meet avg < 20ms in this run |
| H.264 5120x2880 @ 60, 120Mbps, 1s | 60 | 60 | 9.321 | 10.073 | 75.755 | 0 | still fails to produce payloads |

## Notes

- The first non-sequential HEVC files in this directory were launched in parallel and should be treated as contention smoke artifacts, not benchmark results.
- `--list-encoders` output shows the current Mac exposes `com.apple.videotoolbox.videoencoder.ave.avc`, `com.apple.videotoolbox.videoencoder.h264`, `com.apple.videotoolbox.videoencoder.ave.hevc`, and `com.apple.videotoolbox.videoencoder.hevc.vcp`.
- Low-latency rate control is now passed in `VTCompressionSessionCreate` via `encoderSpecification`, not by `VTSessionSetProperty`.
- 3200x1800 remains the engineering default candidate from prior Plan C render tests, but encoder tuning needs more matrix runs before it can be claimed below a 20ms encode average.
