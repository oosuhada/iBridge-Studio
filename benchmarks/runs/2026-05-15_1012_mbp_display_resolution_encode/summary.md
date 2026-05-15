# MacBook Pro Display Resolution Encode Probe

Prompt: MacBook Pro Primary comparison after MacBook Air / iMac tests.

All tests forced `com.apple.videotoolbox.videoencoder.ave.hevc` and disabled low-latency rate-control.

| Display-sized source | Resolution | Frames | Failed | Avg generate ms | Avg encode ms | P95 encode ms | Max encode ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| Built-in XDR | 3024x1964 | 180 | 0 | 7.260 | 16.941 | 17.235 | 59.934 |
| USB-C/portrait TFX173T | 1080x1920 | 180 | 0 | 4.076 | 9.718 | 9.559 | 62.368 |
| Sidecar iPad Air 5 | 2360x1640 | 180 | 0 | 4.921 | 16.205 | 17.276 | 67.425 |
| HDMI LG FHD | 1920x1080 | 180 | 0 | 3.026 | 9.498 | 9.485 | 49.238 |

## Result

All current display-sized synthetic sources encode successfully under the 60Hz frame budget on average. This does not yet prove live screen capture performance; it only isolates synthetic frame generation and VideoToolbox encode for each display resolution.
