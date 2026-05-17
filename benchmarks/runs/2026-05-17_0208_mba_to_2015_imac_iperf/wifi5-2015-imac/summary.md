# Network Matrix Result: wifi5-2015-imac

- Receiver IP: `192.168.31.187`
- Duration: `20` seconds
- Status: MacBook Air to 2015 27-inch iMac Wi-Fi throughput matrix captured.

## Required Notes

- Interface actually used: MacBook Air Wi-Fi `en0`, local IP `192.168.31.11`.
- Physical path: same-LAN Wi-Fi from MacBook Air to 2015 iMac, no Ethernet cable attached.
- Receiver identity: `gabriels-imac27-2015`, local IP `192.168.31.187`, Tailscale IP `100.84.32.31`.
- Tailscale direct/relay status, if applicable: artifacts captured; earlier spot check reached the iMac through local endpoint `192.168.31.187:41641`.
- Ping: 100/100 received, min/avg/max/stddev `3.690/30.495/258.942/44.687 ms`.
- TCP to receiver: `154.09 Mbps` received.
- TCP reverse from receiver: `129.43 Mbps` received.
- UDP 30 Mbps: `29.99 Mbps` received, `0%` loss, `0.603 ms` iperf jitter.
- UDP 60 Mbps: `59.78 Mbps` received, `0.333%` loss, `0.246 ms` iperf jitter.
- UDP 120 Mbps: `119.95 Mbps` received, `0.003%` loss, `0.188 ms` iperf jitter.
- Link speed, if visible: not interpreted from current artifacts.
- Observed blockers: SSH auth from MacBook Air to the 2015 iMac is still not confirmed; TCP `48320` was refused in the prior port probe, so no iBridge receiver was listening yet.

## Read

The throughput result is much better than the ICMP latency spikes suggest:
120Mbps UDP was essentially lossless over the 20-second iperf run. However,
ICMP still shows repeated 100-250ms latency spikes, so this path should not be
treated as a smooth low-latency display transport yet.

For MacBook Air, this keeps only the conservative `2560x1440@60` HEVC profile
in scope for a live smoke test. Do not use this Wi-Fi path for 5K, tiled 5K, or
high-detail fallback decisions.
