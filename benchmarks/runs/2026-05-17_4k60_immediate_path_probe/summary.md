# 4K60 Immediate Connection Probe

Date: 2026-05-17

Goal: verify that the MacBook Pro can immediately connect to the 2017 iMac
receiver with the 4K60 profile after deploying the latest Intel receiver binary.

Receiver:

- Host: `169.254.70.114`
- Port: `48320`
- Binary: `~/ibridge-remote/latest/ibridge-receiver-macos`
- Mode: fullscreen, status overlay hidden

Source display:

- BetterDisplay `Virtual 16:9`
- System physical mode: `3840x2160 @ 60Hz`
- HiDPI UI mode: `1920x1080`
- ScreenCaptureKit display: `display_index=1`, `width=1920`, `height=1080`

Sender profile:

- `PROFILE=lan-4k`
- requested stream resolution: `3840x2160`
- target fps: `60`
- codec: HEVC
- bitrate: `80Mbps`
- capture max in-flight frames: `1`

Result:

- requested/submitted/encoded: `180/26/26`
- failed frames: `0`
- sender dropped frames: `0`
- send failed frames: `0`
- avg encode: `22.698 ms`
- p95 encode: `24.576 ms`
- avg send: `0.755 ms`
- p95 send: `3.080 ms`

Interpretation:

- The path is immediately connectable now: latest receiver is running on the
  2017 iMac and the sender can attach to it over direct LAN.
- This is not a full quality pass. It verifies connection and 4K60-profile
  stream setup, while active-window/readability testing remains pending.
