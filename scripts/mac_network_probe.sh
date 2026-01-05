#!/usr/bin/env bash
set -euo pipefail
HOST=${1:-}
if [[ -z "$HOST" ]]; then
  echo "Usage: $0 <receiver-ip>"
  exit 1
fi
ping -c 20 "$HOST" | tee logs/ping_${HOST}.txt
if command -v iperf3 >/dev/null 2>&1; then
  iperf3 -c "$HOST" -t 30 | tee logs/iperf3_${HOST}.txt
else
  echo "iperf3 not installed"
fi
