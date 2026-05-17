#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-logs/power}"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
RUN_DIR="$OUT_DIR/$STAMP"

mkdir -p "$RUN_DIR"

pmset -g batt > "$RUN_DIR/pmset_batt.txt"
system_profiler SPPowerDataType > "$RUN_DIR/system_profiler_power.txt"
ioreg -rn AppleSmartBattery > "$RUN_DIR/ioreg_apple_smart_battery.txt"

echo "power_probe_dir=$RUN_DIR"
