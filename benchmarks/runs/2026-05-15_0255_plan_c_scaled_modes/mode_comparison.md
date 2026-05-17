# Plan C 60Hz Scaled Mode Comparison

Prompt: `prompts/04_PLAN_C_60HZ_SCALED_MODES.md`

Goal: compare 60Hz fallback modes for a 5120x2880 iMac output after Plan B 5K60 compressed mode showed encode and transport bottlenecks.

## Receiver Scaled Render Test

All receiver runs used:

```powershell
ibridge-receiver.exe --synthetic --resolution <source> --output-resolution 5120x2880 --fps 60 --duration 8 --fullscreen --static-frame --scale-mode <mode> --csv <file>
```

These runs measure iMac-side D3D11 source-to-5K output scaling/present cost without network decode.

| Mode | Source | Scale | Receiver fps | P95 total ms | Max total ms | Missed frames |
|---|---:|---|---:|---:|---:|---:|
| 1440p nearest | 2560x1440 | nearest | 59.881 | 17.476 | 25.163 | 241 |
| 1440p linear | 2560x1440 | linear | 59.994 | 17.459 | 23.271 | 230 |
| 3200x1800 linear | 3200x1800 | linear | 59.885 | 17.477 | 31.456 | 220 |
| 4K linear | 3840x2160 | linear | 59.840 | 17.418 | 35.613 | 232 |
| 4096x2304 linear | 4096x2304 | linear | 59.777 | 17.473 | 38.184 | 223 |

Interpretation:

- All static scaled render modes reached about 60fps on the iMac D3D11 path.
- 1440p nearest and linear are both viable at the local renderer/present layer.
- Higher source resolutions show larger max frame spikes, but the p95 values remain clustered around one vsync interval.

## Primary HEVC 120Mbps Local Encode Test

All Primary runs used:

```bash
ibridge-primary --synthetic --resolution <source> --fps 60 --duration 1 --codec hevc --bitrate-mbps 120 --csv <file>
```

| Mode | Source | Avg generate ms | Avg encode latency ms | P95 encode latency ms | Payload bytes |
|---|---:|---:|---:|---:|---:|
| 1440p | 2560x1440 | 5.389 | 16.876 | 40.792 | 15,758,016 |
| 3200x1800 | 3200x1800 | 8.520 | 14.738 | 23.529 | 15,467,082 |
| 4K | 3840x2160 | 10.963 | 21.164 | 38.249 | 15,521,173 |
| 4096x2304 | 4096x2304 | 12.332 | 27.231 | 48.630 | 15,568,675 |

Interpretation:

- 3200x1800 had the best encode latency in this short synthetic HEVC run.
- 1440p had the lowest generation cost, but p95 encode latency was worse than 3200x1800 in this sample.
- 4K and 4096x2304 carry higher generation and encode latency pressure.

## Subjective Text Quality

Not scored yet.

Reason:

- The receiver does not yet decode and display compressed Primary frames.
- The current receiver scaled-render test uses a synthetic color pattern/static texture, not a code editor or terminal text scene.
- Screenshot capture samples are therefore pending rather than guessed.

Required follow-up once decode/render exists:

- VS Code or terminal text at small font sizes.
- Scroll test.
- Mouse movement test.
- Screenshot samples for nearest, linear, and sharpen/bicubic if added.

## Current Default Recommendation

Temporary engineering default: `3200x1800 @ 60fps, linear scale`.

Reason:

- It reached 59.885fps on the iMac static scaled renderer.
- It had the best measured HEVC encode latency among these short local Plan C encode runs.
- Text quality is still unverified, so this is not a user-facing default yet.

Fallback candidate: `2560x1440 @ 60fps, nearest scale` for exact 2x integer scaling once text screenshots are available.
