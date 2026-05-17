# Network Matrix Benchmark Plan

Prompt: focused Plan C end-to-end pipeline spike after `prompts/04_PLAN_C_60HZ_SCALED_MODES.md`.

## Current Transport Classification

Previous compressed transport measurements must be classified narrowly:

| Field | Classification |
|---|---|
| Physical path | likely Wi-Fi 2.4GHz |
| Overlay path | Tailscale |
| Protocol | TCP |
| Representative of LAN/Thunderbolt? | no |
| Current conclusion | useful early failure signal only; not a LAN, 5GHz Wi-Fi, 1GbE, or Thunderbolt Bridge throughput result |

The current 5K HEVC TCP run measured only `3.092 Mbps` receive throughput over the active path. Treat this as a path-specific result until direct local IP, Ethernet, and Thunderbolt Bridge measurements exist.

Tailscale documents direct connections as the best-performance path, with relayed connections used when direct connectivity is unavailable. [내용 출처 : https://tailscale.com/docs/reference/connection-types]

Tailscale also documents `tailscale ping`, `tailscale status`, and `tailscale netcheck` as ways to inspect direct vs DERP/relay behavior. [내용 출처 : https://tailscale.com/docs/reference/troubleshooting/network-configuration/derp-routing]

## Matrix

Run each row when the physical setup is available. Do not block decode/render implementation on missing cables.

| Case | Primary path | Receiver path | Status |
|---|---|---|---|
| Wi-Fi 2.4GHz local IP | MacBook Wi-Fi | iMac Wi-Fi | pending |
| Wi-Fi 5GHz local IP | MacBook Wi-Fi | iMac Wi-Fi | pending |
| 1GbE LAN local IP | MacBook USB-C Ethernet or hub | iMac Ethernet | pending |
| Thunderbolt Bridge local IP | MacBook TB/USB-C to Apple TB3-to-TB2 adapter | iMac TB2 | pending |
| Tailscale IP | Tailscale overlay | Tailscale overlay | partial early data exists; direct/relay status pending |

## Measurements Per Case

Record these under `benchmarks/runs/YYYY-MM-DD_HHMM_network_matrix/<case>/`:

- interface name on both machines
- local IP and receiver IP
- link speed if the OS reports it
- ping 100 packets: min/avg/max/loss
- `iperf3` TCP MacBook -> iMac
- `iperf3` TCP iMac -> MacBook
- `iperf3` UDP at 30, 60, and 120 Mbps with jitter/loss
- Tailscale only: `tailscale ping`, `tailscale status`, and `tailscale netcheck`

## Receiver Setup

Start an `iperf3` server on the side being tested as receiver:

```powershell
iperf3 -s
```

For reverse-direction TCP, either use `iperf3 -R` from macOS or run the Windows script with the MacBook IP.

## macOS Runner

```bash
scripts/mac_network_matrix.sh --case 1gbe --receiver-ip <imac-local-ip>
scripts/mac_network_matrix.sh --case thunderbolt --receiver-ip <imac-thunderbolt-ip>
scripts/mac_network_matrix.sh --case tailscale --receiver-ip <imac-tailscale-ip> --tailscale-name <tailscale-host-or-ip>
```

## Windows Runner

```powershell
scripts\windows_network_matrix.ps1 -Case 1gbe -MacHost <macbook-local-ip>
scripts\windows_network_matrix.ps1 -Case thunderbolt -MacHost <macbook-thunderbolt-ip>
scripts\windows_network_matrix.ps1 -Case tailscale -MacHost <macbook-tailscale-ip> -TailscaleTarget <macbook-tailscale-name-or-ip>
```

## Interpretation Rules

- Keep Tailscale, direct local IP, Ethernet, and Thunderbolt Bridge results separate.
- Do not use DERP-relayed Tailscale throughput to reject LAN or Thunderbolt Bridge viability.
- For display streaming, high backlog is a latency failure even if every frame eventually arrives.
- The next implementation target remains Plan C compressed end-to-end display before UDP or tiled 5K work.
