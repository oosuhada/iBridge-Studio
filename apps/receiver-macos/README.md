# receiver-macos

Mac-to-Mac iMac receiver spike.

The first target is a visible 4K60 smoke test on the 2017 21.5-inch Retina 4K
iMac. It listens for protocol v0 TCP frames, accepts HEVC or H.264 Annex-B
payloads from `ibridge-primary`, and displays them with
`AVSampleBufferDisplayLayer`.

Build on the receiver iMac:

```bash
swift build --package-path apps/receiver-macos -c release
```

Run fullscreen on the iMac:

```bash
apps/receiver-macos/.build/release/ibridge-receiver-macos --port 48320 --fullscreen --title "iBridge 4K Receiver"
```

Send a synthetic 4K HEVC stream from the MacBook Pro over direct Ethernet:

```bash
apps/primary-macos/.build/release/ibridge-primary \
  --synthetic \
  --source synthetic-nv12 \
  --resolution 3840x2160 \
  --fps 60 \
  --duration 20 \
  --codec hevc \
  --bitrate-mbps 120 \
  --data-rate-limit-mbps 120 \
  --disable-low-latency-rate-control \
  --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc \
  --disable-frame-reordering \
  --disable-open-gop \
  --payload-format annex-b \
  --send-host 169.254.70.114 \
  --send-port 48320
```

This is a smoke path, not the final product receiver. It intentionally keeps
the protocol simple and records enough console diagnostics to confirm whether
the iMac is receiving and displaying frames.
