#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-3}"
RUN_ROOT="${RUN_ROOT:-}"
AVE_HEVC_ID="${AVE_HEVC_ID:-com.apple.videotoolbox.videoencoder.ave.hevc}"
BITRATE_MBPS="${BITRATE_MBPS:-120}"
INCLUDE_SCREEN_CAPTURE="${INCLUDE_SCREEN_CAPTURE:-1}"

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_encode_strategy_matrix"
fi
mkdir -p "$RUN_ROOT"

PRIMARY="apps/primary-macos/.build/release/ibridge-primary"

swift build --package-path apps/primary-macos -c release
"$PRIMARY" --list-encoders > "$RUN_ROOT/video_encoders.txt"

cat > "$RUN_ROOT/summary.csv" <<'CSV'
profile,source,resolution,fps,duration_seconds,bitrate_mbps,encoder_id,frames_requested,frames_submitted,frames_skipped,frames_encoded,failed_frames,avg_generate_ms,avg_encode_latency_ms,p95_encode_latency_ms,max_encode_latency_ms,payload_bytes,csv,log,status
CSV

extract_metric() {
  local key="$1"
  local log="$2"
  awk -F= -v key="$key" '$1 == key { value=$2 } END { print value }' "$log"
}

csv_append() {
  local profile="$1"
  local source="$2"
  local resolution="$3"
  local fps="$4"
  local csv="$5"
  local log="$6"
  local status="$7"

  local frames_requested frames_submitted frames_skipped frames_encoded failed generate avg p95 max payload encoder_id
  encoder_id="$(extract_metric encoder_id "$log")"
  frames_requested="$(extract_metric frames_requested "$log")"
  frames_submitted="$(extract_metric frames_submitted "$log")"
  frames_skipped="$(extract_metric frames_skipped "$log")"
  frames_encoded="$(extract_metric frames_encoded "$log")"
  failed="$(extract_metric failed_frames "$log")"
  generate="$(extract_metric avg_generate_ms "$log")"
  avg="$(extract_metric avg_encode_latency_ms "$log")"
  p95="$(extract_metric p95_encode_latency_ms "$log")"
  max="$(extract_metric max_encode_latency_ms "$log")"
  payload="$(extract_metric payload_bytes "$log")"

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$profile" "$source" "$resolution" "$fps" "$DURATION" "$BITRATE_MBPS" \
    "${encoder_id:-$AVE_HEVC_ID}" "${frames_requested:-0}" "${frames_submitted:-0}" \
    "${frames_skipped:-0}" "${frames_encoded:-0}" "${failed:-1}" "${generate:-0}" \
    "${avg:-0}" "${p95:-0}" "${max:-0}" "${payload:-0}" "$csv" "$log" "$status" \
    >> "$RUN_ROOT/summary.csv"
}

run_case() {
  local profile="$1"
  local source="$2"
  local resolution="$3"
  local fps="$4"
  shift 4
  local extra_args=("$@")

  local safe_name="${profile}_${source}_${resolution}_${fps}fps"
  safe_name="${safe_name//[^A-Za-z0-9_]/_}"
  local csv="$RUN_ROOT/${safe_name}.csv"
  local log="$RUN_ROOT/${safe_name}.txt"
  local mode_arg="--synthetic"
  if [[ "$source" == "screen-capture" ]]; then
    mode_arg="--screen-capture"
  fi

  local command=(
    "$PRIMARY"
    "$mode_arg"
    --source "$source"
    --resolution "$resolution"
    --fps "$fps"
    --duration "$DURATION"
    --codec hevc
    --bitrate-mbps "$BITRATE_MBPS"
    --encoder-id "$AVE_HEVC_ID"
    --disable-low-latency-rate-control
    --allow-temporal-compression
    --disable-frame-reordering
    --disable-open-gop
    --data-rate-limit-mbps "$BITRATE_MBPS"
    --data-rate-window 1.0
    --prioritize-speed
    --csv "$csv"
  )
  if [[ "${#extra_args[@]}" -gt 0 ]]; then
    command+=("${extra_args[@]}")
  fi

  set +e
  "${command[@]}" > "$log" 2>&1
  local exit_code=$?
  set -e

  if [[ "$exit_code" -ne 0 ]]; then
    {
      echo "profile=$profile"
      echo "source=$source"
      echo "resolution=$resolution"
      echo "target_fps=$fps"
      echo "encoder_id=$AVE_HEVC_ID"
      echo "frames_requested=0"
      echo "frames_submitted=0"
      echo "frames_skipped=0"
      echo "frames_encoded=0"
      echo "failed_frames=1"
      echo "avg_generate_ms=0"
      echo "avg_encode_latency_ms=0"
      echo "p95_encode_latency_ms=0"
      echo "max_encode_latency_ms=0"
      echo "payload_bytes=0"
      echo "exit_code=$exit_code"
    } >> "$log"
  fi

  csv_append "$profile" "$source" "$resolution" "$fps" "$csv" "$log" "$exit_code"
}

run_tile_2x2_case() {
  local profile="tile_2x2_5k60"
  local source="synthetic-nv12"
  local resolution="2560x1440"
  local fps="60"
  local dir="$RUN_ROOT/${profile}"
  mkdir -p "$dir"

  local pids=()
  for tile in 0 1 2 3; do
    local csv="$dir/tile_${tile}.csv"
    local log="$dir/tile_${tile}.txt"
    (
      "$PRIMARY" \
        --synthetic \
        --source "$source" \
        --resolution "$resolution" \
        --fps "$fps" \
        --duration "$DURATION" \
        --codec hevc \
        --bitrate-mbps "$BITRATE_MBPS" \
        --encoder-id "$AVE_HEVC_ID" \
        --disable-low-latency-rate-control \
        --allow-temporal-compression \
        --disable-frame-reordering \
        --disable-open-gop \
        --data-rate-limit-mbps "$BITRATE_MBPS" \
        --data-rate-window 1.0 \
        --prioritize-speed \
        --csv "$csv" \
        > "$log" 2>&1
    ) &
    pids+=("$!")
  done

  local status=0
  for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
      status=1
    fi
  done

  {
    echo "# Tile 2x2 5K60 approximation"
    echo
    echo "- Source per tile: $source"
    echo "- Tile resolution: $resolution"
    echo "- Tiles: 4"
    echo "- Combined logical surface: 5120x2880"
    echo "- Exit status: $status"
    echo
    echo "| Tile | Frames | Avg encode ms | P95 encode ms | Max encode ms | Log |"
    echo "| --- | ---: | ---: | ---: | ---: | --- |"
    for tile in 0 1 2 3; do
      local log="$dir/tile_${tile}.txt"
      local frames avg p95 max
      frames="$(extract_metric frames_encoded "$log")"
      avg="$(extract_metric avg_encode_latency_ms "$log")"
      p95="$(extract_metric p95_encode_latency_ms "$log")"
      max="$(extract_metric max_encode_latency_ms "$log")"
      echo "| $tile | ${frames:-0} | ${avg:-0} | ${p95:-0} | ${max:-0} | tile_${tile}.txt |"
    done
  } > "$dir/summary.md"
}

for resolution in 3200x1800 3840x2160 4096x2304 5120x2880; do
  run_case "bgra_baseline" "synthetic-bgra" "$resolution" 60
  run_case "nv12_input" "synthetic-nv12" "$resolution" 60
done

run_case "static_skip_every_2" "synthetic-static-skip" "5120x2880" 60 --static-change-every 2
run_case "static_skip_every_10" "synthetic-static-skip" "5120x2880" 60 --static-change-every 10
run_case "static_skip_every_60" "synthetic-static-skip" "5120x2880" 60 --static-change-every 60

run_case "nv12_5k45" "synthetic-nv12" "5120x2880" 45
run_case "nv12_5k30" "synthetic-nv12" "5120x2880" 30

run_tile_2x2_case

if [[ "$INCLUDE_SCREEN_CAPTURE" == "1" ]]; then
  run_case "sck_4k60" "screen-capture" "3840x2160" 60 --capture-display-index 0 --capture-queue-depth 8
  run_case "sck_5k60" "screen-capture" "5120x2880" 60 --capture-display-index 0 --capture-queue-depth 8
  run_case "sck_5k30" "screen-capture" "5120x2880" 30 --capture-display-index 0 --capture-queue-depth 8
fi

cat > "$RUN_ROOT/summary.md" <<EOF
# Encode Strategy Matrix

- Duration per case: \`$DURATION\` seconds
- Forced encoder: \`$AVE_HEVC_ID\`
- Codec: HEVC
- Bitrate/DataRateLimits: \`$BITRATE_MBPS Mbps\`
- Main table: \`summary.csv\`
- Encoder list: \`video_encoders.txt\`
- Tile approximation: \`tile_2x2_5k60/summary.md\`

## What This Tests

- BGRA synthetic input versus NV12 synthetic input.
- Static-screen frame skipping with 5K logical output.
- 5K45 and 5K30 refresh-rate fallback.
- 2x2 parallel encoder sessions approximating tiled 5K.
- ScreenCaptureKit/IOSurface capture path when Screen Recording permission allows it.
EOF

echo "Wrote $RUN_ROOT"
