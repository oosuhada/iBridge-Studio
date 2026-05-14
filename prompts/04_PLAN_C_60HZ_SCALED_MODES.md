# Prompt 04 — Plan C: 60Hz Scaled Modes for 5K Panel

Prerequisite:
Plan B 5K60 is not yet usable or needs a practical fallback.

Goal:
Preserve 60Hz interaction quality while using the 5K iMac panel intelligently.

Modes to implement/test in order:

1. 2560×1440 @ 60fps with exact 2x integer scale to 5120×2880.
2. 3840×2160 @ 60fps.
3. 3200×1800 @ 60fps.
4. 4096×2304 @ 60fps.

Tasks:

1. Add mode negotiation to the shared protocol.
2. Add receiver scaling modes:
   - integer/nearest for 1440p;
   - bilinear;
   - bicubic/sharp if available.
3. Add screenshot capture method for text quality comparison.
4. Run the same test scene across all modes.
5. Pick the best default mode based on data, not preference.

Verification:
- `benchmarks/runs/.../mode_comparison.md` exists.
- At least 1440p60 and 4K60 have comparable logs.
- Worklog updated.
