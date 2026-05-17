# Encode Strategy Matrix

- Duration per case: `3` seconds
- Forced encoder: `com.apple.videotoolbox.videoencoder.ave.hevc`
- Codec: HEVC
- Bitrate/DataRateLimits: `120 Mbps`
- Main table: `summary.csv`
- Encoder list: `video_encoders.txt`
- Tile approximation: `tile_2x2_5k60/summary.md`
- Targeted follow-up: `targeted/sck_5k60.txt`

## What This Tests

- BGRA synthetic input versus NV12 synthetic input.
- Static-screen frame skipping with 5K logical output.
- 5K45 and 5K30 refresh-rate fallback.
- 2x2 parallel encoder sessions approximating tiled 5K.
- ScreenCaptureKit/IOSurface capture path when Screen Recording permission allows it.

## Highlights

| Case | Avg encode ms | P95 encode ms | Result |
| --- | ---: | ---: | --- |
| synthetic NV12 3840x2160@60 | 11.557 | 11.906 | Strongest single-session 4K60 signal. |
| ScreenCaptureKit 3840x2160@60 | 16.363 | 18.412 | Real capture works, but p95 is slightly above 60Hz frame budget. |
| synthetic NV12 4096x2304@60 | 12.898 | 13.245 | Strong high-detail 60Hz candidate. |
| synthetic NV12 5120x2880@60 | 222.716 | 234.220 | 5K60 single-session HEVC still fails. |
| ScreenCaptureKit 5120x2880@60 | 302.354 | 360.042 | Real 5K60 capture+encode also fails. |
| synthetic NV12 5120x2880@30 | 19.296 | 19.824 | Fits 30Hz frame budget, not 60Hz. |
| tile 2x2 5K60 approximation | 6.496-9.528 | 10.568-11.254 | Per-tile sessions fit 60Hz; end-to-end tiled recomposition is still unproven. |
