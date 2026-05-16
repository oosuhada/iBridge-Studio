# 2017 iMac macOS Receiver Live Smoke

Date: 2026-05-17

## Setup

- Primary: MacBook Pro M1 Max
- Receiver: 2017 21.5-inch Retina 4K iMac, macOS 15.7.7 via OCLP
- Network: direct 1GbE link-local
- Receiver IP: `169.254.70.114`
- Receiver: `apps/receiver-macos/.build/release/ibridge-receiver-macos --port 48320 --fullscreen`

## Results

| Mode | Frames encoded | Sender drops | Send failures | Avg encode ms | P95 encode ms | Avg send ms | Receiver result |
|---|---:|---:|---:|---:|---:|---:|---|
| `1920x1080@60` HEVC | 300/300 | 0 | 0 | 13.325 | 19.448 | 0.074 | receiver logged 300 frames |
| `3840x2160@60` HEVC | 720/720 | 0 | 0 | 56.705 | 73.049 | 0.047 | receiver logged frame receipt through frame 660 before sender disconnect |

## Read

- The live macOS receiver plumbing works on the 2017 iMac.
- The user observed the iMac screen changing during the run.
- SSH `screencapture` did not reliably capture the receiver's
  `AVSampleBufferDisplayLayer` output, so remote screenshots are weak evidence
  for this path.
- The 4K run proves live frame transport/decode/display plumbing, not smooth
  4K60 interaction. Sender backpressure or frame dropping is still needed to
  keep latency bounded when encode falls behind.
