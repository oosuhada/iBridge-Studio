# Plan A 5K60 Bandwidth Theory

Prompt: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`

## Target

Plan A starts at the highest user target:

```text
5120 x 2880 @ 60 fps
```

Pixel count:

```text
5120 * 2880 = 14,745,600 pixels/frame
14,745,600 * 60 = 884,736,000 pixels/sec
```

## Raw RGB 24-bit

```text
bits/sec = 5120 * 2880 * 60 * 24
         = 21,233,664,000 bps
         = 21.234 Gbps

bytes/frame = 5120 * 2880 * 3
            = 44,236,800 bytes
            = 44.237 MB/frame

bytes/sec = 44,236,800 * 60
          = 2,654,208,000 bytes/sec
          = 2.654 GB/sec
```

Raw RGB24 5K60 already exceeds a 20Gbps-class Thunderbolt 2 link before IP, packetization, capture, copy, render, and protocol overhead. Apple's TB3-to-TB2 adapter document describes Thunderbolt 2 transfer up to 20Gbps for Thunderbolt 2 devices. [내용 출처 : https://support.apple.com/en-us/111753]

## BGRA 32-bit App Buffer

The first Windows synthetic renderer uses `DXGI_FORMAT_B8G8R8A8_UNORM` because it is a common D3D11 presentation/upload format.

```text
bits/sec = 5120 * 2880 * 60 * 32
         = 28,311,552,000 bps
         = 28.312 Gbps

bytes/frame = 5120 * 2880 * 4
            = 58,982,400 bytes
            = 58.982 MB/frame

bytes/sec = 58,982,400 * 60
          = 3,538,944,000 bytes/sec
          = 3.539 GB/sec
```

This is not the intended network format, but it is a useful receiver-side stress test because it measures whether the iMac can generate, upload, draw, and present a full 5K frame every 16.667 ms.

## YUV 4:2:0 8-bit

YUV 4:2:0 8-bit is 12 bits/pixel.

```text
bits/sec = 5120 * 2880 * 60 * 12
         = 10,616,832,000 bps
         = 10.617 Gbps

bytes/frame = 5120 * 2880 * 1.5
            = 22,118,400 bytes
            = 22.118 MB/frame

bytes/sec = 22,118,400 * 60
          = 1,327,104,000 bytes/sec
          = 1.327 GB/sec
```

YUV 4:2:0 is below Thunderbolt 2's theoretical 20Gbps figure, but it is still far above 1GbE and still requires conversion/subsampling. It must be tested as near-raw, not assumed to work.

## Transport Comparison

| Transport | Nominal link | Plan A implication |
|---|---:|---|
| 1GbE | 1 Gbps class | Too small for raw RGB24 or YUV 4:2:0 5K60 before overhead. Useful for latency and compressed fallback measurements. |
| Thunderbolt 2 | Up to 20 Gbps class | Still below raw RGB24 5K60 before overhead. YUV 4:2:0 is theoretically under the link rate but needs real Thunderbolt Bridge throughput and latency tests. |

Apple documents the Late 2015 iMac with 10/100/1000BASE-T Gigabit Ethernet and Thunderbolt 2 ports. [내용 출처 : https://support.apple.com/en-us/112035]

Apple documents IP communication between two Thunderbolt-equipped Macs over Thunderbolt Bridge. [내용 출처 : https://support.apple.com/guide/mac-help/ip-thunderbolt-connect-mac-computers-mchld53dd2f5/mac]

Apple documents direct Ethernet networking between two Macs. [내용 출처 : https://support.apple.com/en-om/guide/mac-help/mchlp1413/mac]

## Current Decision

Do not downshift from Plan A yet.

Plan A raw RGB24 over 1GbE is mathematically out of range, and raw RGB24 over Thunderbolt 2 is over the nominal link rate before overhead. However, Plan A still needs the required local benchmark path:

- Windows Receiver synthetic 5K60 local render benchmark.
- Measured LAN throughput/latency.
- Measured Thunderbolt Bridge throughput/latency if the hardware path is available.

Only measured receiver/render/transport failures should trigger the Plan B start.
