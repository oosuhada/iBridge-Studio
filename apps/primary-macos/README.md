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
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 3200x1800 --fps 60 --duration 3 --codec hevc --bitrate-mbps 120 --disable-low-latency-rate-control --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc --data-rate-limit-mbps 120 --csv benchmarks/runs/YYYY-MM-DD_HHMM_primary_1800p60_hevc_ave/primary_stats.csv
```

Use `--list-encoders` first and keep encoder-ID-specific results separate from automatic encoder selection.

Reference-informed VideoToolbox controls:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 3840x2160 --fps 60 --duration 5 --codec hevc --bitrate-mbps 120 \
  --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc \
  --disable-low-latency-rate-control \
  --allow-temporal-compression \
  --disable-frame-reordering \
  --disable-open-gop \
  --data-rate-limit-mbps 120 \
  --payload-format annex-b \
  --csv benchmarks/runs/YYYY-MM-DD_HHMM_vt_property_probe/primary_stats.csv
```

Frame reordering is disabled for latency, but temporal compression is enabled
by default so the encoder can still emit P-frames. `--payload-format annex-b`
adds VPS/SPS/PPS or SPS/PPS before keyframes and converts length-prefixed NALs
to start-code-delimited elementary stream payloads for receiver experiments.

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

Run the reference-informed VideoToolbox property matrix:

```bash
scripts/mac_vt_property_matrix.sh
```

Run the source/strategy matrix:

```bash
scripts/mac_encode_strategy_matrix.sh
```

The Primary CLI can now compare `synthetic-bgra`, `synthetic-nv12`,
`synthetic-static-skip`, and `screen-capture` sources. The strategy matrix
also runs 5K45/5K30 and a 2x2 tiled-session approximation for 5K60.
