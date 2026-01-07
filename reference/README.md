# iBridge Reference Clones

This directory is for local, ignored third-party source clones used to study
capture, encode, transport, decode, and render techniques relevant to iBridge.

Do not vendor or copy implementation code from these projects into iBridge
without a separate license and clean-room review. Use them as design references
and record any technical conclusions in project docs with source URLs.

## Clone Set

The ignored local clone set currently has 39 repositories.

| Category | Directory | Repository | Commit | Why it is relevant |
|---|---|---|---|---|
| End-to-end host | `sunshine` | `https://github.com/LizardByte/Sunshine.git` | `33bdb01` | Mature low-latency game-streaming host with macOS VideoToolbox support and Moonlight-compatible protocol decisions. |
| End-to-end client | `moonlight-qt` | `https://github.com/moonlight-stream/moonlight-qt.git` | `9cbba10` | Cross-platform receiver/client with Windows/macOS hardware decode, frame pacing, renderer, and streaming stats. |
| Capture/encode app | `obs-studio` | `https://github.com/obsproject/obs-studio.git` | `5dacbb6` | Mature ScreenCaptureKit/macOS capture and Apple VideoToolbox encoder integration patterns. |
| Swift VT wrapper | `Transcoding` | `https://github.com/finnvoor/Transcoding.git` | `3af0f4f` | Small Swift package focused on VideoToolbox encode/decode, Annex-B adaptation, and ultra-low-latency presets. |
| ScreenCaptureKit sample | `CapturingScreenContentInMacOS` | `https://github.com/Fidetro/CapturingScreenContentInMacOS.git` | `083aae1` | Mirror of Apple's ScreenCaptureKit sample for high-performance macOS display/window capture flow. |
| Swift VT sample | `VideoToolboxH265Encoder` | `https://github.com/zf3/VideoToolboxH265Encoder.git` | `fcc2726` | Minimal Swift VideoToolbox HEVC/H.264 encoder sample. |
| Codec/hwaccel framework | `FFmpeg` | `https://github.com/FFmpeg/FFmpeg.git` | `b286748` | Reference implementation for VideoToolbox encoder/hwaccel plumbing and codec bitstream handling. |
| H.264 codec | `openh264` | `https://github.com/cisco/openh264.git` | `e3f5b10` | Open H.264 encoder/decoder with API and console samples; useful for elementary stream and decoder expectations. |
| H.264 encoder | `x264` | `https://github.com/mirror/x264.git` | `c24e06c` | Mature H.264 encoder with `zerolatency`, VBV, B-frame, keyframe, and lookahead tradeoffs. |
| HEVC encoder | `x265` | `https://github.com/videolan/x265.git` | `4191822` | Mature HEVC encoder with low-latency presets, GOP, threading, and rate-control options. |
| AV1 codec | `SVT-AV1` | `https://github.com/AOMediaCodec/SVT-AV1.git` | `3fc8691` | AV1 encoder/decoder implementation with real-time and speed preset tuning surface. |
| AV1 decoder | `dav1d` | `https://github.com/videolan/dav1d.git` | `1cfad6d` | Fast AV1 decoder reference focused on desktop performance and correctness. |
| VP8/VP9 codec | `libvpx` | `https://github.com/webmproject/libvpx.git` | `e9efe03` | VP8/VP9 encoder/decoder reference with real-time rate-control examples. |
| AV1 encoder | `rav1e` | `https://github.com/xiph/rav1e.git` | `564ae3b` | Rust AV1 encoder useful for speed presets, lookahead, and encode/decode tests. |
| VVC encoder | `vvenc` | `https://github.com/fraunhoferhhi/vvenc.git` | `6f76748` | VVC encoder reference for modern codec complexity and low-delay configuration ideas. |
| VVC decoder | `vvdec` | `https://github.com/fraunhoferhhi/vvdec.git` | `fd3a5e9` | VVC decoder reference for parser/decoder architecture. |
| AV1 reference | `aom` | `https://aomedia.googlesource.com/aom` | `5e4b07d` | Official AV1 reference implementation from AOMedia; cloned from googlesource because the canonical source is not a GitHub repo. |
| NVIDIA SDK | `video-sdk-samples` | `https://github.com/NVIDIA/video-sdk-samples.git` | `aa3544d` | NVENC/NVDEC samples including DXGI output duplication and D3D11 encode paths. |
| AMD SDK | `AMF` | `https://github.com/GPUOpen-LibrariesAndSDKs/AMF.git` | `eadd008` | AMD AMF encode/decode/display capture API docs and samples; large but relevant for hardware pipelines. |
| Intel SDK | `oneVPL` | `https://github.com/oneapi-src/oneVPL.git` | `778a66d` | Intel oneVPL encode/decode examples, DX11 surface sharing, and low-latency dispatcher tests. |
| Windows samples | `Windows-classic-samples` | `https://github.com/microsoft/Windows-classic-samples.git` | `77f217b` | Microsoft Media Foundation, DX11 video renderer, and DXGI desktop duplication samples. |
| Windows filters | `LAVFilters` | `https://github.com/Nevcairiel/LAVFilters.git` | `a9e6864` | Production Windows DirectShow/FFmpeg decoder stack with D3D11VA/DXVA paths and Annex-B parsers. |
| Media framework | `gstreamer` | `https://github.com/gstreamer/gstreamer.git` | `9fc023c` | Large multimedia pipeline framework with RTP/WebRTC, hardware plugins, and encoder/decoder elements. |
| WebRTC desktop stream | `selkies-gstreamer` | `https://github.com/selkies-project/selkies-gstreamer.git` | `210e2e8` | Low-latency accelerated remote desktop streaming over GStreamer/WebRTC. |
| WebRTC stack | `pion-webrtc` | `https://github.com/pion/webrtc.git` | `9654161` | Go WebRTC stack useful for RTP receiver, sample builder, H.264/H.265 writers, and stats. |
| WebRTC stack | `libdatachannel` | `https://github.com/paullouisageneau/libdatachannel.git` | `ca9a141` | C/C++ WebRTC data/media stack with H.264/H.265/AV1 RTP packetizers/depacketizers. |
| Transport | `srt` | `https://github.com/Haivision/srt.git` | `8e68635` | Secure Reliable Transport reference for low-latency unreliable-network media delivery. |
| Streaming server | `srs` | `https://github.com/ossrs/srs.git` | `3663a8e` | Realtime streaming server with WebRTC/SRT/RTP queues and packet handling. |
| Codec packaging | `libavif` | `https://github.com/AOMediaCodec/libavif.git` | `4b817bb` | AV1 image/sequence packaging reference; secondary relevance for AV1 codec integration. |
| Codec packaging | `libheif` | `https://github.com/strukturag/libheif.git` | `7dc8570` | HEIF/AVIF/HEVC integration reference; secondary relevance for codec wrapper patterns. |
| Transcoding app | `HandBrake` | `https://github.com/HandBrake/HandBrake.git` | `8587e82` | Mature transcoding app with codec integration and hardware encode/decode option surfaces. |
| macOS virtual display | `DeskPad` | `https://github.com/Stengo/DeskPad.git` | `c3349f0` | Creates a virtual monitor and mirrors it into an app window with `CGVirtualDisplay` and `CGDisplayStream`. |
| macOS virtual display | `FreeDisplay` | `https://github.com/huberdf/FreeDisplay.git` | `07ba072` | Virtual-display management app with lessons around WindowServer blocking, HiDPI modes, and stale display cleanup. |
| macOS virtual display | `SimpleDisplay` | `https://github.com/SamuelRioTz/SimpleDisplay.git` | `fcfcdce` | Lightweight virtual monitor/display management app using a small Objective-C bridge. |
| macOS virtual display | `node-mac-virtual-display` | `https://github.com/enfp-dev-studio/node-mac-virtual-display.git` | `83bf871` | Node/native bridge for `CGVirtualDisplay`, display settings, HiDPI, and mirroring behavior. |
| macOS display tool | `BetterDisplay` | `https://github.com/waydabber/BetterDisplay.git` | `d5bc059` | Display/HiDPI/virtual-screen reference and historical context for macOS display manipulation. |
| Remote desktop | `rustdesk` | `https://github.com/rustdesk/rustdesk.git` | `0d40cf2` | Cross-platform remote desktop app with macOS capture, hwcodec/VRAM encode-decode selection, and adaptive video paths. |
| WebRTC second screen | `deskreen` | `https://github.com/pavlobu/deskreen.git` | `7449628` | Turns browsers/devices into secondary screens via Electron/WebRTC; useful as a product/reference comparison. |
| WebRTC screen sharing | `screencat` | `https://github.com/max-mapper/screencat.git` | `5f5c2a9` | Electron/WebRTC screen sharing and remote-control reference. |

## Current Local Clone Command

Run selected commands from the repository root. The clone bodies are intentionally
ignored by Git.

```bash
mkdir -p reference
git clone --depth 1 https://github.com/LizardByte/Sunshine.git reference/sunshine
git clone --depth 1 https://github.com/moonlight-stream/moonlight-qt.git reference/moonlight-qt
git clone --depth 1 https://github.com/obsproject/obs-studio.git reference/obs-studio
git clone --depth 1 https://github.com/finnvoor/Transcoding.git reference/Transcoding
git clone --depth 1 https://github.com/Fidetro/CapturingScreenContentInMacOS.git reference/CapturingScreenContentInMacOS
git clone --depth 1 https://github.com/zf3/VideoToolboxH265Encoder.git reference/VideoToolboxH265Encoder
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git reference/FFmpeg
```

## First Analysis Targets

- VideoToolbox encoder creation flags, encoder ID choice, realtime/latency
  properties, keyframe cadence, and Annex-B/parameter-set handling.
- Capture path: whether frames stay GPU-resident or round-trip through CPU
  memory before encode.
- Receiver path: Windows hardware decode API choice, decoded-frame upload
  strategy, vsync/frame pacing, and latency stats.
- Transport path: whether TCP is avoided for live frames, packet loss policy,
  frame dropping policy, and jitter buffering.

## First-Pass Source Map

### macOS Capture

- `reference/CapturingScreenContentInMacOS/CaptureSample/CaptureEngine.swift`
  shows a compact ScreenCaptureKit flow around `SCStream`, `SCStreamOutput`,
  sample-buffer delivery, and frame-status filtering.
- `reference/obs-studio/plugins/mac-capture/mac-sck-video-capture.m`
  shows production ScreenCaptureKit display/window capture setup, including
  display pixel sizing from `CGDisplayModeGetPixelWidth/Height` before creating
  `SCStream`.
- `reference/obs-studio/plugins/mac-capture/mac-sck-common.m`
  handles `SCStreamFrameInfoScaleFactor`, `SCStreamFrameInfoContentRect`, and
  `SCStreamFrameInfoContentScale`; these are important for Retina-accurate
  capture and text clarity.
- `reference/obs-studio/plugins/mac-capture/mac-display-capture.m`
  is the older `CGDisplayStream` fallback path and is useful if
  ScreenCaptureKit introduces latency or frame-status issues.
- `reference/DeskPad/DeskPad/Frontend/Screen/ScreenViewController.swift`
  creates a virtual display, starts `CGDisplayStream` against that display ID,
  and assigns the returned IOSurface to a layer. This is a key Mac-Mac reference
  because it proves a local "virtual monitor as source" model before network
  transport enters the picture.
- `reference/rustdesk/libs/scrap/src/quartz` is the RustDesk macOS capture
  reference area for cross-platform remote desktop capture behavior.

### macOS Virtual Display

- `reference/DeskPad/DeskPad/CGVirtualDisplayPrivate.h` shows the private
  `CGVirtualDisplay`, `CGVirtualDisplayDescriptor`, `CGVirtualDisplaySettings`,
  and `CGVirtualDisplayMode` declarations used by several virtual display apps.
- `reference/DeskPad/DeskPad/Frontend/Screen/ScreenViewController.swift`
  applies multiple 60 Hz HiDPI-friendly modes, including 5120-wide modes.
- `reference/FreeDisplay/FreeDisplay/Services/VirtualDisplayService.swift`
  keeps strong references to active displays, recreates configured displays
  after startup, detects stale virtual displays, and records practical
  WindowServer constraints.
- `reference/FreeDisplay/FreeDisplay/Services/CGHelpers.swift` wraps blocking
  CoreGraphics/WindowServer calls with a timeout. This is directly relevant if
  iBridge experiments with virtual displays on older iMac macOS installs.
- `reference/SimpleDisplay/Sources/VirtualDisplayBridge/VirtualDisplayWrapper.m`
  is a compact Objective-C bridge with runtime private-API availability checks.
- `reference/node-mac-virtual-display/src/virtual_display.mm` is a compact
  native bridge for creating virtual displays, adding HiDPI/low-res paired
  modes, avoiding unintended main-display changes, and managing mirror mode.

### macOS VideoToolbox Encode

- `reference/Transcoding/Sources/Transcoding/VideoEncoder+Config.swift`
  has an explicit `ultraLowLatency` preset using speed priority, realtime mode,
  and low-latency rate control. It also exposes many VT properties missing from
  iBridge's current focused probe, including `MaxFrameDelayCount`,
  `MoreFramesBeforeStart`, `MoreFramesAfterEnd`, `ConstantBitRate`,
  `DataRateLimits`, and `EncoderID`.
- `reference/Transcoding/Sources/Transcoding/VideoEncoderAnnexBAdaptor.swift`
  is a small Swift reference for converting VideoToolbox AVCC/HVCC sample
  buffers into Annex-B byte streams with SPS/PPS or VPS/SPS/PPS before sync
  frames.
- `reference/VideoToolboxH265Encoder/VideoToolboxCompression/ViewController.swift`
  is an older but simple Swift sample for HEVC/H.264 session creation,
  parameter-set extraction, and NAL length conversion.
- `reference/obs-studio/plugins/mac-videotoolbox/encoder.c`
  is the most mature direct VT encoder reference: encoder ID selection,
  Apple Silicon CRF handling, bitrate limits, profile/color metadata, and
  explicit VideoToolbox error logging.
- `reference/FFmpeg/libavcodec/videotoolboxenc.c`
  is useful for checking which VT properties are treated as optional,
  platform-specific, or hardware-frame compatible.
- `reference/sunshine/src/video.cpp` shows low-delay encoder strategy at the
  streaming-host level: no B-frames, low-delay flags, on-demand IDR when
  available, limited reference frames, and hardware-device contexts.

### Windows Receiver / Decode / Render

- `reference/moonlight-qt/app/streaming/video/ffmpeg-renderers/d3d11va.cpp`
  is the highest-priority Windows receiver reference. It uses FFmpeg with
  D3D11VA, shared fences/textures, decode/render device separation, DWM/MMCSS,
  and D3D11 render paths.
- `reference/moonlight-qt/app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp`
  shows a real frame pacer with bounded queues and frame dropping before
  latency accumulates.
- `reference/moonlight-qt/app/streaming/video/ffmpeg.cpp` is the entry point
  that ties stream decode, renderer selection, and stats together.
- `reference/sunshine/src/platform/windows/display_vram.cpp` is host-side, but
  it is very useful for D3D11 texture sharing, NV12/P010 conversion, and avoiding
  full CPU readback/upload loops.
- `reference/LAVFilters/decoder/LAVVideo/decoders/d3d11va.cpp` and
  `reference/LAVFilters/decoder/LAVVideo/decoders/dxva2dec.cpp` are production
  Windows hardware decode references.
- `reference/LAVFilters/decoder/LAVVideo/parsers/AnnexBConverter.cpp`,
  `H264SequenceParser.cpp`, and `HEVCSequenceParser.cpp` are useful for
  robust stream parser behavior before decode.
- `reference/Windows-classic-samples/Samples/DX11VideoRenderer/cpp` is a
  Microsoft DX11 Media Foundation renderer sample.
- `reference/Windows-classic-samples/Samples/MediaFoundationTransformDecoder/cpp`
  is a Microsoft MFT decoder sample, useful for receiver-side decode plumbing.
- `reference/Windows-classic-samples/Samples/DXGIDesktopDuplication/cpp` is
  capture-side, but useful for understanding DXGI frame acquisition and dirty
  desktop updates.

### Transport / Frame Loss Strategy

- `reference/sunshine/src/stream.cpp` is the main transport reference. It sends
  video over UDP/RTP-style packets, inserts per-frame headers, computes FEC
  blocks, rate-controls packet bursts within a frame, and logs frame processing,
  FEC, batch-send, and overall network latency.
- `reference/sunshine/src/rtsp.cpp` captures stream negotiation details such as
  packet size and client feedback/control setup.
- `reference/moonlight-qt/moonlight-common-c` should be searched next for the
  receiving side of packet reassembly, loss stats, and IDR requests.
- `reference/libdatachannel/src/h264rtppacketizer.cpp`,
  `h265rtppacketizer.cpp`, `av1rtppacketizer.cpp`, and matching depacketizers
  are compact C++ references for codec-specific RTP payload splitting.
- `reference/pion-webrtc/pkg/media/samplebuilder/samplebuilder.go` and
  `pkg/media/h264writer/h264writer.go` are useful receiving-side Go references
  for rebuilding media samples from RTP packets.
- `reference/selkies-gstreamer/src/selkies/webrtc/jitterbuffer.py` and
  `media_pipeline.py` are high-level references for desktop-stream WebRTC
  jitter buffering and GStreamer pipeline assembly.
- `reference/srt/apps/transmitmedia.cpp` is a simple low-latency transport
  utility reference, though SRT may be heavier than iBridge needs.

### Hardware Vendor SDKs

- `reference/video-sdk-samples/nvEncDXGIOutputDuplicationSample` is a close
  analogue for GPU capture plus hardware encode on Windows/NVIDIA.
- `reference/video-sdk-samples/nvEncBroadcastSample/nvEnc/nvCodec` shows
  D3D11 NVENC wrapper classes and bitstream buffer handling.
- `reference/AMF/amf/doc/AMF_Video_Encode_API.md`,
  `AMF_Video_Encode_HEVC_API.md`, `AMF_Video_Encode_AV1_API.md`, and
  `AMF_Video_Decode_API.md` are AMD hardware encoder/decoder API references.
- `reference/AMF/amf/doc/AMF_Display_Capture_API.md` is relevant to
  capture-to-encode flow, even though iBridge primary capture is macOS first.
- `reference/oneVPL/examples/api2x/hello-decode`,
  `hello-encode`, `hello-transcode`, and `hello-sharing-dx11` are compact Intel
  encode/decode and DX11 surface-sharing examples.

### Codec Implementations

- `reference/x264/x264.c`, `reference/x264/encoder/encoder.c`, and
  `reference/x264/doc/ratecontrol.txt` are useful for H.264 zerolatency,
  lookahead, B-frame, VBV, and keyframe policy.
- `reference/x265/doc/reST/presets.rst`, `cli.rst`, `threading.rst`, and
  `reference/x265/source/common/param.cpp` are useful for HEVC low-latency
  preset and threading tradeoffs.
- `reference/openh264/codec/api/wels/codec_api.h`,
  `codec/console/enc/src/welsenc.cpp`, and `codec/console/dec/src/h264dec.cpp`
  show a smaller H.264 encoder/decoder API surface.
- `reference/aom/examples/svc_encoder_rtc.cc`,
  `reference/aom/av1/ratectrl_rtc.cc`, and
  `reference/aom/av1/encoder/speed_features.c` are useful for real-time AV1
  rate-control and speed-feature references.
- `reference/libvpx/examples/vpx_temporal_svc_encoder.c` and
  `reference/libvpx/vpx/internal/vpx_ratectrl_rtc.h` are useful for VPx
  real-time and scalable-video coding patterns.
- `reference/dav1d` is primarily decoder-performance study material, while
  `reference/SVT-AV1`, `reference/rav1e`, `reference/vvenc`, and
  `reference/vvdec` are broader codec-complexity references rather than likely
  direct dependencies for iBridge.

### Mac-Mac / Remote Desktop Product References

- `reference/rustdesk/libs/scrap/src/common/hwcodec.rs` and `vram.rs` are
  useful for hardware codec feature detection, fallback selection, H.264/H.265
  encode/decode configuration, and VRAM-vs-RAM paths.
- `reference/rustdesk/libs/scrap/src/common/aom.rs` shows screen-content AV1
  low-latency settings, including disabling expensive tools and selecting
  `AOM_CONTENT_SCREEN`.
- `reference/deskreen` and `reference/screencat` are useful product references
  for "secondary display over WebRTC" UX and signaling, though their Electron
  architecture is probably not the right low-level implementation target for
  5K/60 iBridge.

## Immediate iBridge Hypotheses From The References

- The current TCP proof path is useful for correctness but is probably the wrong
  architecture for live display latency. Sunshine's live video path assumes UDP,
  packet pacing, FEC, loss stats, and IDR feedback.
- The receiver should not accumulate frames. Moonlight's pacer keeps queues
  tiny and drops frames to preserve latency.
- The receiver decode path should target GPU-native frames earlier. Moonlight's
  D3D11VA path and Sunshine's D3D11 texture-sharing paths are more relevant
  than CPU upload loops.
- iBridge's VideoToolbox probe should expand from average encode time into a
  matrix of encoder properties: B-frame/reordering off, max frame delay, bitrate
  mode, data-rate limits, speed priority, realtime, encoder ID, and Annex-B
  parameter-set behavior.
- For the next implementation spike, the strongest reference-backed direction
  is receiver-first D3D11VA decode/render plus bounded frame pacing, in parallel
  with a VT property matrix. UDP/FEC should follow once decode/render no longer
  hides the bottleneck.
- The project should not overfit to macOS Primary -> Windows Receiver. If the
  iMac can return to macOS, Mac-Mac should be treated as a first-class route:
  virtual display source on the primary Mac, hardware encode/decode through
  VideoToolbox, and Metal/IOSurface presentation on the receiver may offer a
  cleaner pipeline than Media Foundation plus D3D11 on Windows.
