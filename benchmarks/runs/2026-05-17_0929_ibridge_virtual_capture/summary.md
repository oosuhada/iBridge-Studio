# iBridge LAN High Quality Virtual Capture Smoke

Date: 2026-05-17

Receiver: 2017 4K iMac over direct 1GbE, `169.254.70.114:48320`.

Command profile:

- `PROFILE=lan-readable`
- `2560x1440 @ 30fps`
- HEVC Annex-B
- 35Mbps
- `capture_max_in_flight_frames=1`
- sender queue depth `12`
- capture queue depth `6`

Display selection:

- `capture_display_count=2`
- selected `display_index=1`
- selected display frame `(1512.0, 0.0, 1920.0, 1080.0)`

Sender result:

- requested/submitted/encoded: `90/46/46`
- skipped by capture backpressure/static capture cadence: `44`
- failed frames: `0`
- sender dropped frames: `0`
- send failed frames: `0`
- avg encode: `14.754 ms`
- p95 encode: `17.101 ms`
- max encode: `47.041 ms`
- avg send: `0.243 ms`
- p95 send: `0.877 ms`

Receiver result:

- protocol handshake received for `2560x1440 @ 30fps`
- receiver logged `46` frames before disconnect
- one 1-frame missing event was logged before frame `2`

Interpretation:

- The packaged LAN high-quality command can now auto-select the extended display
  and send a live ScreenCaptureKit stream over wired LAN.
- Capture-side backpressure kept the sender from building a stale backlog; this
  is a better product default for high-detail profiles than trying to encode
  every captured frame.
- This is still a short smoke, not a final quality pass. Next runs should use a
  longer active-window/cursor movement scenario and collect direct visual
  feedback from the iMac panel.
