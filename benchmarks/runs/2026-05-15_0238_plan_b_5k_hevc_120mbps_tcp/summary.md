# Plan B 5K60 HEVC 120Mbps TCP Transport

Prompt: `prompts/03_PLAN_B_5K60_PRACTICAL.md`

Primary command:

```bash
apps/primary-macos/.build/release/ibridge-primary --synthetic --resolution 5120x2880 --fps 60 --duration 1 --codec hevc --bitrate-mbps 120 --send-host 100.86.52.88 --send-port 48320 --csv benchmarks/runs/2026-05-15_0238_plan_b_5k_hevc_120mbps_tcp/primary_stats.csv
```

Receiver command:

```powershell
ibridge-receiver.exe --transport-sink --port 48320 --duration 60 --csv C:\dev\iBridge\benchmarks\runs\2026-05-15_0238_plan_b_5k_hevc_120mbps_tcp\receiver_stats.csv
```

Result:

| Metric | Value |
|---|---:|
| Primary frames encoded | 60 |
| Primary failed frames | 0 |
| Primary payload bytes | 15,356,893 |
| Primary avg generate | 35.342 ms |
| Primary avg encode callback latency | 5,840.621 ms |
| Primary max encode callback latency | 11,008.292 ms |
| Primary avg send | 636.270 ms |
| Primary max send | 2,250.204 ms |
| Receiver frames received | 60 |
| Receiver payload bytes | 15,356,893 |
| Receiver missing frames | 0 |
| Receiver avg receive | 662.186 ms |
| Receiver measured throughput | 3.092 Mbps |
| Wall time | 38.60 s |

Classification:

- `transport bottleneck`: TCP over the current Tailscale path is far below the throughput required for even a 120Mbps 5K60 compressed stream.
- `encode latency bottleneck`: blocking sends from the encode callback inflate callback latency, so transport must be decoupled from encode before product latency can be measured fairly.
- `decode/render bottleneck`: not measured in this run because the receiver sink intentionally validates transport only.

