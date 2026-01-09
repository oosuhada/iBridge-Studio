#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-0.1.0-alpha}"
DIST_ROOT="${DIST_ROOT:-dist}"
PACKAGE_ROOT="$DIST_ROOT/iBridge-$VERSION"
RECEIVER_APP="$PACKAGE_ROOT/iBridge Receiver.app"
PRIMARY_BIN="apps/primary-macos/.build/release/ibridge-primary"
RECEIVER_BIN="apps/receiver-macos/.build/release/ibridge-receiver-macos"

rm -rf "$PACKAGE_ROOT"
mkdir -p "$RECEIVER_APP/Contents/MacOS" "$RECEIVER_APP/Contents/Resources"
mkdir -p "$PACKAGE_ROOT/bin" "$PACKAGE_ROOT/scripts" "$PACKAGE_ROOT/docs"

swift build --package-path apps/primary-macos -c release
swift build --package-path apps/receiver-macos -c release

cp "$RECEIVER_BIN" "$RECEIVER_APP/Contents/MacOS/iBridgeReceiver"
cp "$PRIMARY_BIN" "$PACKAGE_ROOT/bin/ibridge-primary"
cp scripts/start_ibridge_virtual_capture.sh "$PACKAGE_ROOT/scripts/start_ibridge_virtual_capture.sh"
cp scripts/start_2015_imac_receiver_macos.sh "$PACKAGE_ROOT/scripts/start_2015_imac_receiver_macos.sh"
cp scripts/stop_2015_imac_receiver_macos.sh "$PACKAGE_ROOT/scripts/stop_2015_imac_receiver_macos.sh"
cp docs/18_ALPHA_RELEASE.md "$PACKAGE_ROOT/docs/18_ALPHA_RELEASE.md"

cat > "$RECEIVER_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>iBridgeReceiver</string>
  <key>CFBundleIdentifier</key>
  <string>dev.oosu.iBridge.receiver</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>iBridge Receiver</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
</dict>
</plist>
PLIST

cat > "$RECEIVER_APP/Contents/MacOS/iBridgeReceiver.command" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$DIR/iBridgeReceiver" --port "${PORT:-48320}" --fullscreen --hide-status --title "iBridge Receiver"
SCRIPT

cat > "$PACKAGE_ROOT/Start iBridge Virtual Capture.command" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
exec scripts/start_ibridge_virtual_capture.sh
SCRIPT

cat > "$PACKAGE_ROOT/Start iBridge LAN High Quality.command" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
export PROFILE="${PROFILE:-lan-readable}"
exec scripts/start_ibridge_virtual_capture.sh
SCRIPT

cat > "$PACKAGE_ROOT/Start iBridge 4K60.command" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
export PROFILE="${PROFILE:-lan-4k}"
exec scripts/start_ibridge_virtual_capture.sh
SCRIPT

cat > "$PACKAGE_ROOT/README.md" <<'README'
# iBridge Alpha

This is an internal alpha package for local testing.

## Receiver iMac

Open `iBridge Receiver.app` on the receiver iMac. It listens on TCP `48320`,
opens a fullscreen borderless receiver window, and hides the debug status
overlay by default.

## Source Mac

1. Keep BetterDisplay `Virtual 16:9` connected as an extended display.
2. Set `RECEIVER_IP` if needed.
3. Run `Start iBridge 4K60.command` when BetterDisplay `Virtual 16:9` is set
   to 4K60, `Start iBridge LAN High Quality.command` for the safer wired
   readability profile, or `Start iBridge Virtual Capture.command` for the
   balanced default.

Default sender profile:

- `1920x1080 @ 60fps`
- HEVC
- 25Mbps
- receiver endpoint from `RECEIVER_IP`

Wired high-quality profile:

- `2560x1440 @ 30fps`
- HEVC
- 35Mbps
- `PROFILE=lan-readable`

4K60 wired profile:

- `3840x2160 @ 60fps`
- HEVC
- 80Mbps
- `PROFILE=lan-4k`

Example:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Virtual\ Capture.command
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ LAN\ High\ Quality.command
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ 4K60.command
```

For a lighter smoke:

```bash
FPS=30 BITRATE_MBPS=8 RECEIVER_IP=100.84.32.31 ./Start\ iBridge\ Virtual\ Capture.command
```

## Current Limits

- This alpha is not notarized.
- Screen Recording permission is required for the source sender.
- 4K capture works but is not yet smooth enough for the default profile.
- Display auto-selection chooses the first non-origin extended display; use
  `CAPTURE_DISPLAY_INDEX=<n>` if the wrong display is selected.

See `docs/18_ALPHA_RELEASE.md` for the repo release notes.
README

chmod +x \
  "$RECEIVER_APP/Contents/MacOS/iBridgeReceiver" \
  "$RECEIVER_APP/Contents/MacOS/iBridgeReceiver.command" \
  "$PACKAGE_ROOT/bin/ibridge-primary" \
  "$PACKAGE_ROOT/scripts/start_ibridge_virtual_capture.sh" \
  "$PACKAGE_ROOT/scripts/start_2015_imac_receiver_macos.sh" \
  "$PACKAGE_ROOT/scripts/stop_2015_imac_receiver_macos.sh" \
  "$PACKAGE_ROOT/Start iBridge Virtual Capture.command" \
  "$PACKAGE_ROOT/Start iBridge LAN High Quality.command" \
  "$PACKAGE_ROOT/Start iBridge 4K60.command"

codesign --force --deep --sign - "$RECEIVER_APP" >/dev/null 2>&1 || true

(cd "$DIST_ROOT" && ditto -c -k --sequesterRsrc --keepParent "iBridge-$VERSION" "iBridge-$VERSION.zip")

echo "$PACKAGE_ROOT"
echo "$DIST_ROOT/iBridge-$VERSION.zip"
