# iBridge Studio macOS Alpha Release

Date: 2026-05-17

## Scope

This alpha is an internal Mac-to-Mac release path for testing iBridge Studio as a
software Retina display:

- source Mac: BetterDisplay virtual extended display + iBridge Studio sender
- receiver iMac: iBridge Studio Receiver macOS app
- transport: local TCP, default port `48320`

This is not an App Store, signed Developer ID, or notarized release yet.

## Build Package

From the repository root:

```bash
scripts/package_macos_alpha.sh
```

Outputs:

- `dist/iBridge-Studio-0.1.0-alpha/`
- `dist/iBridge-Studio-0.1.0-alpha.zip`

The package includes:

- `iBridge Studio.app`
- `iBridge Studio Receiver.app`
- `bin/ibridge-primary`
- `Start iBridge Studio Virtual Capture.command`
- helper scripts under `scripts/`
- package-local `README.md`

## Receiver iMac

Open `iBridge Studio Receiver.app` on the iMac. The receiver listens on TCP `48320`,
opens as a standard macOS fullscreen window, and hides the debug status overlay.
Use `Command-F` to toggle fullscreen and `Esc` to leave fullscreen.

If macOS blocks the app because this alpha is ad-hoc signed, open it with
right-click > Open or remove quarantine for local lab testing:

```bash
xattr -dr com.apple.quarantine "iBridge Studio Receiver.app"
```

## Source Mac

Open `iBridge Studio.app` on the source Mac for the current lab GUI. The app is
organized around display sessions rather than one global sender form. Each
session card has receiver setup fields, sender signal/profile fields, and
independent start/stop controls. The app also installs a menu bar extra so the
main window can be closed while quick actions remain available.

Current built-in presets:

- `2015 iMac 5K Quality`: `iMac 27inch 2015`, `5120x2880`, 280Mbps.
- `2015 iMac Smooth`: `iMac 27inch 2015`, `2560x1440`, 80Mbps.
- `2017 iMac 4K Quality`: `iMac 21.5inch 2017`, `4096x2304`, 220Mbps.

Use `Add Session` to create a second iMac session before running two receivers
at once. This is the intended GUI path for the MacBook Pro plus two-iMac lab.

If a terminal, browser, or app window is stranded on a virtual display after the
receiver window closes, use `Restore Windows` in the app or menu bar. This
tries to move visible app windows back to the MacBook display area and requires
macOS Accessibility permission for `iBridge Studio`.

The command helpers below remain useful for debugging and repeatable benchmark
runs.

1. In BetterDisplay, keep `Virtual 16:9` connected as an extended display.
2. In macOS Displays, keep it as `Extended display`.
3. When BetterDisplay `Virtual 16:9` is set to 4K60, run:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Studio\ 4K60.command
```

For the safer wired readability profile, run:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Studio\ LAN\ High\ Quality.command
```

For the safer balanced default, run:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Studio\ Virtual\ Capture.command
```

Profiles:

| Profile | Resolution | FPS | Bitrate | Use |
| --- | --- | ---: | ---: | --- |
| `balanced` | `1920x1080` | 60 | 25Mbps | safer default |
| `lan-readable` | `2560x1440` | 30 | 35Mbps | wired text/readability default |
| `lan-60hz` | `2560x1440` | 60 | 45Mbps | experimental motion-first wired mode |
| `lan-sharp` | `3200x1800` | 30 | 50Mbps | experimental sharper wired mode |
| `lan-4k` | `3840x2160` | 60 | 80Mbps | 4K60 wired mode |
| `imac4k-quality` | `4096x2304` | 60 | 220Mbps | current 2017 21.5-inch 4K iMac quality profile |

All profiles use HEVC Annex-B protocol v0. Auto-selection chooses the largest
non-origin extended display unless `CAPTURE_DISPLAY_INDEX` is provided.

Input relay is enabled by default. The receiver captures mouse and keyboard
events over the video surface, sends them back over the existing TCP connection,
and the source sender injects them into the captured display with `CGEvent`.
The source Mac may require Accessibility permission for the sender process.

The wired profiles also enable capture-side backpressure with
`CAPTURE_MAX_IN_FLIGHT_FRAMES=1`, so the sender prefers newer frames over
building a stale encode backlog when the encoder falls behind.

For the 2017 21.5-inch Retina 4K iMac, the current subjective best profile is
BetterDisplay `Virtual 16:9` set to `2048x1152 HiDPI`, with iBridge Studio
`PROFILE=imac4k-quality`. This matches the receiver panel's `4096x2304`
pixel grid more closely than `3840x2160` and keeps the source UI at a practical
Retina scale.

Override display selection when needed:

```bash
CAPTURE_DISPLAY_INDEX=1 RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Studio\ Virtual\ Capture.command
```

Run a short smoke:

```bash
DURATION=3 RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Studio\ 4K60.command
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
