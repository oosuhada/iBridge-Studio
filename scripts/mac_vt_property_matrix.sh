#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-2}"
FPS="${FPS:-60}"
RUN_ROOT="${RUN_ROOT:-}"
LIMIT_CASES="${LIMIT_CASES:-0}"

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_vt_property_matrix"
fi
mkdir -p "$RUN_ROOT"

PRIMARY="apps/primary-macos/.build/release/ibridge-primary"
AVE_HEVC_ID="${AVE_HEVC_ID:-com.apple.videotoolbox.videoencoder.ave.hevc}"

swift build --package-path apps/primary-macos -c release
"$PRIMARY" --list-encoders > "$RUN_ROOT/video_encoders.txt"

cat > "$RUN_ROOT/summary.csv" <<'CSV'
profile,codec,resolution,bitrate_mbps,encoder_id,low_latency_rate_control,realtime,allow_temporal_compression,allow_frame_reordering,allow_open_gop,prioritize_speed,max_frame_delay_count,data_rate_limit_mbps,payload_format,frames_requested,frames_encoded,failed_frames,avg_encode_latency_ms,p95_encode_latency_ms,max_encode_latency_ms,payload_bytes,csv,log
CSV

case_count=0

extract_metric() {
  local key="$1"
  local log="$2"
  awk -F= -v key="$key" '$1 == key { value=$2 } END { print value }' "$log"
}

run_case() {
  local profile="$1"
  local resolution="$2"
  local bitrate="$3"
  shift 3
  local args=("$@")

  case_count=$((case_count + 1))
  if [[ "$LIMIT_CASES" -gt 0 && "$case_count" -gt "$LIMIT_CASES" ]]; then
    return
  fi

  local safe_name="${profile}_${resolution}_${bitrate}mbps"
  safe_name="${safe_name//[^A-Za-z0-9_]/_}"
  local csv="$RUN_ROOT/${safe_name}.csv"
  local log="$RUN_ROOT/${safe_name}.txt"

  set +e
  local command=(
    "$PRIMARY"
    --synthetic
    --resolution "$resolution"
    --fps "$FPS"
    --duration "$DURATION"
    --codec hevc
    --bitrate-mbps "$bitrate"
    --csv "$csv"
  )
  if [[ "${#args[@]}" -gt 0 ]]; then
    command+=("${args[@]}")
  fi
  "${command[@]}" > "$log" 2>&1
  local status=$?
  set -e

  if [[ "$status" -ne 0 ]]; then
    {
      echo "profile=$profile"
      echo "resolution=$resolution"
      echo "bitrate_mbps=$bitrate"
      echo "frames_requested=0"
      echo "frames_encoded=0"
      echo "failed_frames=1"
      echo "avg_encode_latency_ms=0"
      echo "p95_encode_latency_ms=0"
      echo "max_encode_latency_ms=0"
      echo "payload_bytes=0"
    } >> "$log"
  fi

  local encoder_id llrc realtime temporal reorder opengop speed delay data_limit payload_format
  local frames_requested frames_encoded failed avg p95 max payload
  encoder_id="$(extract_metric encoder_id "$log")"
  llrc="$(extract_metric low_latency_rate_control "$log")"
  realtime="$(extract_metric realtime "$log")"
  temporal="$(extract_metric allow_temporal_compression "$log")"
  reorder="$(extract_metric allow_frame_reordering "$log")"
  opengop="$(extract_metric allow_open_gop "$log")"
  speed="$(extract_metric prioritize_speed "$log")"
  delay="$(extract_metric max_frame_delay_count "$log")"
  data_limit="$(extract_metric data_rate_limit_mbps "$log")"
  payload_format="$(extract_metric payload_format "$log")"
  frames_requested="$(extract_metric frames_requested "$log")"
  frames_encoded="$(extract_metric frames_encoded "$log")"
  failed="$(extract_metric failed_frames "$log")"
  avg="$(extract_metric avg_encode_latency_ms "$log")"
  p95="$(extract_metric p95_encode_latency_ms "$log")"
  max="$(extract_metric max_encode_latency_ms "$log")"
  payload="$(extract_metric payload_bytes "$log")"

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$profile" "hevc" "$resolution" "$bitrate" "$encoder_id" "$llrc" "$realtime" \
    "$temporal" "$reorder" "$opengop" "$speed" "$delay" "$data_limit" "$payload_format" \
    "$frames_requested" "$frames_encoded" "$failed" "$avg" "$p95" "$max" "$payload" \
    "$csv" "$log" >> "$RUN_ROOT/summary.csv"
}

for resolution in 3200x1800 3840x2160 5120x2880; do
  bitrate=120
  run_case "auto_llrc_temporal_on" "$resolution" "$bitrate"
  run_case "ave_no_llrc_reference" "$resolution" "$bitrate" \
    --encoder-id "$AVE_HEVC_ID" \
    --disable-low-latency-rate-control \
    --allow-temporal-compression \
    --disable-frame-reordering \
    --disable-open-gop \
    --max-frame-delay-count 0
  run_case "ave_no_llrc_speed" "$resolution" "$bitrate" \
    --encoder-id "$AVE_HEVC_ID" \
    --disable-low-latency-rate-control \
    --allow-temporal-compression \
    --disable-frame-reordering \
    --disable-open-gop \
    --max-frame-delay-count 0 \
    --prioritize-speed
  run_case "ave_no_llrc_datarate" "$resolution" "$bitrate" \
    --encoder-id "$AVE_HEVC_ID" \
    --disable-low-latency-rate-control \
    --allow-temporal-compression \
    --disable-frame-reordering \
    --disable-open-gop \
    --max-frame-delay-count 0 \
    --data-rate-limit-mbps "$bitrate" \
    --data-rate-window 1.0
  run_case "ave_no_llrc_annexb" "$resolution" "$bitrate" \
    --encoder-id "$AVE_HEVC_ID" \
    --disable-low-latency-rate-control \
    --allow-temporal-compression \
    --disable-frame-reordering \
    --disable-open-gop \
    --max-frame-delay-count 0 \
    --payload-format annex-b
done

cat > "$RUN_ROOT/summary.md" <<EOF
# VideoToolbox Property Matrix

- Duration per case: \`$DURATION\` seconds
- FPS target: \`$FPS\`
- Codec: HEVC
- Forced encoder profile uses: \`$AVE_HEVC_ID\`
- Output CSV: \`summary.csv\`
- Encoder list: \`video_encoders.txt\`

## Purpose

This matrix tests encoder properties before any iMac receiver dependency:

- automatic low-latency rate control versus forced \`ave.hevc\`
- temporal compression on with frame reordering off
- closed GOP
- max frame delay count
- speed-priority hint
- DataRateLimits
- Annex-B payload extraction cost

Use this to decide whether Plan A/B encode itself is viable before continuing
receiver or transport work.
EOF

echo "Wrote $RUN_ROOT"
