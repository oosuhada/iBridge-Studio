#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_DIR="${REMOTE_DIR:-~/ibridge-remote/latest}"
PORT="${PORT:-48320}"
TITLE="${TITLE:-iBridge Studio 4K60 Receiver}"
LOCAL_BIN="${LOCAL_BIN:-apps/receiver-macos/.build/x86_64-apple-macosx/release/ibridge-receiver-macos}"

if [[ -z "$REMOTE_HOST" ]]; then
  echo "Set REMOTE_HOST=user@host before running this helper." >&2
  exit 64
fi

if [[ ! -x "$LOCAL_BIN" ]]; then
  swift build --package-path apps/receiver-macos -c release --arch x86_64
fi

ssh "$REMOTE_HOST" "mkdir -p $REMOTE_DIR"
scp "$LOCAL_BIN" "$REMOTE_HOST:$REMOTE_DIR/ibridge-receiver-macos"
ssh "$REMOTE_HOST" "
  chmod +x $REMOTE_DIR/ibridge-receiver-macos
  pkill -f ibridge-receiver-macos || true
  : > ~/ibridge-remote/receiver-macos-${PORT}.log
  nohup $REMOTE_DIR/ibridge-receiver-macos --port '$PORT' --fullscreen --hide-status --title '$TITLE' > ~/ibridge-remote/receiver-macos-${PORT}.log 2>&1 &
  sleep 1
  pgrep -fl ibridge-receiver-macos
  nc -vz 127.0.0.1 '$PORT'
  tail -n 20 ~/ibridge-remote/receiver-macos-${PORT}.log
"
