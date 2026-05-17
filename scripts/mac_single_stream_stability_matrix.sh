#!/usr/bin/env bash
set -euo pipefail

DURATION="${DURATION:-5}"
REPEATS="${REPEATS:-3}"
COOLDOWN_SECONDS="${COOLDOWN_SECONDS:-3}"
RUN_ROOT="${RUN_ROOT:-}"
AVE_HEVC_ID="${AVE_HEVC_ID:-com.apple.videotoolbox.videoencoder.ave.hevc}"
BITRATE_MBPS="${BITRATE_MBPS:-120}"
PRIORITIZE_SPEED="${PRIORITIZE_SPEED:-unset}"

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_single_stream_stability"
fi
mkdir -p "$RUN_ROOT"

PRIMARY="apps/primary-macos/.build/release/ibridge-primary"

usage() {
  cat <<'USAGE'
Usage:
  REPEATS=3 DURATION=5 scripts/mac_single_stream_stability_matrix.sh

Environment:
  DURATION=5
  REPEATS=3
  COOLDOWN_SECONDS=3
  BITRATE_MBPS=120
  PRIORITIZE_SPEED=unset|on|off
  RUN_ROOT=benchmarks/runs/custom_name

This isolates single-stream HEVC stability across repeated runs. It intentionally
does not run tiled encoding or receiver decode/render.
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
  echo "repeats=$REPEATS"
  echo "cooldown_seconds=$COOLDOWN_SECONDS"
  echo "bitrate_mbps=$BITRATE_MBPS"
  echo "prioritize_speed=$PRIORITIZE_SPEED"
  echo "encoder_id=$AVE_HEVC_ID"
  echo "hostname=$(hostname)"
  echo "hw_model=$(sysctl -n hw.model 2>/dev/null || true)"
  echo "cpu=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
  pmset -g batt 2>/dev/null | paste -sd ' ' - | sed 's/[[:space:]]*$//'
} > "$RUN_ROOT/metadata.txt"

system_profiler SPHardwareDataType SPDisplaysDataType \
  | sed '/Serial Number/d;/Hardware UUID/d;/Provisioning UDID/d' \
  > "$RUN_ROOT/system_profile_sanitized.txt" 2>&1 || true

cat > "$RUN_ROOT/summary.csv" <<'CSV'
run_index,resolution,fps,bitrate_mbps,prioritize_speed,status,frames_requested,frames_submitted,frames_encoded,failed_frames,avg_generate_ms,avg_encode_ms,p95_encode_ms,max_encode_ms,payload_bytes,log,csv
CSV

extract_metric() {
  local key="$1"
  local log="$2"
  awk -F= -v key="$key" '$1 == key { value=$2 } END { print value }' "$log"
}

append_summary() {
  local run_index="$1"
  local resolution="$2"
  local status="$3"
  local log="$4"
  local csv="$5"

  local frames_requested frames_submitted frames_encoded failed generate avg p95 max payload
  frames_requested="$(extract_metric frames_requested "$log")"
  frames_submitted="$(extract_metric frames_submitted "$log")"
  frames_encoded="$(extract_metric frames_encoded "$log")"
  failed="$(extract_metric failed_frames "$log")"
  generate="$(extract_metric avg_generate_ms "$log")"
  avg="$(extract_metric avg_encode_latency_ms "$log")"
  p95="$(extract_metric p95_encode_latency_ms "$log")"
  max="$(extract_metric max_encode_latency_ms "$log")"
  payload="$(extract_metric payload_bytes "$log")"

  printf '%s,%s,60,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$run_index" "$resolution" "$BITRATE_MBPS" "$PRIORITIZE_SPEED" "$status" \
    "${frames_requested:-0}" "${frames_submitted:-0}" "${frames_encoded:-0}" \
    "${failed:-1}" "${generate:-0}" "${avg:-0}" "${p95:-0}" "${max:-0}" \
    "${payload:-0}" "$log" "$csv" >> "$RUN_ROOT/summary.csv"
}

run_case() {
  local run_index="$1"
  local resolution="$2"
  local safe_resolution="${resolution//x/_}"
  local log="$RUN_ROOT/run${run_index}_${safe_resolution}.txt"
  local csv="$RUN_ROOT/run${run_index}_${safe_resolution}.csv"
  local command=(
    "$PRIMARY"
    --synthetic
    --source synthetic-nv12
    --resolution "$resolution"
    --fps 60
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
    --csv "$csv"
  )

  case "$PRIORITIZE_SPEED" in
    on) command+=(--prioritize-speed) ;;
    off) command+=(--prioritize-quality) ;;
    unset) ;;
    *)
      echo "unknown PRIORITIZE_SPEED=$PRIORITIZE_SPEED" >&2
      exit 1
      ;;
  esac

  {
    echo "run_index=$run_index"
    echo "resolution=$resolution"
    echo "started_at=$(date '+%Y-%m-%d %H:%M:%S %Z')"
    pmset -g batt 2>/dev/null | paste -sd ' ' - | sed 's/[[:space:]]*$//'
    echo "--- encoder output ---"
  } > "$log"

  set +e
  "${command[@]}" >> "$log" 2>&1
  local status=$?
  set -e

  {
    echo "--- run footer ---"
    echo "finished_at=$(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "exit_code=$status"
  } >> "$log"

  append_summary "$run_index" "$resolution" "$status" "$log" "$csv"
}

RESOLUTIONS=(4096x2304 3840x2160 3200x1800 2560x1440)

for run_index in $(seq 1 "$REPEATS"); do
  for resolution in "${RESOLUTIONS[@]}"; do
    run_case "$run_index" "$resolution"
    if [[ "$COOLDOWN_SECONDS" -gt 0 ]]; then
      sleep "$COOLDOWN_SECONDS"
    fi
  done
done

python3 - "$RUN_ROOT/summary.csv" "$RUN_ROOT/aggregate.md" <<'PY'
import csv
import statistics
import sys
from collections import defaultdict

summary_path, output_path = sys.argv[1:3]
rows = list(csv.DictReader(open(summary_path)))
groups: dict[str, list[dict[str, str]]] = defaultdict(list)
for row in rows:
    groups[row["resolution"]].append(row)

lines = ["# Single Stream Stability Aggregate", ""]
lines.append("| Resolution | Runs | Avg of avg ms | Best p95 ms | Median p95 ms | Worst p95 ms | Worst max ms | Pass p95 <=16.67 |")
lines.append("|---|---:|---:|---:|---:|---:|---:|---:|")
for resolution in ("4096x2304", "3840x2160", "3200x1800", "2560x1440"):
    items = groups.get(resolution, [])
    avgs = [float(item["avg_encode_ms"]) for item in items]
    p95s = [float(item["p95_encode_ms"]) for item in items]
    maxes = [float(item["max_encode_ms"]) for item in items]
    pass_count = sum(1 for value in p95s if value <= 16.67)
    lines.append(
        f"| {resolution} | {len(items)} | "
        f"{(statistics.mean(avgs) if avgs else 0):.3f} | "
        f"{(min(p95s) if p95s else 0):.3f} | "
        f"{(statistics.median(p95s) if p95s else 0):.3f} | "
        f"{(max(p95s) if p95s else 0):.3f} | "
        f"{(max(maxes) if maxes else 0):.3f} | "
        f"{pass_count}/{len(items)} |"
    )

open(output_path, "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
PY

cat > "$RUN_ROOT/summary.md" <<EOF
# Single Stream Stability Matrix

- Duration per run: \`$DURATION\` seconds
- Repeats per resolution: \`$REPEATS\`
- Cooldown between cases: \`$COOLDOWN_SECONDS\` seconds
- Codec: HEVC
- Source: synthetic NV12
- Bitrate/DataRateLimits: \`$BITRATE_MBPS Mbps\`
- Forced encoder: \`$AVE_HEVC_ID\`
- Prioritize speed: \`$PRIORITIZE_SPEED\`
- Main table: \`summary.csv\`
- Aggregate: \`aggregate.md\`

## Intent

This isolates single-stream sender latency variance for 4096x2304, 3840x2160,
3200x1800, and 2560x1440 before choosing wired or wireless fallback profiles.
EOF

echo "Wrote $RUN_ROOT"
