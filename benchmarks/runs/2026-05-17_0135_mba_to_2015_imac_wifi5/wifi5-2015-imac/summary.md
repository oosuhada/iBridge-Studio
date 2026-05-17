# Network Matrix Result: wifi5-2015-imac

- Receiver IP: `192.168.31.187`
- Duration: `10` seconds
- Status: partial Wi-Fi matrix captured from MacBook Air to 2015 27-inch iMac.

## Required Notes

- Interface actually used: MacBook Air Wi-Fi `en0`, local IP `192.168.31.11`.
- Physical path: same LAN / 5GHz Wi-Fi candidate, no Ethernet cable attached for this run.
- Receiver identity: Tailscale shows `gabriels-imac27-2015`, macOS, Tailscale IP `100.84.32.31`; local endpoint observed as `192.168.31.187:41641`.
- Tailscale direct/relay status, if applicable: `tailscale ping` reached the receiver via `192.168.31.187:41641` in the captured spot check, so this path appears local-direct rather than DERP for the spot check.
- Ping result: 100/100 received, min/avg/max/stddev `3.819/51.446/420.666/88.334 ms`.
- Port probe: TCP `22` and `5201` open on both `192.168.31.187` and `100.84.32.31`; TCP `48320` refused, so the iBridge receiver is not listening.
- Link speed, if visible: not captured; Tahoe 26 does not expose the old `airport -I` path on this MacBook Air.
- Observed blockers: MacBook Air local `iperf3` is missing. `brew install iperf3` failed because the local Homebrew install cannot auto-update cleanly and reports unsupported macOS `26.5`; do not reset Homebrew without user approval. SSH port is open but MacBook Air key is not authorized for `gabrieljang` or `gabriel` on the 2015 iMac.

## Read

The 2015 iMac Wi-Fi path is reachable and appears to be on the same LAN, but
the latency spikes are far beyond a 60Hz display budget. Treat this as a
reachability/prep result only. Do not choose high-detail receiver profiles from
this Wi-Fi path until packet loss/throughput can be measured and the jitter is
reduced.
