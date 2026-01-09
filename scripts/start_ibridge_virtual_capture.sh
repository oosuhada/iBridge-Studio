#!/usr/bin/env bash
set -euo pipefail

RECEIVER_IP="${RECEIVER_IP:-169.254.70.114}"
RECEIVER_PORT="${RECEIVER_PORT:-48320}"
RESOLUTION="${RESOLUTION:-1920x1080}"
FPS="${FPS:-60}"
DURATION="${DURATION:-3600}"
BITRATE_MBPS="${BITRATE_MBPS:-25}"
SENDER_QUEUE_DEPTH="${SENDER_QUEUE_DEPTH:-8}"
CAPTURE_QUEUE_DEPTH="${CAPTURE_QUEUE_DEPTH:-4}"
CAPTURE_DISPLAY_INDEX="${CAPTURE_DISPLAY_INDEX:-auto}"
RUN_ROOT="${RUN_ROOT:-benchmarks/runs/$(date +%Y-%m-%d_%H%M)_ibridge_virtual_capture}"
PRIMARY_BIN="${PRIMARY_BIN:-}"

mkdir -p "$RUN_ROOT"

if [[ -z "$PRIMARY_BIN" ]]; then
  if [[ -f "apps/primary-macos/Package.swift" ]]; then
    swift build --package-path apps/primary-macos -c release
    PRIMARY_BIN="apps/primary-macos/.build/release/ibridge-primary"
  elif [[ -x "bin/ibridge-primary" ]]; then
    PRIMARY_BIN="bin/ibridge-primary"
  else
    echo "Could not find iBridge primary binary. Run from the repo root or packaged iBridge folder." >&2
    exit 1
  fi
fi

display_list="$RUN_ROOT/capture_displays.txt"
"$PRIMARY_BIN" --list-displays | tee "$display_list"

display_count="$(
  awk -F= '/^capture_display_count=/ { print $2; exit }' "$display_list"
)"
if [[ "${display_count:-0}" == "0" ]]; then
  cat <<EOF >&2
iBridge could not see a ScreenCaptureKit-capturable display.

Check these before retrying:
- BetterDisplay virtual screen is connected.
- macOS Displays shows it as Extended display, not AirPlay mirroring.
- Terminal/Codex/packaged sender has Screen Recording permission.
- The display is awake.

Display list was written to $display_list
EOF
  exit 2
fi

if [[ "$CAPTURE_DISPLAY_INDEX" == "auto" ]]; then
  CAPTURE_DISPLAY_INDEX="$(
    awk '
      /display_index=/ {
        idx = ""; frame = "";
        for (i = 1; i <= NF; i++) {
          if ($i ~ /^display_index=/) {
            split($i, a, "="); idx = a[2]
          }
          if ($i ~ /^frame=/) {
            frame = substr($0, index($0, "frame="))
          }
        }
        if (idx != "" && frame !~ /frame=\\(0\\.0, 0\\.0,/) {
          print idx
          exit
        }
      }
    ' "$display_list"
  )"
  if [[ -z "$CAPTURE_DISPLAY_INDEX" ]]; then
    CAPTURE_DISPLAY_INDEX="0"
  fi
fi

cat <<EOF
iBridge virtual display sender
- Receiver: $RECEIVER_IP:$RECEIVER_PORT
- Capture display index: $CAPTURE_DISPLAY_INDEX
- Resolution/FPS: $RESOLUTION @ $FPS
- Bitrate: ${BITRATE_MBPS}Mbps
- Duration: ${DURATION}s
- Run root: $RUN_ROOT

Keep the BetterDisplay virtual screen connected as an extended display. Move a
window or cursor on that virtual screen if a static desktop emits few frames.
EOF

"$PRIMARY_BIN" \
  --screen-capture \
  --source screen-capture \
  --capture-display-index "$CAPTURE_DISPLAY_INDEX" \
  --capture-queue-depth "$CAPTURE_QUEUE_DEPTH" \
  --resolution "$RESOLUTION" \
  --fps "$FPS" \
  --duration "$DURATION" \
  --codec hevc \
  --bitrate-mbps "$BITRATE_MBPS" \
  --data-rate-limit-mbps "$BITRATE_MBPS" \
  --disable-low-latency-rate-control \
  --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc \
  --disable-frame-reordering \
  --disable-open-gop \
  --payload-format annex-b \
  --sender-queue-depth "$SENDER_QUEUE_DEPTH" \
  --send-host "$RECEIVER_IP" \
  --send-port "$RECEIVER_PORT" \
  --csv "$RUN_ROOT/primary_stats.csv" 2>&1 | tee "$RUN_ROOT/primary_console.txt"

echo "Wrote $RUN_ROOT"
