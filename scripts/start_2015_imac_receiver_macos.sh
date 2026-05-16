#!/usr/bin/env bash
set -euo pipefail

RECEIVER_SSH="${RECEIVER_SSH:-oosu@100.84.32.31}"
RECEIVER_KEY="${RECEIVER_KEY:-$HOME/.ssh/ibridge_imac_ed25519}"
REMOTE_REPO="${REMOTE_REPO:-/Users/oosu/development/iBridge}"
PORT="${PORT:-48320}"
TITLE="${TITLE:-iBridge 2015 Receiver}"
FULLSCREEN="${FULLSCREEN:-1}"

fullscreen_arg=()
if [[ "$FULLSCREEN" == "1" || "$FULLSCREEN" == "true" ]]; then
  fullscreen_arg=(--fullscreen)
fi

ssh -i "$RECEIVER_KEY" "$RECEIVER_SSH" "
  set -e
  mkdir -p ~/ibridge-remote
  cd '$REMOTE_REPO'
  git fetch origin
  git checkout feat/plan-a-5k60-benchmark
  git pull --ff-only
  swift build --package-path apps/receiver-macos -c release
  pkill -f ibridge-receiver-macos 2>/dev/null || true
  pgrep -fl 'caffeinate -dimsu' >/dev/null || nohup caffeinate -dimsu > ~/ibridge-remote/caffeinate.log 2>&1 &
  pgrep -fl 'iperf3 -s' >/dev/null || nohup /usr/local/bin/iperf3 -s > ~/ibridge-remote/iperf3-server.log 2>&1 &
  : > ~/ibridge-remote/receiver-macos-${PORT}.log
  nohup apps/receiver-macos/.build/release/ibridge-receiver-macos --port '$PORT' ${fullscreen_arg[*]} --title '$TITLE' > ~/ibridge-remote/receiver-macos-${PORT}.log 2>&1 &
  echo \$! > ~/ibridge-remote/receiver-macos-${PORT}.pid
  sleep 3
  pgrep -fl ibridge-receiver-macos || true
  lsof -nP -iTCP:'$PORT' -sTCP:LISTEN || true
  tail -20 ~/ibridge-remote/receiver-macos-${PORT}.log || true
"
