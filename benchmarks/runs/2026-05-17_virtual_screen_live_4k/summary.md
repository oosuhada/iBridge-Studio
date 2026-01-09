# BetterDisplay Virtual Screen Live Capture Smoke

Date: 2026-05-17

## Setup

- Source virtual display: BetterDisplay `Virtual 16:9`
- macOS display mode: UI looks like `1920x1080 @ 60Hz`
- Backing pixels: `3840x2160`
- Primary: MacBook Pro M1 Max
- Receiver: 2017 21.5-inch Retina 4K iMac
- Receiver IP: `169.254.70.114`
- Network: direct 1GbE

## Results

| Capture/output mode | Frames submitted | Frames encoded | Sender drops | Send failures | Avg encode ms | P95 encode ms | Avg send ms | Receiver result |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `3840x2160@60` | 299/600 | 299 | 0 | 0 | 32.346 | 64.015 | 0.468 | receiver logged 299 frames |
| `1920x1080@60` downscale | 255/600 | 255 | 0 | 0 | 13.793 | 22.332 | 0.510 | receiver logged 255 frames |

## Read

- BetterDisplay virtual screen capture works with iBridge.
- `Virtual 16:9` is a valid source for ScreenCaptureKit and live iMac
  receiver transport.
- The current static desktop only submitted changed frames, so this is not a
  full 60fps motion test.
- 4K backing-pixel capture is too latent for a final smooth mode in this run.
- Downscaled `1920x1080` output is much closer to interactive budget and is the
  safer next practical mode while backpressure/frame-drop policy is added.

## Next

1. Add explicit display selection by display name or ID instead of relying on
   `--capture-display-index 0`.
2. Add live sender backpressure / newest-frame-wins dropping.
3. Add a one-command launcher that starts the iMac receiver and captures the
   BetterDisplay virtual screen.
