#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-10}"
FALLBACK_DURATION="${FALLBACK_DURATION:-5}"
CLEAN_BOOT_MAX_MINUTES="${CLEAN_BOOT_MAX_MINUTES:-15}"
REQUIRE_CLEAN_BOOT="${REQUIRE_CLEAN_BOOT:-1}"
RUN_ROOT="${RUN_ROOT:-}"
AVE_HEVC_ID="${AVE_HEVC_ID:-com.apple.videotoolbox.videoencoder.ave.hevc}"

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_clean_session_encoder_probe"
fi
mkdir -p "$RUN_ROOT"

PRIMARY="apps/primary-macos/.build/release/ibridge-primary"

usage() {
  cat <<'USAGE'
Usage:
  DURATION=10 FALLBACK_DURATION=5 scripts/mac_clean_session_encoder_probe.sh

Purpose:
  Run the clean-session A/B gate:
    1. Verify the Mac booted recently.
    2. Run segment-hints tiled 5K60 first.
    3. Immediately run 4096x2304, 3200x1800, and 2560x1440 fallback probes.

Environment:
  CLEAN_BOOT_MAX_MINUTES=15
  REQUIRE_CLEAN_BOOT=1
  RUN_ROOT=benchmarks/runs/custom_name

Set REQUIRE_CLEAN_BOOT=0 only for a deliberately dirty control run.
USAGE
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

boot_epoch="$(sysctl -n kern.boottime | awk -F'[=,]' '{ gsub(/ /, "", $2); print $2 }')"
now_epoch="$(date +%s)"
uptime_minutes="$(( (now_epoch - boot_epoch) / 60 ))"

{
  echo "timestamp=$STAMP"
  echo "duration_seconds=$DURATION"
  echo "fallback_duration_seconds=$FALLBACK_DURATION"
  echo "clean_boot_max_minutes=$CLEAN_BOOT_MAX_MINUTES"
  echo "require_clean_boot=$REQUIRE_CLEAN_BOOT"
  echo "uptime_minutes=$uptime_minutes"
  echo "boot_time=$(date -r "$boot_epoch" '+%Y-%m-%d %H:%M:%S %z')"
  echo "hostname=$(hostname)"
  echo "pwd=$(pwd)"
  uname -a
} > "$RUN_ROOT/metadata.txt"

if [[ "$REQUIRE_CLEAN_BOOT" == "1" && "$uptime_minutes" -gt "$CLEAN_BOOT_MAX_MINUTES" ]]; then
  {
    echo "# Clean Session Encoder Probe"
    echo
    echo "Skipped: current uptime is ${uptime_minutes} minutes, exceeding CLEAN_BOOT_MAX_MINUTES=${CLEAN_BOOT_MAX_MINUTES}."
    echo
    echo "Run this script immediately after reboot/login to get a valid clean-session result."
  } > "$RUN_ROOT/summary.md"
  echo "not_clean_uptime_minutes=$uptime_minutes"
  echo "wrote $RUN_ROOT/summary.md"
  exit 2
fi

swift build --package-path apps/primary-macos -c release

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
  local duration="$5"
  local bitrate="$6"
  local status="$7"
  local csv="$8"
  local log="$9"
  local logical_csv="${10}"
  local deadline_md="${11}"

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
    "$case_name" "$mode" "$resolution" "$fps" "$duration" "$bitrate" "$status" \
    "${frames_encoded:-0}" "${effective:-}" "${avg:-0}" "${p95:-0}" "${max:-0}" \
    "${p95_steady:-}" "${over_16:-}" "${over_33:-}" "$csv" "$logical_csv" "$deadline_md" "$log" \
    >> "$RUN_ROOT/summary.csv"
}

run_segment_hints_tiled_first() {
  local csv="$RUN_ROOT/segment_hints_tiled_first.csv"
  local log="$RUN_ROOT/segment_hints_tiled_first.txt"
  local logical_csv="${csv%.csv}_logical.csv"
  local deadline_md="${csv%.csv}_deadline.md"

  set +e
  "$PRIMARY" \
    --synthetic \
    --source synthetic-nv12-tiled \
    --resolution 5120x2880 \
    --fps 60 \
    --duration "$DURATION" \
    --codec hevc \
    --bitrate-mbps 30 \
    --encoder-id "$AVE_HEVC_ID" \
    --disable-low-latency-rate-control \
    --allow-temporal-compression \
    --disable-frame-reordering \
    --disable-open-gop \
    --data-rate-limit-mbps 30 \
    --data-rate-window 1.0 \
    --prioritize-speed \
    --tile-columns 2 \
    --tile-rows 2 \
    --tile-reuse-buffers \
    --tile-reset-every-frames 180 \
    --tile-max-inflight-logical-frames 1 \
    --tile-segment-hints \
    --warmup-frames 30 \
    --csv "$csv" > "$log" 2>&1
  local exit_code=$?
  set -e

  if [[ -f "$logical_csv" ]]; then
    python3 scripts/analyze_tiled_deadline.py "$logical_csv" --run-log "$log" --summary-md "$deadline_md" >/dev/null
  else
    deadline_md=""
  fi
  append_summary "segment_hints_tiled_first" "tiled" "5120x2880" "60" "$DURATION" "30" "$exit_code" "$csv" "$log" "$logical_csv" "$deadline_md"
}

run_fallback_case() {
  local case_name="$1"
  local resolution="$2"
  local bitrate="$3"
  local csv="$RUN_ROOT/${case_name}.csv"
  local log="$RUN_ROOT/${case_name}.txt"

  set +e
  "$PRIMARY" \
    --synthetic \
    --source synthetic-nv12 \
    --resolution "$resolution" \
    --fps 60 \
    --duration "$FALLBACK_DURATION" \
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

  append_summary "$case_name" "single" "$resolution" "60" "$FALLBACK_DURATION" "$bitrate" "$exit_code" "$csv" "$log" "" ""
}

run_segment_hints_tiled_first
run_fallback_case "post_tiled_4096_fallback" "4096x2304" "120"
run_fallback_case "post_tiled_3200_fallback" "3200x1800" "60"
run_fallback_case "post_tiled_2560_fallback" "2560x1440" "25"

python3 - "$RUN_ROOT/summary.csv" "$RUN_ROOT/summary.md" <<'PY'
import csv
import sys

csv_path, md_path = sys.argv[1:3]
rows = list(csv.DictReader(open(csv_path, newline="")))

def p95(case):
    row = next((r for r in rows if r["case"] == case), None)
    if not row:
        return None
    try:
        return float(row["p95_encode_ms"])
    except ValueError:
        return None

fallback_4096 = p95("post_tiled_4096_fallback")
fallback_3200 = p95("post_tiled_3200_fallback")
fallback_2560 = p95("post_tiled_2560_fallback")

passes_high_detail = (
    fallback_4096 is not None and fallback_4096 <= 16.67
    and fallback_3200 is not None and fallback_3200 <= 16.67
)

with open(md_path, "w") as f:
    f.write("# Clean Session Encoder Probe\n\n")
    f.write("| Case | P95 ms | Result |\n")
    f.write("|---|---:|---|\n")
    for case in [
        "segment_hints_tiled_first",
        "post_tiled_4096_fallback",
        "post_tiled_3200_fallback",
        "post_tiled_2560_fallback",
    ]:
        value = p95(case)
        result = "pass" if value is not None and value <= 16.67 else "fail"
        f.write(f"| `{case}` | {value if value is not None else 'n/a'} | {result} |\n")
    f.write("\n")
    if passes_high_detail:
        f.write("Decision: high-detail fallback switching remains viable after segment-hints tiled 5K60.\n")
    else:
        f.write("Decision: high-detail fallback switching remains unsafe; keep product emergency fallback at `2560x1440@60` until a stronger reset boundary is proven.\n")
PY

cat "$RUN_ROOT/summary.md"
