# Prompt 03 — Plan B: 5K60 Practical Compressed Mode

Prerequisite:
Plan A has a measured bottleneck or an explicit pending hardware blocker.

Goal:
Try to make 5120×2880 @ 60fps usable through hardware encoding/decoding.

Tasks:

1. macOS Primary:
   - Create/capture a 5120×2880 source if possible.
   - Use VideoToolbox H.264 low latency first.
   - Add HEVC path second.
   - Stamp every frame with capture/encode timestamps.

2. Windows Receiver:
   - Decode H.264 first.
   - Add HEVC if initial pipeline works.
   - Render fullscreen with D3D11/SDL bootstrap.
   - Show actual fps, dropped frames, decode time, render time.

3. Transport:
   - Start with TCP for first image only if necessary.
   - Move to UDP/low-latency transport for real test.
   - Include packet/frame ids.

4. Quality:
   - Test code editor screen, terminal scroll, mouse movement.
   - Implement local cursor overlay experiment if streamed cursor feels laggy.

Verification:
- At least one 5K compressed stream test result is logged.
- If 5K60 fails, failure reason is classified: encode, transport, decode, render, power/thermal, or virtual display.
- Downshift to Plan C only after that classification.
