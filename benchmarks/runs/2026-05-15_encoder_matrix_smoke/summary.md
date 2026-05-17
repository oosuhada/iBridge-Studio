# Plan C Encoder Low-Latency Matrix

- Duration per case: `1` seconds
- FPS target: `60`
- Output CSV: `summary.csv`
- Encoder list: `video_encoders.txt`

## Reading Rules

- HEVC is the primary Plan C codec path.
- H.264 results are kept only for modes that produce payloads.
- Treat 5120x2880 H.264 as out of scope for this matrix because prior 5K H.264 produced status -10279 for every frame.
- Use average, p95, max encode latency, failed frames, and achieved payload bytes together; a low average with high p95 still needs follow-up.
