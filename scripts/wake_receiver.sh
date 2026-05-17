#!/usr/bin/env bash
set -euo pipefail

WAKE_MAC="${WAKE_MAC:-}"
WAKE_BROADCAST="${WAKE_BROADCAST:-255.255.255.255}"
WAKE_PORT="${WAKE_PORT:-9}"
WAKE_WAIT_HOST="${WAKE_WAIT_HOST:-}"
WAKE_WAIT_PORT="${WAKE_WAIT_PORT:-48320}"
WAKE_WAIT_TIMEOUT="${WAKE_WAIT_TIMEOUT:-0}"
WAKE_REPEAT="${WAKE_REPEAT:-3}"

if [[ -z "$WAKE_MAC" ]]; then
  echo "No Wake MAC configured." >&2
  exit 2
fi

WAKE_MAC="$WAKE_MAC" WAKE_BROADCAST="$WAKE_BROADCAST" WAKE_PORT="$WAKE_PORT" WAKE_REPEAT="$WAKE_REPEAT" python3 - <<'PY'
import os
import re
import socket
import sys
import time

mac = os.environ["WAKE_MAC"].strip()
raw_targets = os.environ.get("WAKE_BROADCAST", "255.255.255.255").strip()
if raw_targets.lower() == "auto":
    raw_targets = "255.255.255.255"
targets = re.split(r"[\s,]+", raw_targets)
port = int(os.environ.get("WAKE_PORT", "9"))
repeat = max(1, int(os.environ.get("WAKE_REPEAT", "3")))

hex_mac = re.sub(r"[^0-9A-Fa-f]", "", mac)
if len(hex_mac) != 12:
    print(f"Invalid Wake MAC: {mac}", file=sys.stderr)
    sys.exit(2)

packet = bytes.fromhex("FF" * 6 + hex_mac * 16)
sent = 0
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    for attempt in range(repeat):
        for target in [item for item in targets if item]:
            sock.sendto(packet, (target, port))
            print(f"sent magic packet {attempt + 1}/{repeat} to {mac} via {target}:{port}")
            sent += 1
        if attempt + 1 < repeat:
            time.sleep(0.25)

if sent == 0:
    print("No Wake broadcast targets configured.", file=sys.stderr)
    sys.exit(2)
PY

if [[ -n "$WAKE_WAIT_HOST" && "$WAKE_WAIT_TIMEOUT" != "0" ]]; then
  echo "waiting for $WAKE_WAIT_HOST:$WAKE_WAIT_PORT for up to ${WAKE_WAIT_TIMEOUT}s"
  deadline=$((SECONDS + WAKE_WAIT_TIMEOUT))
  while (( SECONDS < deadline )); do
    if nc -G 1 -z "$WAKE_WAIT_HOST" "$WAKE_WAIT_PORT" >/dev/null 2>&1; then
      echo "$WAKE_WAIT_HOST:$WAKE_WAIT_PORT is reachable"
      exit 0
    fi
    sleep 1
  done
  echo "receiver port did not become reachable before timeout" >&2
  exit 1
fi
