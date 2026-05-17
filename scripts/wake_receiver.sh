#!/usr/bin/env bash
set -euo pipefail

WAKE_MAC="${WAKE_MAC:-}"
WAKE_BROADCAST="${WAKE_BROADCAST:-255.255.255.255}"
WAKE_PORT="${WAKE_PORT:-9}"

if [[ -z "$WAKE_MAC" ]]; then
  echo "No Wake MAC configured." >&2
  exit 2
fi

WAKE_MAC="$WAKE_MAC" WAKE_BROADCAST="$WAKE_BROADCAST" WAKE_PORT="$WAKE_PORT" python3 - <<'PY'
import os
import re
import socket
import sys

mac = os.environ["WAKE_MAC"].strip()
targets = re.split(r"[\s,]+", os.environ.get("WAKE_BROADCAST", "255.255.255.255").strip())
port = int(os.environ.get("WAKE_PORT", "9"))

hex_mac = re.sub(r"[^0-9A-Fa-f]", "", mac)
if len(hex_mac) != 12:
    print(f"Invalid Wake MAC: {mac}", file=sys.stderr)
    sys.exit(2)

packet = bytes.fromhex("FF" * 6 + hex_mac * 16)
sent = 0
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    for target in [item for item in targets if item]:
        sock.sendto(packet, (target, port))
        print(f"sent magic packet to {mac} via {target}:{port}")
        sent += 1

if sent == 0:
    print("No Wake broadcast targets configured.", file=sys.stderr)
    sys.exit(2)
PY
