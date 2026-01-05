# Prompt 05 — macOS Primary Implementation

Goal:
Build the MacBook-side app that creates/captures the display source, encodes frames, and sends them to the receiver.

Implementation order:

1. `apps/primary-macos` project scaffolding.
2. CLI first, GUI later.
3. Capture a selected display/window with ScreenCaptureKit.
4. Add synthetic frame source for benchmarking.
5. Add VideoToolbox H.264 low-latency encoder.
6. Add HEVC encoder.
7. Add transport client.
8. Add diagnostics CSV output.
9. Add virtual display research spike separately.

Do not block the first pipeline on virtual display perfection. If virtual display is hard, capture an existing screen/window first, then return to virtual display.

Verification:
- primary app can emit frames from synthetic source.
- primary app can encode at least 1440p60 synthetic frames.
- logs include encode latency.
