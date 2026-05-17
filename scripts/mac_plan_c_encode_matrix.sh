#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-5}"
FPS="${FPS:-60}"
RUN_ROOT="${RUN_ROOT:-}"
LIMIT_CASES="${LIMIT_CASES:-0}"

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_encoder_lowlatency_matrix"
fi
mkdir -p "$RUN_ROOT"

PRIMARY="apps/primary-macos/.build/release/ibridge-primary"

swift build --package-path apps/primary-macos -c release
"$PRIMARY" --list-encoders > "$RUN_ROOT/video_encoders.txt"

cat > "$RUN_ROOT/summary.csv" <<'CSV'
codec,resolution,bitrate_mbps,max_keyframe_interval,max_keyframe_interval_duration,frames_requested,frames_encoded,failed_frames,avg_encode_latency_ms,p95_encode_latency_ms,max_encode_latency_ms,payload_bytes,csv,log
CSV

case_count=0

bitrates_for_resolution() {
  case "$1" in
    2560x1440) echo "20 40 60" ;;
    3200x1800) echo "40 60 80 120" ;;
    3840x2160|4096x2304) echo "60 80 120" ;;
    *) echo "60" ;;
  esac
}

extract_metric() {
  local key="$1"
  local log="$2"
  awk -F= -v key="$key" '$1 == key { value=$2 } END { print value }' "$log"
}

run_case() {
  local codec="$1"
  local resolution="$2"
  local bitrate="$3"
  local kfi="$4"
  local kfd="$5"

  case_count=$((case_count + 1))
  if [[ "$LIMIT_CASES" -gt 0 && "$case_count" -gt "$LIMIT_CASES" ]]; then
    return
  fi

  local safe_name="${codec}_${resolution}_${bitrate}mbps_kfi${kfi}_kfd${kfd}"
  safe_name="${safe_name//./_}"
  local csv="$RUN_ROOT/${safe_name}.csv"
  local log="$RUN_ROOT/${safe_name}.txt"

  "$PRIMARY" \
    --synthetic \
    --resolution "$resolution" \
    --fps "$FPS" \
    --duration "$DURATION" \
    --codec "$codec" \
    --bitrate-mbps "$bitrate" \
    --max-keyframe-interval "$kfi" \
    --max-keyframe-interval-duration "$kfd" \
    --csv "$csv" \
    --print-supported-properties \
    | tee "$log"

  local frames_requested frames_encoded failed avg p95 max payload
  frames_requested="$(extract_metric frames_requested "$log")"
  frames_encoded="$(extract_metric frames_encoded "$log")"
  failed="$(extract_metric failed_frames "$log")"
  avg="$(extract_metric avg_encode_latency_ms "$log")"
  p95="$(extract_metric p95_encode_latency_ms "$log")"
  max="$(extract_metric max_encode_latency_ms "$log")"
  payload="$(extract_metric payload_bytes "$log")"

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$codec" "$resolution" "$bitrate" "$kfi" "$kfd" \
    "$frames_requested" "$frames_encoded" "$failed" "$avg" "$p95" "$max" \
    "$payload" "$csv" "$log" >> "$RUN_ROOT/summary.csv"
}

for resolution in 2560x1440 3200x1800 3840x2160 4096x2304; do
  for bitrate in $(bitrates_for_resolution "$resolution"); do
    for kfi in 60 120; do
      for kfd in 1 2; do
        run_case hevc "$resolution" "$bitrate" "$kfi" "$kfd"
      done
    done
  done
done

for resolution in 2560x1440 3840x2160 4096x2304; do
  for bitrate in $(bitrates_for_resolution "$resolution"); do
    for kfi in 60 120; do
      for kfd in 1 2; do
        run_case h264 "$resolution" "$bitrate" "$kfi" "$kfd"
      done
    done
  done
done

cat > "$RUN_ROOT/summary.md" <<EOF
# Plan C Encoder Low-Latency Matrix

- Duration per case: \`$DURATION\` seconds
- FPS target: \`$FPS\`
- Output CSV: \`summary.csv\`
- Encoder list: \`video_encoders.txt\`

## Reading Rules

- HEVC is the primary Plan C codec path.
- H.264 results are kept only for modes that produce payloads.
- Treat 5120x2880 H.264 as out of scope for this matrix because prior 5K H.264 produced status -10279 for every frame.
- Use average, p95, max encode latency, failed frames, and achieved payload bytes together; a low average with high p95 still needs follow-up.
EOF

echo "Wrote $RUN_ROOT"
