# One Command Virtual Display Smoke

- Command: `DURATION=3 scripts/start_ibridge_mba_2015.sh`.
- Source: MacBook Air `Virtual 16:9` extended display.
- Capture display: `display_index=1`, `1920x1080`, frame origin `(1440, 0)`.
- Receiver: 2015 iMac macOS receiver over Tailscale `100.84.32.31:48320`.
- Profile: HEVC, Annex-B, `1920x1080 @ 30fps`, 8Mbps target.

## Result

- Sender requested/submitted/encoded: `90/27/27` frames over 3 seconds.
- Failed frames: `0`.
- Send failures: `0`.
- Sender queue drops: `0`.
- Receiver frames total: `27`.
- Display list confirmed `Virtual 16:9` is capture index `1`.

## Read

The one-command startup path works for the current virtual extended display. The
submitted-frame count is low because the virtual desktop was mostly static;
move the cursor or a window on `Virtual 16:9` to force updates.
