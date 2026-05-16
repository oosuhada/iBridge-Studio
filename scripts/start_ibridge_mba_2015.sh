#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/start_2015_imac_receiver_macos.sh"
"$SCRIPT_DIR/start_mba_to_2015_imac_live_capture.sh"
