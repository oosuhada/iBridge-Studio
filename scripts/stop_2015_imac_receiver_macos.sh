#!/usr/bin/env bash
set -euo pipefail

RECEIVER_SSH="${RECEIVER_SSH:-}"
RECEIVER_KEY="${RECEIVER_KEY:-$HOME/.ssh/ibridge_imac_ed25519}"

if [[ -z "$RECEIVER_SSH" ]]; then
  echo "Set RECEIVER_SSH=user@host before running this helper." >&2
  exit 64
fi

ssh -i "$RECEIVER_KEY" "$RECEIVER_SSH" "
  pkill -f ibridge-receiver-macos 2>/dev/null || true
  pgrep -fl ibridge-receiver-macos || true
"
