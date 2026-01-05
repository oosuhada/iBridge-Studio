# Plan A Transport Benchmark Plan

Prompt: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`

## Goal

Measure real LAN and Thunderbolt Bridge throughput/latency before making any Plan A downshift decision.

## LAN

Receiver side:

```powershell
iperf3 -s
```

Primary macOS side:

```bash
scripts/mac_network_probe.sh <receiver-ip>
```

Expected artifacts:

```text
logs/ping_<receiver-ip>.txt
logs/iperf3_<receiver-ip>.txt
```

## Thunderbolt Bridge

Required hardware:

- Apple Thunderbolt 3 to Thunderbolt 2 Adapter
- Thunderbolt 2 cable
- iMac Thunderbolt 2 port
- MacBook USB-C/Thunderbolt port

Apple documents IP communication between two Thunderbolt-equipped Macs over Thunderbolt Bridge. [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]

Apple documents the TB3-to-TB2 adapter as supporting Thunderbolt/Thunderbolt 2 data transfer up to 20Gbps with Thunderbolt 2 devices. [내용 출처 : https://support.apple.com/en-us/111753]

Run the same `iperf3` and ping tests over the Thunderbolt interface IP if available.

## Required Metrics

- ping min/avg/max/stddev
- iperf3 sender bitrate
- iperf3 receiver bitrate
- retransmits if TCP
- interface used: Ethernet or Thunderbolt Bridge
- cable/adapter path

## Plan A Gate

Raw RGB24 5K60 requires 21.234Gbps before overhead. YUV 4:2:0 8-bit requires 10.617Gbps before overhead. See `benchmarks/theory/5k60_bandwidth.md`.

Plan A can continue only if measured transport and receiver render results leave enough headroom for capture, packetization, copies, and render. If measured transport is below near-raw requirements, Plan A should be recorded as failed for that transport and Plan B should start for compressed 5K60.
