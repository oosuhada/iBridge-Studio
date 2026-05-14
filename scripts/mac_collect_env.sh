#!/usr/bin/env bash
set -euo pipefail
OUT_DIR=${1:-logs/env}
mkdir -p "$OUT_DIR"
{
  echo "# macOS Environment"
  date
  sw_vers || true
  system_profiler SPHardwareDataType || true
  system_profiler SPPowerDataType || true
  pmset -g batt || true
  ifconfig || true
  networksetup -listallhardwareports || true
} > "$OUT_DIR/macos_env.txt"
echo "Wrote $OUT_DIR/macos_env.txt"
