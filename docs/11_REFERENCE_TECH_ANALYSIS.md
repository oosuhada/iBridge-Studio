# Reference Technology Analysis

Date: 2026-05-15

Branch: `feat/plan-a-5k60-benchmark`

This document turns the `reference/` clone set into concrete iBridge
engineering direction. Most references are ignored local clones; BetterDisplay
is intentionally tracked as a Git submodule so virtual-display/HiDPI behavior is
available across machines. It does not copy code from third-party projects.

## Executive Read

- The strongest current signal is still Plan C, not raw 5K frames: forced
  `com.apple.videotoolbox.videoencoder.ave.hevc` without low-latency rate
  control fits a 60 Hz encode budget at 3200x1800 on the MacBook Pro.
- The reference projects show that the next bottlenecks are architectural:
  capture/encode must stay close to GPU surfaces, transport must not be a
  blocking TCP proof path, and the receiver must decode/render with bounded
  queues rather than accumulating frames.
- Mac-to-Mac should be kept as a first-class route. If the iMac can boot macOS,
  the receiver side can avoid Media Foundation/D3D11 complexity. The virtual
  display source is most likely a feature of the modern Primary Mac, not
  necessarily the old iMac.
- Remote macOS installation or boot-volume switching is a machine-state risk,
  not a coding task. It should only be attempted after confirming an existing
  macOS volume, Boot Camp control-panel visibility, and a recovery path.

## Reference Findings By Pipeline Stage

### 1. Virtual Display Source

Primary references:

- `reference/DeskPad/DeskPad/CGVirtualDisplayPrivate.h`
- `reference/DeskPad/DeskPad/Frontend/Screen/ScreenViewController.swift`
- `reference/FreeDisplay/docs/lessons/coregraphics.md`
- `reference/SimpleDisplay/Sources/VirtualDisplayBridge/VirtualDisplayWrapper.m`
- `reference/node-mac-virtual-display/src/virtual_display.mm`

What matters:

- DeskPad creates `CGVirtualDisplay`, sets 60 Hz modes, enables HiDPI, and
  captures that virtual display with `CGDisplayStream`.
- FreeDisplay records practical constraints that are more useful than API
  optimism: `CGVirtualDisplay` is private SPI, `vendorID` cannot be zero,
  creation must happen on the main thread, and WindowServer calls can block.
- SimpleDisplay and node-mac-virtual-display are compact bridge references for
  runtime availability checks and mode construction.

iBridge implication:

- A strong Mac-Mac spike is possible before touching the iMac: create a virtual
  display on the MBP/MBA, capture that display, encode it with the current
  forced HEVC path, then decode locally or on another Mac.
- Private API risk is real. This path is suitable for a local/private tool
  prototype, but it should be isolated behind an experiment flag and not mixed
  into the clean Windows receiver path.

### 2. macOS Capture And VideoToolbox Encode

Primary references:

- `reference/CapturingScreenContentInMacOS/CaptureSample/CaptureEngine.swift`
- `reference/obs-studio/plugins/mac-capture/mac-sck-video-capture.m`
- `reference/obs-studio/plugins/mac-capture/mac-sck-common.m`
- `reference/Transcoding/Sources/Transcoding/VideoEncoder+Config.swift`
- `reference/Transcoding/Sources/Transcoding/VideoEncoderAnnexBAdaptor.swift`
- `reference/obs-studio/plugins/mac-videotoolbox/encoder.c`
- `reference/FFmpeg/libavcodec/videotoolboxenc.c`

What matters:

- ScreenCaptureKit references focus on frame status, Retina content scale, and
  pixel sizing. This is where text clarity will be won or lost.
- Transcoding exposes more VT properties than iBridge currently probes:
  `AllowFrameReordering`, `AllowOpenGOP`, `DataRateLimits`,
  `PrioritizeEncodingSpeedOverQuality`, `MaxFrameDelayCount`, `RealTime`,
  `EncoderID`, and low-latency rate control.
- Transcoding also has concise Annex-B adapters that insert H.264 SPS/PPS or
  HEVC VPS/SPS/PPS before sync frames and convert length-prefixed VT output to
  start-code delimited elementary streams.
- OBS and FFmpeg show the production pattern: treat VT properties as
  platform-dependent, log unsupported properties clearly, and keep encoder ID
  selection observable.

iBridge implication:

- The next Primary work should not be another broad speed check. It should be a
  VT property matrix with explicit columns for encoder ID, low-latency RC,
  speed priority, realtime, reordering, open GOP, frame delay, data-rate limits,
  keyframe cadence, and output format.
- iBridge should add a clean elementary-stream/Annex-B option before live
  compressed receiver work gets complicated. This helps both Windows Media
  Foundation and macOS VideoToolbox decode paths.

### 3. Transport And Frame Loss

Primary references:

- `reference/sunshine/src/stream.cpp`
- `reference/libdatachannel/src/h264rtppacketizer.cpp`
- `reference/libdatachannel/src/h265rtppacketizer.cpp`
- `reference/pion-webrtc/pkg/media/samplebuilder/samplebuilder.go`
- `reference/selkies-gstreamer/src/selkies/webrtc/rtp.py`

What matters:

- Sunshine's live video path assumes UDP/RTP-style packets, frame headers,
  IDR feedback, loss stats, FEC, packet pacing, and per-stage latency logging.
- libdatachannel gives compact H.264/H.265/AV1 packetizer/depacketizer models.
- Pion's sample builder is useful receiver-side logic for reconstructing media
  samples from RTP sequence numbers with bounded lateness.

iBridge implication:

- TCP is still valuable as a correctness harness, but it is not the final live
  display transport. Once decode/render works, the next protocol step should be
  UDP with sequence numbers, frame IDs, EOF/SOF flags, loss counters, and an IDR
  request mechanism.
- Do not start with full WebRTC unless NAT traversal becomes the main product
  requirement. For same-room Mac/iMac display use, a smaller RTP-like protocol
  is more reviewable.

### 4. Windows Receiver Decode And Render

Primary references:

- `reference/moonlight-qt/app/streaming/video/ffmpeg-renderers/d3d11va.cpp`
- `reference/moonlight-qt/app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp`
- `reference/LAVFilters/decoder/LAVVideo/decoders/d3d11va.cpp`
- `reference/LAVFilters/decoder/LAVVideo/parsers/AnnexBConverter.cpp`
- `reference/Windows-classic-samples/Samples/DX11VideoRenderer/cpp`
- `reference/Windows-classic-samples/Samples/MediaFoundationTransformDecoder/cpp`

What matters:

- Moonlight's D3D11VA renderer keeps decoded frames GPU-native, handles shared
  textures/fences, and has explicit renderer/device fallback logic.
- Moonlight's pacer caps queues and drops frames. The important design point is
  that a live display must preserve recency over completeness.
- Microsoft's DX11 renderer sample gives a Media Foundation presentation
  scheduler, while LAVFilters provides production parser and D3D11VA behavior.

iBridge implication:

- The Windows path should move from "upload frames and present" toward
  "decode to GPU surface and present with bounded queues".
- The immediate receiver target should be an offline HEVC/H.264 Annex-B decode
  smoke, then the same decode path fed by protocol v0 TCP. Only after this path
  is visible should UDP/FEC become the main implementation work.

### 5. Codec Libraries

Primary references:

- `reference/x264`, `reference/x265`, `reference/openh264`
- `reference/aom`, `reference/libvpx`, `reference/SVT-AV1`, `reference/dav1d`
- `reference/rustdesk/libs/scrap/src/common/aom.rs`

What matters:

- These repos are useful for codec vocabulary and tradeoffs: B-frames,
  lookahead, VBV, GOP/keyframe cadence, realtime/screen-content modes, and
  decoder expectations.
- They are not likely to replace platform hardware codecs for iBridge. CPU
  software encode of high-resolution 60 Hz desktop frames is the wrong default
  for battery, latency, and thermals.

iBridge implication:

- Keep VideoToolbox on Primary and GPU decode on Receiver as the default.
- Use AV1/VPx study only if HEVC licensing/compatibility or image quality
  becomes a product blocker.

## Route Comparison

| Route | Strength | Risk | Best next test |
|---|---|---|---|
| MBP/MBA Primary -> Windows iMac Receiver | Uses current iMac Windows install; can proceed through Tailscale/RDP once receiver is started. | Media Foundation/D3D11 decode/render complexity; Windows receiver port and SSH auth are currently blocked. | Run offline HEVC/H.264 decode smoke on iMac, then protocol v0 TCP compressed decode. |
| MBP/MBA Primary -> macOS iMac Receiver | Cleaner codec stack through VideoToolbox on both ends; avoids Windows D3D11VA learning curve. | Requires iMac macOS boot/install state; old iMac official OS ceiling matters; remote OS install is unsafe without physical access. | Confirm existing macOS volume and remote access first; then build a minimal macOS receiver. |
| Local Mac virtual display source | Can be developed now without iMac; matches "external display" UX better than mirroring a real display. | Uses private `CGVirtualDisplay` SPI and WindowServer-sensitive behavior. | Local MBP virtual display -> capture -> forced HEVC encode smoke. |
| Custom UDP/RTP transport | Matches mature low-latency streaming references. | Harder to debug until decode/render is stable. | Add frame IDs/loss stats/IDR request after TCP decode/render passes. |

## Recommended Immediate Work

1. Keep most reference clones Git-disconnected and ignored. Treat
   `reference/BetterDisplay` as the current submodule exception for shared
   HiDPI/virtual-display research across MacBook Pro, MacBook Air, and Codex
   Cloud.
2. Run the Windows iMac inventory script from RDP or an existing remote shell.
3. Extend the Primary benchmark into a VT property matrix rather than only
   comparing machines.
4. Add an Annex-B output/decode fixture path so both Windows and macOS receiver
   experiments consume the same elementary stream.
5. Add a local macOS virtual-display smoke app/flag only after deciding to
   accept private SPI risk for prototype experiments.
