# Prompt 06 — Windows Receiver Implementation

Goal:
Build the iMac Windows-side receiver app.

Implementation order:

1. `apps/receiver-windows` project scaffolding.
2. Fullscreen window on target display.
3. Synthetic frame renderer at 5120×2880 @ 60fps local benchmark.
4. Network server receives frame packets.
5. H.264 decode path.
6. HEVC decode path.
7. D3D11 render path.
8. HUD overlay.
9. Scaling modes.

Important:
The receiver must be useful even before macOS Primary is complete. It must support a synthetic/local benchmark mode.

Verification:
- receiver opens fullscreen.
- synthetic mode runs for 60 seconds.
- actual fps is logged.
- if codec path is unavailable, fallback is documented.
