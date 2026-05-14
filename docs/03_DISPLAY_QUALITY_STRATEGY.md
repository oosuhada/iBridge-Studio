# Display Quality Strategy

## 1. Why 5K60 First

The user explicitly wants the engineering attempt to begin at 5K60, not at a low MVP. Therefore, iBridge begins with a Plan A benchmark and only moves down after objective failure.

## 2. Plan A: 5K60 Raw/Near-Raw

### Goal

5120×2880 @ 60fps, minimal compression, minimal latency.

### Expected failure point

Raw 24-bit RGB requires roughly 21.2Gbps before overhead:

```text
5120 * 2880 * 60 * 24 = 21,233,664,000 bits/sec
```

Thunderbolt 2 is a 20Gbps-class link, but here it is a data transport, not a direct display input path. [내용 출처 : https://support.apple.com/en-us/111753]

### What Codex must produce

- A calculation file in `benchmarks/theory/5k60_raw_bandwidth.md`
- A synthetic frame generator test
- A LAN throughput result
- A Thunderbolt Bridge throughput result if hardware is available
- A downshift decision only after logs exist

## 3. Plan B: 5K60 Practical Compressed

### Goal

5120×2880 @ 60fps with HEVC/H.264 hardware encoding.

### Key quality requirements

- Prioritize pointer smoothness and text clarity.
- Prefer dropped quality over dropped frames only if text remains readable.
- Include local cursor overlay experiment.
- Include static-screen mode with higher quality and lower bitrate.

## 4. Plan C: 60Hz Scaled Modes

The user has found sub-60Hz uncomfortable. Plan C is not “bad quality fallback”; it is the likely practical product mode.

### C1 — 2560×1440 @ 60, integer 2x scale

This maps exactly to 5120×2880 by 2x scaling:

```text
2560 × 2 = 5120
1440 × 2 = 2880
```

Expected advantages:

- Smooth 60Hz target.
- Lower bandwidth than 4K/5K.
- Clean integer scaling on the 5K panel.
- UI size comparable to 27-inch 1440p workspace.

### C2 — 3840×2160 @ 60

Expected advantages:

- Common 4K encoder/decoder path.
- More detail than 1440p.

Expected disadvantage:

- Non-integer upscale to 5K panel, possible text blur.

### C3 — 3200×1800 @ 60

Balanced experiment. More pixels than QHD, lighter than 4K.

### C4 — 4096×2304 @ 60

High-detail experiment, likely heavier than C3/C2.

## 5. Comparison Method

Each mode must be tested with:

- static code editor text
- fast mouse movement
- terminal scrolling
- browser scrolling
- dark text on light background
- light text on dark background
- video playback sample

Capture:

- receiver screenshots
- phone slow-motion video if available
- HUD CSV logs
- subjective notes in `benchmarks/runs/.../summary.md`
