#!/usr/bin/env bash
set -euo pipefail

RECEIVER_IP="${RECEIVER_IP:-192.168.31.187}"
RECEIVER_PORT="${RECEIVER_PORT:-48320}"
RECEIVER_SSH="${RECEIVER_SSH:-oosu@100.84.32.31}"
RECEIVER_KEY="${RECEIVER_KEY:-$HOME/.ssh/ibridge_imac_ed25519}"
RESOLUTION="${RESOLUTION:-2560x1440}"
FPS="${FPS:-30}"
DURATION="${DURATION:-3600}"
BITRATE_MBPS="${BITRATE_MBPS:-15}"
SENDER_QUEUE_DEPTH="${SENDER_QUEUE_DEPTH:-8}"
CAPTURE_DISPLAY_INDEX="${CAPTURE_DISPLAY_INDEX:-0}"
CAPTURE_QUEUE_DEPTH="${CAPTURE_QUEUE_DEPTH:-4}"
RUN_ROOT="${RUN_ROOT:-benchmarks/runs/$(date +%Y-%m-%d_%H%M)_mba_to_2015_imac_live_capture}"

mkdir -p "$RUN_ROOT"
swift build --package-path apps/primary-macos -c release

apps/primary-macos/.build/release/ibridge-primary \
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

ssh -i "$RECEIVER_KEY" "$RECEIVER_SSH" "cat ~/ibridge-remote/receiver-macos-${RECEIVER_PORT}.log" > "$RUN_ROOT/receiver_console.txt" || true
echo "Wrote $RUN_ROOT"
