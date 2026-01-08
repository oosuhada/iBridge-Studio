# BetterDisplay And 2017 4K Receiver Check

Date: 2026-05-17

## Current Answer

BetterDisplay can likely solve the source-Mac virtual display / HiDPI setup
piece quickly, but it does not replace iBridge's network transport and iMac
receiver path.

Use BetterDisplay as a practical source-display helper:

1. Create a 16:9 virtual screen on the MacBook.
2. Set a 3840x2160 or useful HiDPI mode.
3. Capture that virtual display with iBridge.
4. Send it to the iMac receiver over the measured 1GbE path.

Do not treat BetterDisplay installation alone as proof that the 2017 iMac is a
low-latency external monitor. The iMac still needs a receiver app or another
remote-display transport.

## Source Check

- BetterDisplay's current public feature list includes virtual screens,
  Picture in Picture, local streaming, CLI integration, and headless Mac virtual
  screen use. [내용 출처 : https://github.com/waydabber/BetterDisplay/blob/landing/README.md]
- The current public README lists v4.3.3 for macOS Tahoe 26, Sequoia, Sonoma,
  and Ventura, and says some features require a Pro license. [내용 출처 : https://github.com/waydabber/BetterDisplay/blob/landing/README.md]
- The `opensource` branch in `reference/BetterDisplay` is BetterDummy OpenSource
  Edition, not the full current BetterDisplay v4 app. [내용 출처 : https://github.com/waydabber/BetterDisplay/tree/opensource]
- The CLI can create and control virtual screens when BetterDisplay is installed
  and CLI commands are enabled. [내용 출처 : https://github.com/waydabber/BetterDisplay/discussions/2032]

## Fork / Customization Read

`reference/BetterDisplay` is useful enough for a clean-room iBridge
virtual-display helper because it contains:

- `BetterDummy/Bridging-Header.h`: private `CGVirtualDisplay`,
  `CGVirtualDisplayDescriptor`, `CGVirtualDisplayMode`, and
  `CGVirtualDisplaySettings` declarations.
- `BetterDummy/Model/Dummy.swift`: compact create/connect/disconnect logic for
  `CGVirtualDisplay`.
- `BetterDummy/Support/DisplayManager.swift`: display enumeration and virtual
  display detection via CoreDisplay metadata.
- `BetterDummy/Support/AppMenu.swift`: resolution listing and HiDPI mode menu
  patterns.

It is not enough to fork and customize the full current BetterDisplay product,
because the tracked open-source branch is older BetterDummy code and does not
include the modern v4 feature surface, Pro feature implementation, or current
app architecture. For iBridge, that is fine: the required near-term custom work
is virtual display creation and capture integration, not cloning the full
BetterDisplay app.

## Live 2017 4K iMac Result

Receiver path tested:

- Source: MacBook Pro M1 Max
- Receiver: 2017 21.5-inch Retina 4K iMac, macOS 15.7.7 via OCLP
- Network: direct 1GbE link-local, receiver `169.254.70.114`
- Receiver app: `apps/receiver-macos`

Validation:

- `swift build --package-path apps/receiver-macos -c release`: passed locally.
- `swift build --package-path apps/primary-macos -c release`: passed locally.
- Remote Intel iMac receiver build: passed on the iMac.
- `1920x1080@60` HEVC live send: 300/300 frames encoded and received, sender
  drop/send-failure count 0.
- `3840x2160@60` HEVC live send: 720/720 frames encoded and received, sender
  drop/send-failure count 0.

Important caveat:

- The user reported the iMac screen visibly changed, but SSH
  `screencapture` did not capture the AVSampleBufferDisplayLayer content
  reliably. Treat remote screenshots as weak evidence for this receiver path;
  runtime receiver logs and visible local observation are stronger.
- The 12-second 4K synthetic run received every frame, but encode callback
  latency was high in this run: avg `56.705 ms`, p95 `73.049 ms`, max
  `107.609 ms`. This proves live 4K display plumbing, not final smooth 4K60
  interaction.

## Product Direction

1. Keep iBridge as the receiver/transport layer.
2. Use BetterDisplay or a small clean-room `CGVirtualDisplay` helper to create
   the source Mac's virtual extended desktop.
3. Add a live capture path from that virtual display into `ibridge-primary`.
4. Add sender backpressure/frame dropping for 4K so latency stays bounded when
   encode falls behind.
5. Use `2560x1440@60` or `3200x1800@60` as smoother practical profiles while
   4K latency is being tuned.
