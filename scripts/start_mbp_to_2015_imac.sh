#!/usr/bin/env bash
set -euo pipefail

RECEIVER_IP="${RECEIVER_IP:-}"
RECEIVER_KEY="${RECEIVER_KEY:-$HOME/.ssh/id_ed25519}"
CAPTURE_DISPLAY_NAME="${CAPTURE_DISPLAY_NAME:-iMac 27inch 2015}"
PROFILE="${PROFILE:-lan-60hz}"
RESOLUTION="${RESOLUTION:-2560x1440}"
BITRATE_MBPS="${BITRATE_MBPS:-80}"
DURATION="${DURATION:-600}"
RUN_ROOT="${RUN_ROOT:-benchmarks/runs/$(date +%Y-%m-%d_%H%M)_mbp_to_2015_imac}"

if [[ -z "$RECEIVER_IP" ]]; then
  echo "Set RECEIVER_IP before running this helper." >&2
  exit 64
fi

RECEIVER_KEY="$RECEIVER_KEY" scripts/start_2015_imac_receiver_macos.sh

RECEIVER_IP="$RECEIVER_IP" \
CAPTURE_DISPLAY_NAME="$CAPTURE_DISPLAY_NAME" \
PROFILE="$PROFILE" \
RESOLUTION="$RESOLUTION" \
BITRATE_MBPS="$BITRATE_MBPS" \
DURATION="$DURATION" \
RUN_ROOT="$RUN_ROOT" \
scripts/start_ibridge_virtual_capture.sh
