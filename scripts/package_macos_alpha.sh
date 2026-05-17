#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-0.1.0-alpha}"
DIST_ROOT="${DIST_ROOT:-dist}"
PACKAGE_ROOT="$DIST_ROOT/iBridge-$VERSION"
RECEIVER_APP="$PACKAGE_ROOT/iBridge Receiver.app"
CONTROL_APP="$PACKAGE_ROOT/iBridge Studio.app"
PRIMARY_BIN="apps/primary-macos/.build/release/ibridge-primary"
CONTROL_BIN="apps/controller-macos/.build/release/iBridgeController"
RECEIVER_ARM64_BIN="apps/receiver-macos/.build/arm64-apple-macosx/release/ibridge-receiver-macos"
RECEIVER_X86_64_BIN="apps/receiver-macos/.build/x86_64-apple-macosx/release/ibridge-receiver-macos"
RECEIVER_UNIVERSAL_BIN="$PACKAGE_ROOT/bin/ibridge-receiver-macos-universal"

rm -rf "$PACKAGE_ROOT"
mkdir -p "$RECEIVER_APP/Contents/MacOS" "$RECEIVER_APP/Contents/Resources"
mkdir -p "$CONTROL_APP/Contents/MacOS" "$CONTROL_APP/Contents/Resources"
mkdir -p "$PACKAGE_ROOT/bin" "$PACKAGE_ROOT/scripts" "$PACKAGE_ROOT/docs"

make_icon() {
  local icon_name="$1"
  local output_dir="$2"
  local iconset="$output_dir/${icon_name}.iconset"
  mkdir -p "$iconset"
  ICONSET="$iconset" python3 - <<'PY'
import os, struct, zlib

iconset = os.environ["ICONSET"]
sizes = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}

def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)

def write_png(path, size):
    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            nx = x / max(size - 1, 1)
            ny = y / max(size - 1, 1)
            margin = int(size * 0.11)
            radius = int(size * 0.18)
            inside = margin <= x < size - margin and margin <= y < size - margin
            corner = False
            for cx, cy in ((margin + radius, margin + radius), (size - margin - radius - 1, margin + radius), (margin + radius, size - margin - radius - 1), (size - margin - radius - 1, size - margin - radius - 1)):
                if (x < margin + radius and cx < size / 2 or x > size - margin - radius and cx > size / 2) and (y < margin + radius and cy < size / 2 or y > size - margin - radius and cy > size / 2):
                    corner = (x - cx) ** 2 + (y - cy) ** 2 > radius ** 2
            if not inside or corner:
                row += bytes((0, 0, 0, 0))
                continue
            r = int(16 + 20 * nx)
            g = int(102 + 96 * ny)
            b = int(205 + 35 * (1 - nx))
            a = 255
            # Two display outlines connected by a bridge.
            lw = max(2, size // 42)
            left = (int(size * 0.23), int(size * 0.35), int(size * 0.43), int(size * 0.58))
            right = (int(size * 0.57), int(size * 0.35), int(size * 0.77), int(size * 0.58))
            white = False
            for rect in (left, right):
                x1, y1, x2, y2 = rect
                if x1 <= x <= x2 and y1 <= y <= y2 and (x - x1 < lw or x2 - x < lw or y - y1 < lw or y2 - y < lw):
                    white = True
            if int(size * 0.45) <= x <= int(size * 0.55) and abs(y - int(size * 0.47)) <= max(1, size // 70):
                white = True
            if white:
                r, g, b, a = 245, 252, 255, 255
            row += bytes((r, g, b, a))
        rows.append(b"\x00" + bytes(row))
    raw = b"".join(rows)
    data = b"\x89PNG\r\n\x1a\n"
    data += png_chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    data += png_chunk(b"IDAT", zlib.compress(raw, 9))
    data += png_chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(data)

for name, size in sizes.items():
    write_png(os.path.join(iconset, name), size)
PY
  iconutil -c icns "$iconset" -o "$output_dir/${icon_name}.icns"
}

make_icon "iBridgeControl" "$CONTROL_APP/Contents/Resources"
make_icon "iBridgeReceiver" "$RECEIVER_APP/Contents/Resources"

swift build --package-path apps/primary-macos -c release
swift build --package-path apps/controller-macos -c release
swift build --package-path apps/receiver-macos -c release --arch arm64
swift build --package-path apps/receiver-macos -c release --arch x86_64

lipo -create "$RECEIVER_ARM64_BIN" "$RECEIVER_X86_64_BIN" -output "$RECEIVER_UNIVERSAL_BIN"
cp "$RECEIVER_UNIVERSAL_BIN" "$RECEIVER_APP/Contents/MacOS/iBridgeReceiver"
cp "$CONTROL_BIN" "$CONTROL_APP/Contents/MacOS/iBridgeControl"
cp "$PRIMARY_BIN" "$PACKAGE_ROOT/bin/ibridge-primary"
cp scripts/start_ibridge_virtual_capture.sh "$PACKAGE_ROOT/scripts/start_ibridge_virtual_capture.sh"
cp scripts/start_2017_imac_receiver_macos.sh "$PACKAGE_ROOT/scripts/start_2017_imac_receiver_macos.sh"
cp scripts/start_mbp_to_2017_imac_4k60.sh "$PACKAGE_ROOT/scripts/start_mbp_to_2017_imac_4k60.sh"
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
  <key>CFBundleIconFile</key>
  <string>iBridgeReceiver</string>
  <key>CFBundleDisplayName</key>
  <string>iBridge Receiver</string>
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

cat > "$CONTROL_APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>iBridgeControl</string>
  <key>CFBundleIconFile</key>
  <string>iBridgeControl</string>
  <key>CFBundleDisplayName</key>
  <string>iBridge Studio</string>
  <key>CFBundleIdentifier</key>
  <string>dev.oosu.iBridge.control</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>iBridge Studio</string>
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
</dict>
</plist>
PLIST

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
opens a standard macOS fullscreen receiver window, and hides the debug status
overlay by default. Use `Command-F` to toggle fullscreen and `Esc` to leave
fullscreen. The receiver app is a universal macOS binary for Apple Silicon and
Intel iMac receivers.

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

Input relay is enabled by default. The receiver sends mouse and keyboard events
back to the source Mac over the same iBridge TCP connection. The source Mac may
ask for Accessibility permission the first time input injection is used.

Example:

```bash
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ Virtual\ Capture.command
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ LAN\ High\ Quality.command
RECEIVER_IP=169.254.70.114 ./Start\ iBridge\ 4K60.command
```

From a repo checkout, the current MacBook Pro -> 2017 iMac wired test path is:

```bash
scripts/start_mbp_to_2017_imac_4k60.sh
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
  "$CONTROL_APP/Contents/MacOS/iBridgeControl" \
  "$RECEIVER_APP/Contents/MacOS/iBridgeReceiver" \
  "$RECEIVER_APP/Contents/MacOS/iBridgeReceiver.command" \
  "$PACKAGE_ROOT/bin/ibridge-primary" \
  "$PACKAGE_ROOT/scripts/start_ibridge_virtual_capture.sh" \
  "$PACKAGE_ROOT/scripts/start_2017_imac_receiver_macos.sh" \
  "$PACKAGE_ROOT/scripts/start_mbp_to_2017_imac_4k60.sh" \
  "$PACKAGE_ROOT/scripts/start_2015_imac_receiver_macos.sh" \
  "$PACKAGE_ROOT/scripts/stop_2015_imac_receiver_macos.sh" \
  "$PACKAGE_ROOT/Start iBridge Virtual Capture.command" \
  "$PACKAGE_ROOT/Start iBridge LAN High Quality.command" \
  "$PACKAGE_ROOT/Start iBridge 4K60.command"

codesign --force --deep --sign - "$CONTROL_APP" >/dev/null 2>&1 || true
codesign --force --deep --sign - "$RECEIVER_APP" >/dev/null 2>&1 || true

(cd "$DIST_ROOT" && ditto -c -k --sequesterRsrc --keepParent "iBridge-$VERSION" "iBridge-$VERSION.zip")

echo "$PACKAGE_ROOT"
echo "$DIST_ROOT/iBridge-$VERSION.zip"
