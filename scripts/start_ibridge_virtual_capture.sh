#!/usr/bin/env bash
set -euo pipefail

PROFILE="${PROFILE:-balanced}"
RECEIVER_IP="${RECEIVER_IP:-169.254.70.114}"
RECEIVER_PORT="${RECEIVER_PORT:-48320}"
DURATION="${DURATION:-3600}"
CAPTURE_DISPLAY_INDEX="${CAPTURE_DISPLAY_INDEX:-auto}"
RUN_ROOT="${RUN_ROOT:-benchmarks/runs/$(date +%Y-%m-%d_%H%M)_ibridge_virtual_capture}"
PRIMARY_BIN="${PRIMARY_BIN:-}"

case "$PROFILE" in
  balanced)
    DEFAULT_RESOLUTION="1920x1080"
    DEFAULT_FPS="60"
    DEFAULT_BITRATE_MBPS="25"
    DEFAULT_SENDER_QUEUE_DEPTH="8"
    DEFAULT_CAPTURE_QUEUE_DEPTH="4"
    DEFAULT_CAPTURE_MAX_IN_FLIGHT_FRAMES="2"
    ;;
  lan-readable)
    DEFAULT_RESOLUTION="2560x1440"
    DEFAULT_FPS="30"
    DEFAULT_BITRATE_MBPS="35"
    DEFAULT_SENDER_QUEUE_DEPTH="12"
    DEFAULT_CAPTURE_QUEUE_DEPTH="6"
    DEFAULT_CAPTURE_MAX_IN_FLIGHT_FRAMES="1"
    ;;
  lan-60hz)
    DEFAULT_RESOLUTION="2560x1440"
    DEFAULT_FPS="60"
    DEFAULT_BITRATE_MBPS="45"
    DEFAULT_SENDER_QUEUE_DEPTH="12"
    DEFAULT_CAPTURE_QUEUE_DEPTH="6"
    DEFAULT_CAPTURE_MAX_IN_FLIGHT_FRAMES="1"
    ;;
  lan-sharp)
    DEFAULT_RESOLUTION="3200x1800"
    DEFAULT_FPS="30"
    DEFAULT_BITRATE_MBPS="50"
    DEFAULT_SENDER_QUEUE_DEPTH="12"
    DEFAULT_CAPTURE_QUEUE_DEPTH="6"
    DEFAULT_CAPTURE_MAX_IN_FLIGHT_FRAMES="1"
    ;;
  lan-4k)
    DEFAULT_RESOLUTION="3840x2160"
    DEFAULT_FPS="60"
    DEFAULT_BITRATE_MBPS="80"
    DEFAULT_SENDER_QUEUE_DEPTH="12"
    DEFAULT_CAPTURE_QUEUE_DEPTH="6"
    DEFAULT_CAPTURE_MAX_IN_FLIGHT_FRAMES="1"
    ;;
  imac4k-quality)
    DEFAULT_RESOLUTION="4096x2304"
    DEFAULT_FPS="60"
    DEFAULT_BITRATE_MBPS="220"
    DEFAULT_SENDER_QUEUE_DEPTH="12"
    DEFAULT_CAPTURE_QUEUE_DEPTH="6"
    DEFAULT_CAPTURE_MAX_IN_FLIGHT_FRAMES="1"
    ;;
  *)
    echo "Unknown PROFILE=$PROFILE. Use balanced, lan-readable, lan-60hz, lan-sharp, lan-4k, or imac4k-quality." >&2
    exit 64
    ;;
esac

RESOLUTION="${RESOLUTION:-$DEFAULT_RESOLUTION}"
FPS="${FPS:-$DEFAULT_FPS}"
BITRATE_MBPS="${BITRATE_MBPS:-$DEFAULT_BITRATE_MBPS}"
SENDER_QUEUE_DEPTH="${SENDER_QUEUE_DEPTH:-$DEFAULT_SENDER_QUEUE_DEPTH}"
CAPTURE_QUEUE_DEPTH="${CAPTURE_QUEUE_DEPTH:-$DEFAULT_CAPTURE_QUEUE_DEPTH}"
CAPTURE_MAX_IN_FLIGHT_FRAMES="${CAPTURE_MAX_IN_FLIGHT_FRAMES:-$DEFAULT_CAPTURE_MAX_IN_FLIGHT_FRAMES}"
CAPTURE_SHOW_CURSOR="${CAPTURE_SHOW_CURSOR:-0}"
CURSOR_ARGS=()
if [[ "$CAPTURE_SHOW_CURSOR" == "1" || "$CAPTURE_SHOW_CURSOR" == "true" || "$CAPTURE_SHOW_CURSOR" == "on" ]]; then
  CURSOR_ARGS=(--show-captured-cursor)
else
  CURSOR_ARGS=(--hide-captured-cursor)
fi

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
        idx = ""; frame = ""; width = 0; height = 0;
        for (i = 1; i <= NF; i++) {
          if ($i ~ /^display_index=/) {
            split($i, a, "="); idx = a[2]
          }
          if ($i ~ /^width=/) {
            split($i, w, "="); width = w[2]
          }
          if ($i ~ /^height=/) {
            split($i, h, "="); height = h[2]
          }
          if ($i ~ /^frame=/) {
            frame = substr($0, index($0, "frame="))
          }
        }
        if (idx != "" && index(frame, "frame=(0.0, 0.0,") != 1) {
          area = width * height
          if (area > best_area) {
            best_area = area
            best_idx = idx
          }
        }
      }
      END {
        if (best_idx != "") {
          print best_idx
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
- Profile: $PROFILE
- Receiver: $RECEIVER_IP:$RECEIVER_PORT
- Capture display index: $CAPTURE_DISPLAY_INDEX
- Resolution/FPS: $RESOLUTION @ $FPS
- Bitrate: ${BITRATE_MBPS}Mbps
- Capture max in-flight frames: $CAPTURE_MAX_IN_FLIGHT_FRAMES
- Captured cursor: $CAPTURE_SHOW_CURSOR
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
  --capture-max-in-flight-frames "$CAPTURE_MAX_IN_FLIGHT_FRAMES" \
  "${CURSOR_ARGS[@]}" \
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
