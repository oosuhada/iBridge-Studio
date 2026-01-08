#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-5}"
PROFILE_SET="${PROFILE_SET:-quick}"
DEVICE_PROFILE="${DEVICE_PROFILE:-auto}"
RUN_ROOT="${RUN_ROOT:-}"
AVE_HEVC_ID="${AVE_HEVC_ID:-com.apple.videotoolbox.videoencoder.ave.hevc}"
INCLUDE_SCREEN_CAPTURE="${INCLUDE_SCREEN_CAPTURE:-0}"

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_transmission_profile_matrix"
fi
mkdir -p "$RUN_ROOT"

PRIMARY="apps/primary-macos/.build/release/ibridge-primary"

usage() {
  cat <<'USAGE'
Usage:
  DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 scripts/mac_transmission_profile_matrix.sh

Environment:
  DEVICE_PROFILE=auto|m1max|m1air
  PROFILE_SET=quick|wired|wireless|air|all
  DURATION=5
  INCLUDE_SCREEN_CAPTURE=0|1
  RUN_ROOT=benchmarks/runs/custom_name

This is an encode-first sender matrix. It does not test receiver decode/render.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

swift build --package-path apps/primary-macos -c release
"$PRIMARY" --list-encoders > "$RUN_ROOT/video_encoders.txt"

{
  echo "timestamp=$STAMP"
  echo "duration_seconds=$DURATION"
  echo "profile_set=$PROFILE_SET"
  echo "device_profile_requested=$DEVICE_PROFILE"
  echo "hostname=$(hostname)"
  echo "pwd=$(pwd)"
  uname -a
} > "$RUN_ROOT/metadata.txt"

system_profiler SPHardwareDataType SPDisplaysDataType \
  | sed '/Serial Number/d;/Hardware UUID/d;/Provisioning UDID/d' \
  > "$RUN_ROOT/system_profile_sanitized.txt" 2>&1 || true

if [[ "$DEVICE_PROFILE" == "auto" ]]; then
  MODEL="$(sysctl -n hw.model 2>/dev/null || true)"
  case "$MODEL" in
    MacBookPro18,*) DEVICE_PROFILE="m1max" ;;
    MacBookAir10,*) DEVICE_PROFILE="m1air" ;;
    *) DEVICE_PROFILE="unknown" ;;
  esac
fi

cat > "$RUN_ROOT/summary.csv" <<'CSV'
profile,connection_class,device_profile,source,resolution,fps,duration_seconds,codec,bitrate_mbps,status,frames_requested,frames_submitted,frames_encoded,failed_frames,effective_logical_fps,avg_encode_ms,p95_encode_ms,max_encode_ms,payload_bytes,csv,logical_csv,log,deadline_md
CSV

extract_metric() {
  local key="$1"
  local log="$2"
  awk -F= -v key="$key" '$1 == key { value=$2 } END { print value }' "$log"
}

append_summary() {
  local profile="$1"
  local connection_class="$2"
  local source="$3"
  local resolution="$4"
  local fps="$5"
  local bitrate="$6"
  local status="$7"
  local csv="$8"
  local log="$9"
  local logical_csv="${10}"
  local deadline_md="${11}"

  local frames_requested frames_submitted frames_encoded failed effective avg p95 max payload
  frames_requested="$(extract_metric frames_requested "$log")"
  frames_submitted="$(extract_metric frames_submitted "$log")"
  frames_encoded="$(extract_metric frames_encoded "$log")"
  failed="$(extract_metric failed_frames "$log")"
  effective="$(extract_metric effective_logical_fps "$log")"
  avg="$(extract_metric avg_encode_latency_ms "$log")"
  p95="$(extract_metric p95_encode_latency_ms "$log")"
  max="$(extract_metric max_encode_latency_ms "$log")"
  payload="$(extract_metric payload_bytes "$log")"

  printf '%s,%s,%s,%s,%s,%s,%s,hevc,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$profile" "$connection_class" "$DEVICE_PROFILE" "$source" "$resolution" "$fps" \
    "$DURATION" "$bitrate" "$status" "${frames_requested:-0}" "${frames_submitted:-0}" \
    "${frames_encoded:-0}" "${failed:-1}" "${effective:-}" "${avg:-0}" "${p95:-0}" \
    "${max:-0}" "${payload:-0}" "$csv" "$logical_csv" "$log" "$deadline_md" \
    >> "$RUN_ROOT/summary.csv"
}

run_encode_case() {
  local profile="$1"
  local connection_class="$2"
  local source="$3"
  local resolution="$4"
  local fps="$5"
  local bitrate="$6"
  shift 6
  local extra_args=("$@")

  local safe_name="${profile}_${source}_${resolution}_${fps}fps_${bitrate}mbps"
  safe_name="${safe_name//[^A-Za-z0-9_]/_}"
  local csv="$RUN_ROOT/${safe_name}.csv"
  local log="$RUN_ROOT/${safe_name}.txt"
  local logical_csv=""
  local deadline_md=""
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
    --bitrate-mbps "$bitrate"
    --encoder-id "$AVE_HEVC_ID"
    --disable-low-latency-rate-control
    --allow-temporal-compression
    --disable-frame-reordering
    --disable-open-gop
    --data-rate-limit-mbps "$bitrate"
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

  if [[ "$source" == "synthetic-nv12-tiled" ]]; then
    logical_csv="${csv%.csv}_logical.csv"
    if [[ -f "$logical_csv" ]]; then
      deadline_md="${csv%.csv}_deadline.md"
      python3 scripts/analyze_tiled_deadline.py "$logical_csv" --run-log "$log" --summary-md "$deadline_md" >/dev/null
    fi
  fi

  append_summary "$profile" "$connection_class" "$source" "$resolution" "$fps" "$bitrate" "$exit_code" "$csv" "$log" "$logical_csv" "$deadline_md"
}

should_run() {
  local profile="$1"
  if [[ "$DEVICE_PROFILE" == "m1max" && ( "$profile" == *":m1air"* || "$profile" == *":air"* ) ]]; then
    return 1
  fi
  if [[ "$DEVICE_PROFILE" == "m1air" && "$profile" == *":m1max"* ]]; then
    return 1
  fi
  case "$PROFILE_SET" in
    all) return 0 ;;
    quick)
      [[ "$profile" == quick:* ]]
      ;;
    wired)
      [[ "$profile" == wired:* || "$profile" == quick:wired:* ]]
      ;;
    wireless)
      [[ "$profile" == wireless:* || "$profile" == quick:wireless:* ]]
      ;;
    air)
      [[ "$profile" == air:* || "$profile" == quick:air:* ]]
      ;;
    *)
      echo "unknown PROFILE_SET=$PROFILE_SET" >&2
      exit 1
      ;;
  esac
}

maybe_run() {
  local selector="$1"
  shift
  if should_run "$selector"; then
    run_encode_case "$@"
  fi
}

# M1 Max wired candidates: chase full logical 5K first, with high-detail fallbacks.
maybe_run "quick:wired:m1max" \
  "m1max_wired_full_5k60_tiled_hevc" "wired" "synthetic-nv12-tiled" "5120x2880" 60 30 \
  --tile-columns 2 --tile-rows 2 --tile-reuse-buffers --tile-reset-every-frames 180 --tile-max-inflight-logical-frames 1

maybe_run "wired:m1max" \
  "m1max_wired_full_5k30_single_hevc" "wired" "synthetic-nv12" "5120x2880" 30 120

maybe_run "quick:wired:m1max" \
  "m1max_wired_high_detail_4096_60_hevc" "wired" "synthetic-nv12" "4096x2304" 60 120

maybe_run "wired:m1max" \
  "m1max_wired_4k60_hevc" "wired" "synthetic-nv12" "3840x2160" 60 60

# Wireless candidates: prefer lower bitrate and resolution stability over full 5K.
maybe_run "quick:wireless:balanced" \
  "wireless_balanced_3200_60_hevc" "wireless" "synthetic-nv12" "3200x1800" 60 60

maybe_run "wireless:4k" \
  "wireless_4k60_hevc" "wireless" "synthetic-nv12" "3840x2160" 60 45

maybe_run "wireless:retina2x" \
  "wireless_retina2x_1440p60_hevc" "wireless" "synthetic-nv12" "2560x1440" 60 25

# M1 Air candidates: do not assume tiled 5K60; establish lower-resolution ceilings first.
maybe_run "quick:air:baseline" \
  "m1air_baseline_1440p60_hevc" "any" "synthetic-nv12" "2560x1440" 60 25

maybe_run "air:balanced" \
  "m1air_balanced_3200_60_hevc" "any" "synthetic-nv12" "3200x1800" 60 35

maybe_run "air:wired_probe" \
  "m1air_wired_4k60_hevc" "wired" "synthetic-nv12" "3840x2160" 60 45

maybe_run "air:tiled_probe" \
  "m1air_wired_full_5k60_tiled_probe_hevc" "wired" "synthetic-nv12-tiled" "5120x2880" 60 25 \
  --tile-columns 2 --tile-rows 2 --tile-reuse-buffers --tile-reset-every-frames 180 --tile-max-inflight-logical-frames 1

if [[ "$INCLUDE_SCREEN_CAPTURE" == "1" ]]; then
  maybe_run "wired:sck" \
    "sck_4k60_capture_encode_hevc" "wired" "screen-capture" "3840x2160" 60 60 \
    --capture-display-index 0 --capture-queue-depth 8
  maybe_run "wired:sck" \
    "sck_4096_60_capture_encode_hevc" "wired" "screen-capture" "4096x2304" 60 80 \
    --capture-display-index 0 --capture-queue-depth 8
fi

cat > "$RUN_ROOT/summary.md" <<EOF
# Transmission Profile Matrix

- Device profile: \`$DEVICE_PROFILE\`
- Profile set: \`$PROFILE_SET\`
- Duration per case: \`$DURATION\` seconds
- Codec: HEVC
- Forced encoder: \`$AVE_HEVC_ID\`
- Summary table: \`summary.csv\`
- Encoder list: \`video_encoders.txt\`
- Sanitized system profile: \`system_profile_sanitized.txt\`

## Interpretation

This matrix measures sender-side encode viability only. It intentionally does not
claim receiver decode/render success. Use it to choose which capture, transport,
and bitrate profile should be tried before building OS-specific receiver decode
paths.

## Profile intent

- \`m1max_wired_full_5k60_tiled_hevc\`: best current full-resolution M1 Max path.
- \`m1max_wired_high_detail_4096_60_hevc\`: high-detail single-stream fallback.
- \`wireless_balanced_3200_60_hevc\`: first wireless default candidate.
- \`m1air_*\`: Air ceiling probes; results must be collected on the Air.
EOF

echo "Wrote $RUN_ROOT"
