#!/usr/bin/env bash
set -euo pipefail

RECEIVER_SSH="${RECEIVER_SSH:-}"
RECEIVER_KEY="${RECEIVER_KEY:-$HOME/.ssh/ibridge_imac_ed25519}"
REMOTE_REPO="${REMOTE_REPO:-}"
PORT="${PORT:-48320}"
TITLE="${TITLE:-iBridge Studio 2015 Receiver}"
FULLSCREEN="${FULLSCREEN:-1}"
SHOW_STATUS="${SHOW_STATUS:-0}"

if [[ -z "$RECEIVER_SSH" ]]; then
  echo "Set RECEIVER_SSH=user@host before running this helper." >&2
  exit 64
fi

if [[ -z "$REMOTE_REPO" ]]; then
  echo "Set REMOTE_REPO to the iBridge-Studio checkout path on the receiver Mac." >&2
  exit 64
fi

fullscreen_arg=()
if [[ "$FULLSCREEN" == "1" || "$FULLSCREEN" == "true" ]]; then
  fullscreen_arg=(--fullscreen)
fi

status_arg=()
if [[ "$SHOW_STATUS" == "0" || "$SHOW_STATUS" == "false" ]]; then
  status_arg=(--hide-status)
fi

ssh -i "$RECEIVER_KEY" "$RECEIVER_SSH" "
  set -e
  mkdir -p ~/ibridge-remote
  cd '$REMOTE_REPO'
  git fetch origin
  git checkout deploy
  git pull --ff-only
  swift build --package-path apps/receiver-macos -c release
  pkill -f ibridge-receiver-macos 2>/dev/null || true
  pgrep -fl 'caffeinate -dimsu' >/dev/null || nohup caffeinate -dimsu > ~/ibridge-remote/caffeinate.log 2>&1 &
  pgrep -fl 'iperf3 -s' >/dev/null || nohup /usr/local/bin/iperf3 -s > ~/ibridge-remote/iperf3-server.log 2>&1 &
  : > ~/ibridge-remote/receiver-macos-${PORT}.log
  nohup apps/receiver-macos/.build/release/ibridge-receiver-macos --port '$PORT' ${fullscreen_arg[*]} ${status_arg[*]} --title '$TITLE' > ~/ibridge-remote/receiver-macos-${PORT}.log 2>&1 &
  echo \$! > ~/ibridge-remote/receiver-macos-${PORT}.pid
  sleep 3
  pgrep -fl ibridge-receiver-macos || true
  lsof -nP -iTCP:'$PORT' -sTCP:LISTEN || true
  tail -20 ~/ibridge-remote/receiver-macos-${PORT}.log || true
"
