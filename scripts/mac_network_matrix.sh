#!/usr/bin/env bash
set -euo pipefail

CASE_NAME=""
RECEIVER_IP=""
TAILSCALE_TARGET=""
DURATION="${DURATION:-20}"
RUN_ROOT="${RUN_ROOT:-}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/mac_network_matrix.sh --case <name> --receiver-ip <ip> [--tailscale-name <name-or-ip>]

Examples:
  scripts/mac_network_matrix.sh --case wifi-5g --receiver-ip 192.168.1.50
  scripts/mac_network_matrix.sh --case 1gbe --receiver-ip 169.254.10.2
  scripts/mac_network_matrix.sh --case thunderbolt --receiver-ip 169.254.20.2
  scripts/mac_network_matrix.sh --case tailscale --receiver-ip 100.x.y.z --tailscale-name imac

Environment:
  DURATION=20   iperf3 duration in seconds
  RUN_ROOT=...  optional benchmark output root
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --case)
      CASE_NAME="${2:-}"
      shift 2
      ;;
    --case=*)
      CASE_NAME="${1#--case=}"
      shift
      ;;
    --receiver-ip)
      RECEIVER_IP="${2:-}"
      shift 2
      ;;
    --receiver-ip=*)
      RECEIVER_IP="${1#--receiver-ip=}"
      shift
      ;;
    --tailscale-name|--tailscale-target)
      TAILSCALE_TARGET="${2:-}"
      shift 2
      ;;
    --tailscale-name=*|--tailscale-target=*)
      TAILSCALE_TARGET="${1#*=}"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$CASE_NAME" || -z "$RECEIVER_IP" ]]; then
  usage >&2
  exit 1
fi

STAMP="$(date +%Y-%m-%d_%H%M)"
if [[ -z "$RUN_ROOT" ]]; then
  RUN_ROOT="benchmarks/runs/${STAMP}_network_matrix"
fi
OUT_DIR="${RUN_ROOT}/${CASE_NAME}"
mkdir -p "$OUT_DIR"

{
  echo "case=$CASE_NAME"
  echo "receiver_ip=$RECEIVER_IP"
  echo "duration_seconds=$DURATION"
  echo "timestamp=$STAMP"
  echo "hostname=$(hostname)"
  echo "whoami=$(whoami)"
  echo "pwd=$(pwd)"
} | tee "$OUT_DIR/metadata.txt"

ifconfig > "$OUT_DIR/ifconfig.txt" || true
networksetup -listallhardwareports > "$OUT_DIR/networksetup_hardware_ports.txt" 2>&1 || true
networksetup -listallnetworkservices > "$OUT_DIR/networksetup_services.txt" 2>&1 || true

ping -c 100 "$RECEIVER_IP" | tee "$OUT_DIR/ping_100.txt" || true

if command -v iperf3 >/dev/null 2>&1; then
  iperf3 -c "$RECEIVER_IP" -t "$DURATION" --json > "$OUT_DIR/iperf3_tcp_to_receiver.json" || true
  iperf3 -c "$RECEIVER_IP" -t "$DURATION" -R --json > "$OUT_DIR/iperf3_tcp_from_receiver_reverse.json" || true
  for rate in 30 60 120; do
    iperf3 -c "$RECEIVER_IP" -u -b "${rate}M" -t "$DURATION" --json > "$OUT_DIR/iperf3_udp_${rate}mbps.json" || true
  done
else
  echo "iperf3 not installed; install it on both machines before cable benchmarks." | tee "$OUT_DIR/iperf3_missing.txt"
fi

if [[ "$CASE_NAME" == "tailscale" || -n "$TAILSCALE_TARGET" ]]; then
  TARGET="${TAILSCALE_TARGET:-$RECEIVER_IP}"
  if command -v tailscale >/dev/null 2>&1; then
    tailscale status > "$OUT_DIR/tailscale_status.txt" 2>&1 || true
    tailscale netcheck > "$OUT_DIR/tailscale_netcheck.txt" 2>&1 || true
    tailscale ping --c 10 "$TARGET" > "$OUT_DIR/tailscale_ping.txt" 2>&1 || true
  else
    echo "tailscale CLI not found" | tee "$OUT_DIR/tailscale_missing.txt"
  fi
fi

cat > "$OUT_DIR/summary.md" <<EOF
# Network Matrix Result: $CASE_NAME

- Receiver IP: \`$RECEIVER_IP\`
- Duration: \`$DURATION\` seconds
- Status: raw command artifacts captured; summarize min/avg/max/loss and iperf throughput after the physical path is confirmed.

## Required Notes

- Interface actually used:
- Physical path:
- Tailscale direct/relay status, if applicable:
- Link speed, if visible:
- Observed blockers:
EOF

echo "Wrote $OUT_DIR"
