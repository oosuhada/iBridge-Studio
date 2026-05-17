#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-10}"
RUN_FALLBACK="${RUN_FALLBACK:-1}"
RUN_ROOT="${RUN_ROOT:-}"
AVE_HEVC_ID="${AVE_HEVC_ID:-com.apple.videotoolbox.videoencoder.ave.hevc}"
RESET_EVERY="${RESET_EVERY:-180}"
STAGGER_FRAMES="${STAGGER_FRAMES:-30}"

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_encoder_reset_strategy_probe"
fi
mkdir -p "$RUN_ROOT"

PRIMARY="apps/primary-macos/.build/release/ibridge-primary"

usage() {
  cat <<'USAGE'
Usage:
  DURATION=10 RUN_FALLBACK=1 scripts/mac_encoder_reset_strategy_probe.sh

Environment:
  DURATION=10
  RUN_FALLBACK=0|1
  RESET_EVERY=180
  STAGGER_FRAMES=30
  RUN_ROOT=benchmarks/runs/custom_name

Compares tiled 5K60 encoder reset/session strategies:
  1. baseline simultaneous tile reset
  2. VideoToolbox segment hints on simultaneous tile reset
  3. segment hints plus staggered per-tile reset
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

swift build --package-path apps/primary-macos -c release

{
  echo "timestamp=$STAMP"
  echo "duration_seconds=$DURATION"
  echo "reset_every=$RESET_EVERY"
  echo "stagger_frames=$STAGGER_FRAMES"
  echo "run_fallback=$RUN_FALLBACK"
  echo "hostname=$(hostname)"
  echo "pwd=$(pwd)"
  uname -a
} > "$RUN_ROOT/metadata.txt"

cat > "$RUN_ROOT/summary.csv" <<'CSV'
case,mode,resolution,fps,duration_seconds,bitrate_mbps,status,frames_encoded,effective_logical_fps,avg_encode_ms,p95_encode_ms,max_encode_ms,p95_steady_encode_ms,logical_over_16_67,logical_over_33_33,csv,logical_csv,deadline_md,log
CSV

extract_metric() {
  local key="$1"
  local log="$2"
  awk -F= -v key="$key" '$1 == key { value=$2 } END { print value }' "$log"
}

deadline_count() {
  local budget="$1"
  local md="$2"
  if [[ ! -f "$md" ]]; then
    echo ""
    return
  fi
  awk -F'|' -v budget="$budget" '
    $2 ~ budget {
      gsub(/^[ \t]+|[ \t]+$/, "", $3)
      print $3
    }
  ' "$md"
}

append_summary() {
  local case_name="$1"
  local mode="$2"
  local resolution="$3"
  local fps="$4"
  local bitrate="$5"
  local status="$6"
  local csv="$7"
  local log="$8"
  local logical_csv="$9"
  local deadline_md="${10}"

  local frames_encoded effective avg p95 max p95_steady over_16 over_33
  frames_encoded="$(extract_metric frames_encoded "$log")"
  effective="$(extract_metric effective_logical_fps "$log")"
  avg="$(extract_metric avg_encode_latency_ms "$log")"
  p95="$(extract_metric p95_encode_latency_ms "$log")"
  max="$(extract_metric max_encode_latency_ms "$log")"
  p95_steady="$(extract_metric p95_steady_encode_latency_ms "$log")"
  over_16="$(deadline_count '16.67' "$deadline_md")"
  over_33="$(deadline_count '33.33' "$deadline_md")"

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$case_name" "$mode" "$resolution" "$fps" "$DURATION" "$bitrate" "$status" \
    "${frames_encoded:-0}" "${effective:-}" "${avg:-0}" "${p95:-0}" "${max:-0}" \
    "${p95_steady:-}" "${over_16:-}" "${over_33:-}" "$csv" "$logical_csv" "$deadline_md" "$log" \
    >> "$RUN_ROOT/summary.csv"
}

run_case() {
  local case_name="$1"
  shift
  local extra_args=("$@")
  local safe="${case_name//[^A-Za-z0-9_]/_}"
  local csv="$RUN_ROOT/${safe}.csv"
  local log="$RUN_ROOT/${safe}.txt"
  local logical_csv="${csv%.csv}_logical.csv"
  local deadline_md="${csv%.csv}_deadline.md"

  local command=(
    "$PRIMARY"
    --synthetic
    --source synthetic-nv12-tiled
    --resolution 5120x2880
    --fps 60
    --duration "$DURATION"
    --codec hevc
    --bitrate-mbps 30
    --encoder-id "$AVE_HEVC_ID"
    --disable-low-latency-rate-control
    --allow-temporal-compression
    --disable-frame-reordering
    --disable-open-gop
    --data-rate-limit-mbps 30
    --data-rate-window 1.0
    --prioritize-speed
    --tile-columns 2
    --tile-rows 2
    --tile-reuse-buffers
    --tile-reset-every-frames "$RESET_EVERY"
    --tile-max-inflight-logical-frames 1
    --warmup-frames 30
    --csv "$csv"
  )
  if [[ "${#extra_args[@]}" -gt 0 ]]; then
    command+=("${extra_args[@]}")
  fi

  set +e
  "${command[@]}" > "$log" 2>&1
  local exit_code=$?
  set -e

  if [[ -f "$logical_csv" ]]; then
    python3 scripts/analyze_tiled_deadline.py "$logical_csv" --run-log "$log" --summary-md "$deadline_md" >/dev/null
  else
    deadline_md=""
  fi

  append_summary "$case_name" "tiled" "5120x2880" "60" "30" "$exit_code" "$csv" "$log" "$logical_csv" "$deadline_md"
}

run_fallback_case() {
  local case_name="$1"
  local resolution="$2"
  local bitrate="$3"
  local safe="${case_name//[^A-Za-z0-9_]/_}"
  local csv="$RUN_ROOT/${safe}.csv"
  local log="$RUN_ROOT/${safe}.txt"

  set +e
  "$PRIMARY" \
    --synthetic \
    --source synthetic-nv12 \
    --resolution "$resolution" \
    --fps 60 \
    --duration 5 \
    --codec hevc \
    --bitrate-mbps "$bitrate" \
    --encoder-id "$AVE_HEVC_ID" \
    --disable-low-latency-rate-control \
    --allow-temporal-compression \
    --disable-frame-reordering \
    --disable-open-gop \
    --data-rate-limit-mbps "$bitrate" \
    --data-rate-window 1.0 \
    --prioritize-speed \
    --csv "$csv" > "$log" 2>&1
  local exit_code=$?
  set -e

  append_summary "$case_name" "single" "$resolution" "60" "$bitrate" "$exit_code" "$csv" "$log" "" ""
}

run_case "baseline_simultaneous_reset"
run_case "segment_hints_simultaneous_reset" --tile-segment-hints
run_case "segment_hints_staggered_reset" --tile-segment-hints --tile-reset-stagger-frames "$STAGGER_FRAMES"

if [[ "$RUN_FALLBACK" == "1" ]]; then
  run_fallback_case "post_probe_4096_fallback" "4096x2304" "120"
  run_fallback_case "post_probe_3200_fallback" "3200x1800" "60"
  run_fallback_case "post_probe_2560_fallback" "2560x1440" "25"
fi

cat > "$RUN_ROOT/summary.md" <<EOF
# Encoder Reset Strategy Probe

- Duration: \`$DURATION\` seconds
- Reset interval: \`$RESET_EVERY\` logical frames
- Stagger: \`$STAGGER_FRAMES\` logical frames
- Fallback probes: \`$RUN_FALLBACK\`

See \`summary.csv\` for metrics and per-case logs.
EOF

echo "wrote $RUN_ROOT/summary.csv"
