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
opens as a standard macOS fullscreen window, and hides the debug status overlay.
Use `Command-F` to toggle fullscreen and `Esc` to leave fullscreen.

If macOS blocks the app because this alpha is ad-hoc signed, open it with
right-click > Open or remove quarantine for local lab testing:

```bash
xattr -dr com.apple.quarantine "iBridge Receiver.app"
```

## Source Mac

1. In BetterDisplay, keep `Virtual 16:9` connected as an extended display.
2. In macOS Displays, keep it as `Extended display`.
3. When BetterDisplay `Virtual 16:9` is set to 4K60, run:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ 4K60.command
```

For the safer wired readability profile, run:

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
| `lan-4k` | `3840x2160` | 60 | 80Mbps | 4K60 wired mode |

All profiles use HEVC Annex-B protocol v0. Auto-selection chooses the largest
non-origin extended display unless `CAPTURE_DISPLAY_INDEX` is provided.

Input relay is enabled by default. The receiver captures mouse and keyboard
events over the video surface, sends them back over the existing TCP connection,
and the source sender injects them into the captured display with `CGEvent`.
The source Mac may require Accessibility permission for the sender process.

The wired profiles also enable capture-side backpressure with
`CAPTURE_MAX_IN_FLIGHT_FRAMES=1`, so the sender prefers newer frames over
building a stale encode backlog when the encoder falls behind.

Override display selection when needed:

```bash
CAPTURE_DISPLAY_INDEX=1 RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Virtual\ Capture.command
```

Run a short smoke:

```bash
DURATION=3 RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ 4K60.command
```

From the repository checkout, the current one-command MacBook Pro -> 2017 iMac
wired path is:

```bash
scripts/start_mbp_to_2017_imac_4k60.sh
```

This first deploys the latest Intel receiver binary to the 2017 iMac over SSH,
starts it fullscreen with the status overlay hidden, then starts the local 4K60
sender.

If the sender prints `capture_display_count=0`, macOS is not exposing a
ScreenCaptureKit-capturable display to the sender. Reconnect the BetterDisplay
virtual screen, confirm it is an extended display instead of AirPlay mirroring,
and recheck Screen Recording permission.

## Current Limits

- Source Mac requires Screen Recording permission.
- Source Mac requires Accessibility permission for input relay.
- 4K virtual capture has been proven, but the current default is 1080p60
  because it is a safer alpha profile.
- 4K60 smoothness is not yet product-grade.
- Receiver app packaging is macOS-only for this alpha.
- The package is ad-hoc signed and not notarized.
