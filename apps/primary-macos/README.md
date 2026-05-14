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

Send encoded frames to a protocol v0 TCP receiver sink:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 5120x2880 --fps 60 --duration 1 --codec hevc --bitrate-mbps 120 --send-host 100.86.52.88 --send-port 48320 --csv benchmarks/runs/YYYY-MM-DD_HHMM_plan_b_5k_hevc_tcp/primary_stats.csv
```

This first CLI spike uses synthetic BGRA frames and VideoToolbox. ScreenCaptureKit capture and transport are separate follow-up steps so virtual-display research does not block the frame pipeline.
