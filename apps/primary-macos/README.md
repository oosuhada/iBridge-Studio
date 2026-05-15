# primary-macos

MacBook-side app.

First target:

1. synthetic source
2. capture source
3. H.264 encode
4. send to receiver
5. diagnostics output

Do not block first implementation on perfect virtual display. Create a virtual display spike separately.

## CLI spike

Build:

```bash
swift build --package-path apps/primary-macos -c release
```

Run a synthetic 1440p60 H.264 encode benchmark:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec h264 --csv benchmarks/runs/YYYY-MM-DD_HHMM_primary_1440p60_h264/primary_stats.csv
```

Run the HEVC path:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 2560x1440 --fps 60 --duration 2 --codec hevc --csv benchmarks/runs/YYYY-MM-DD_HHMM_primary_1440p60_hevc/primary_stats.csv
```

On machines that expose multiple VideoToolbox encoders, force an encoder ID for isolation:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 3200x1800 --fps 60 --duration 3 --codec hevc --bitrate-mbps 120 --disable-low-latency-rate-control --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc --csv benchmarks/runs/YYYY-MM-DD_HHMM_primary_1800p60_hevc_ave/primary_stats.csv
```

Use `--list-encoders` first and keep encoder-ID-specific results separate from automatic encoder selection.

Send encoded frames to a protocol v0 TCP receiver sink:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 5120x2880 --fps 60 --duration 1 --codec hevc --bitrate-mbps 120 --send-host 100.86.52.88 --send-port 48320 --csv benchmarks/runs/YYYY-MM-DD_HHMM_plan_b_5k_hevc_tcp/primary_stats.csv
```

The TCP sender now uses a bounded async queue. The VideoToolbox output callback copies the encoded payload and enqueues it; a dedicated sender worker owns blocking socket writes. New diagnostics columns include `payload_extract_ms`, `enqueue_ms`, `queue_depth`, `dropped_before`, `send_ms`, `bytes_sent`, `frame_age_at_send_ms`, `send_failed`, `keyframe`, and `sender_dropped`.

List available VideoToolbox encoders on the current Mac:

```bash
apps/primary-macos/.build/release/ibridge-primary --list-encoders
```

Run the Plan C low-latency matrix:

```bash
scripts/mac_plan_c_encode_matrix.sh
```

This first CLI spike uses synthetic BGRA frames and VideoToolbox. ScreenCaptureKit capture and transport are separate follow-up steps so virtual-display research does not block the frame pipeline.
