# MacBook Pro Automatic Encoder Baseline

Prompt: MacBook Pro Primary comparison after MacBook Air / iMac tests.

This run used automatic encoder selection with low-latency rate-control enabled, matching the current default CLI behavior.

| Test | Frames | Failed | Avg encode ms | P95 encode ms | Max encode ms | Payload bytes |
|---|---:|---:|---:|---:|---:|---:|
| HEVC 2560x1440 120Mbps | 300 | 0 | 59.218 | 129.926 | 134.430 | 14,095,734 |
| HEVC 3200x1800 120Mbps | 300 | 0 | 96.271 | 196.283 | 202.067 | 22,320,881 |
| HEVC 3200x1800 80Mbps | 300 | 0 | 95.456 | 196.456 | 202.483 | 22,268,615 |
| HEVC 3840x2160 120Mbps | 300 | 0 | 126.599 | 176.685 | 181.837 | 31,474,566 |
| HEVC 4096x2304 120Mbps | 300 | 0 | 141.326 | 198.312 | 204.227 | 35,777,809 |
| H.264 3840x2160 120Mbps | 300 | 0 | 114.343 | 159.438 | 164.955 | 32,037,694 |
| H.264 5120x2880 120Mbps | 300 | 300 | 8.309 | 8.684 | 55.687 | 0 |

## Result

Automatic low-latency selection is not acceptable on this MacBook Pro for Plan C HEVC. H.264 5K still produces zero payloads.
