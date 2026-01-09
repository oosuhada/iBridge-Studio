# iBridge macOS Alpha Release

Date: 2026-05-17

## Scope

This alpha is an internal Mac-to-Mac release path for testing iBridge as a
software external display:

- source Mac: BetterDisplay virtual extended display + iBridge sender
- receiver iMac: iBridge Receiver macOS app
- transport: local TCP, default port `48320`

This is not an App Store, signed Developer ID, or notarized release yet.

## Build Package

From the repository root:

```bash
scripts/package_macos_alpha.sh
```

Outputs:

- `dist/iBridge-0.1.0-alpha/`
- `dist/iBridge-0.1.0-alpha.zip`

The package includes:

- `iBridge Receiver.app`
- `bin/ibridge-primary`
- `Start iBridge Virtual Capture.command`
- helper scripts under `scripts/`
- package-local `README.md`

## Receiver iMac

Open `iBridge Receiver.app` on the iMac. The receiver listens on TCP `48320`,
opens fullscreen, and hides the debug status overlay.

If macOS blocks the app because this alpha is ad-hoc signed, open it with
right-click > Open or remove quarantine for local lab testing:

```bash
xattr -dr com.apple.quarantine "iBridge Receiver.app"
```

## Source Mac

1. In BetterDisplay, keep `Virtual 16:9` connected as an extended display.
2. In macOS Displays, keep it as `Extended display`.
3. For wired use, run:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ LAN\ High\ Quality.command
```

For the safer balanced default, run:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Virtual\ Capture.command
```

Profiles:

| Profile | Resolution | FPS | Bitrate | Use |
| --- | --- | ---: | ---: | --- |
| `balanced` | `1920x1080` | 60 | 25Mbps | safer default |
| `lan-readable` | `2560x1440` | 30 | 35Mbps | wired text/readability default |
| `lan-60hz` | `2560x1440` | 60 | 45Mbps | experimental motion-first wired mode |
| `lan-sharp` | `3200x1800` | 30 | 50Mbps | experimental sharper wired mode |
| `lan-4k` | `3840x2160` | 30 | 60Mbps | experimental 4K wired mode |

All profiles use HEVC Annex-B protocol v0 and auto-select the first non-origin
extended display unless `CAPTURE_DISPLAY_INDEX` is provided.

Override display selection when needed:

```bash
CAPTURE_DISPLAY_INDEX=1 RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Virtual\ Capture.command
```

Run a short smoke:

```bash
DURATION=3 RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ LAN\ High\ Quality.command
```

If the sender prints `capture_display_count=0`, macOS is not exposing a
ScreenCaptureKit-capturable display to the sender. Reconnect the BetterDisplay
virtual screen, confirm it is an extended display instead of AirPlay mirroring,
and recheck Screen Recording permission.

## Current Limits

- Source Mac requires Screen Recording permission.
- 4K virtual capture has been proven, but the current default is 1080p60
  because it is a safer alpha profile.
- 4K60 smoothness is not yet product-grade.
- Receiver app packaging is macOS-only for this alpha.
- The package is ad-hoc signed and not notarized.
