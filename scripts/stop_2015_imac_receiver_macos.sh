#!/usr/bin/env bash
set -euo pipefail

RECEIVER_SSH="${RECEIVER_SSH:-oosu@100.84.32.31}"
RECEIVER_KEY="${RECEIVER_KEY:-$HOME/.ssh/ibridge_imac_ed25519}"

ssh -i "$RECEIVER_KEY" "$RECEIVER_SSH" "
  pkill -f ibridge-receiver-macos 2>/dev/null || true
  pgrep -fl ibridge-receiver-macos || true
"
