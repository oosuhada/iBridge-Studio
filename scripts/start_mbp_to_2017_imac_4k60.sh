#!/usr/bin/env bash
set -euo pipefail

RECEIVER_IP="${RECEIVER_IP:-169.254.70.114}"
DURATION="${DURATION:-3600}"
PROFILE="${PROFILE:-lan-4k}"
RUN_ROOT="${RUN_ROOT:-benchmarks/runs/$(date +%Y-%m-%d_%H%M)_mbp_to_2017_imac_4k60}"

scripts/start_2017_imac_receiver_macos.sh

PROFILE="$PROFILE" \
RECEIVER_IP="$RECEIVER_IP" \
DURATION="$DURATION" \
RUN_ROOT="$RUN_ROOT" \
scripts/start_ibridge_virtual_capture.sh
