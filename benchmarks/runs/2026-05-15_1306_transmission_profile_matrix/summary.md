# Transmission Profile Matrix

- Device profile: `m1air`
- Profile set: `air`
- Duration per case: `30` seconds
- Codec: HEVC
- Forced encoder: `com.apple.videotoolbox.videoencoder.ave.hevc`
- Summary table: `summary.csv`
- Encoder list: `video_encoders.txt`
- Sanitized system profile: `system_profile_sanitized.txt`

## Interpretation

This matrix measures sender-side encode viability only. It intentionally does not
claim receiver decode/render success. Use it to choose which capture, transport,
and bitrate profile should be tried before building OS-specific receiver decode
paths.

## Profile intent

- `m1max_wired_full_5k60_tiled_hevc`: best current full-resolution M1 Max path.
- `m1max_wired_high_detail_4096_60_hevc`: high-detail single-stream fallback.
- `wireless_balanced_3200_60_hevc`: first wireless default candidate.
- `m1air_*`: Air ceiling probes; results must be collected on the Air.
