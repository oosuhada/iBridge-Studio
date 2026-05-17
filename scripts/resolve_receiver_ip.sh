#!/usr/bin/env bash
set -euo pipefail

RECEIVER_PORT="${RECEIVER_PORT:-48320}"
RECEIVER_IP="${RECEIVER_IP:-}"
RECEIVER_DISCOVERY_HOST="${RECEIVER_DISCOVERY_HOST:-}"
RECEIVER_KEY="${RECEIVER_KEY:-}"

ssh_base=(ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new)
if [[ -n "$RECEIVER_KEY" ]]; then
  ssh_base+=(-i "$RECEIVER_KEY")
fi

add_candidate() {
  local ip="$1"
  local iface="${2:-unknown}"
  [[ -z "$ip" ]] && return 0
  [[ "$ip" == 127.* ]] && return 0
  [[ "$ip" == 0.0.0.0 ]] && return 0
  printf '%s %s\n' "$ip" "$iface"
}

candidate_lines=()
if [[ -n "$RECEIVER_IP" ]]; then
  candidate_lines+=("$(add_candidate "$RECEIVER_IP" configured)")
fi

if [[ -n "$RECEIVER_DISCOVERY_HOST" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && candidate_lines+=("$line")
  done < <(
    "${ssh_base[@]}" "$RECEIVER_DISCOVERY_HOST" '
      ifconfig | awk "
        /^[a-z0-9]+:/ {
          iface = \$1
          sub(\":\", \"\", iface)
        }
        /inet / {
          ip = \$2
          if (ip !~ /^127\\./ && ip != \"0.0.0.0\") {
            print ip, iface
          }
        }
      "
    ' 2>/dev/null || true
  )
fi

if [[ "${#candidate_lines[@]}" -eq 0 ]]; then
  echo "No receiver IP candidates. Set Receiver IP or Discovery host." >&2
  exit 2
fi

rank_candidate() {
  local ip="$1"
  local iface="$2"
  if [[ "$iface" == bridge* && "$ip" == 169.254.* ]]; then
    echo 10
  elif [[ "$ip" == 169.254.* ]]; then
    echo 20
  elif [[ "$ip" == 192.168.* || "$ip" == 10.* || "$ip" == 172.16.* || "$ip" == 172.17.* || "$ip" == 172.18.* || "$ip" == 172.19.* || "$ip" == 172.2* || "$ip" == 172.30.* || "$ip" == 172.31.* ]]; then
    echo 30
  elif [[ "$ip" == 100.* ]]; then
    echo 40
  else
    echo 50
  fi
}

sorted_candidates="$(
  printf '%s\n' "${candidate_lines[@]}" |
    awk 'NF >= 1 && !seen[$1]++ { print }' |
    while read -r ip iface; do
      printf '%s %s %s\n' "$(rank_candidate "$ip" "${iface:-unknown}")" "$ip" "${iface:-unknown}"
    done |
    sort -n
)"

while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  read -r _rank ip iface <<<"$row"
  echo "checking receiver candidate $ip ($iface)" >&2
  if nc -G 1 -z "$ip" "$RECEIVER_PORT" >/dev/null 2>&1; then
    echo "selected receiver $ip ($iface)" >&2
    printf '%s\n' "$ip"
    exit 0
  fi
done <<<"$sorted_candidates"

echo "No reachable receiver on port $RECEIVER_PORT." >&2
printf '%s\n' "$sorted_candidates" >&2
exit 1
