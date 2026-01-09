# Virtual 16:9 Default Script Smoke

- User configured macOS `Virtual 16:9` as an extended display at `1920x1080`.
- Script default now captures display index `1`, sends `1920x1080 @ 30fps`, HEVC, 8Mbps, to the 2015 iMac receiver over Tailscale IP `100.84.32.31`.

## Result

- Sender requested/submitted/encoded: `90/28/28` frames over 3 seconds.
- Failed frames: `0`.
- Send failures: `0`.
- Sender queue drops: `0`.
- Receiver log was copied to the run directory.

## Read

The virtual extended display path is wired through the helper script. The low submitted-frame count is expected for a mostly static display; move the cursor or windows on the `Virtual 16:9` desktop to force visible updates.
