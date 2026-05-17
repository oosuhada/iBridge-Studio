# Live Capture Helper Script Smoke

- Command: `DURATION=3 scripts/start_mba_to_2015_imac_live_capture.sh`.
- Profile: `2560x1440 @ 30fps`, HEVC, Annex-B, 15Mbps target.

## Result

- Sender requested/submitted/encoded: `90/90/90` frames.
- Sender failed frames: `0`.
- Sender send failures: `0`.
- Sender queue drops: `0`.
- Receiver log was copied to the run directory.

## Read

The helper script works for the current MacBook Air -> 2015 iMac live-capture
path. Default duration is 3600 seconds for practical use; set `DURATION=...` for
shorter tests.
