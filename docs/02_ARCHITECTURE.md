# Architecture — iBridge Software, Not Just Harness

## 1. Product Architecture

```text
MacBook macOS Primary
  Virtual Display / Capture / Encode / Transport
      ↓
LAN or Thunderbolt Bridge
      ↓
iMac Windows Receiver
  Decode / Render / Scale / Fullscreen / HUD
```

The project exists to build the above pipeline. The harness files exist only to keep Codex from drifting, overbuilding, or claiming unverified success.

## 2. Main Components

### 2.1 Primary macOS App

Responsibilities:

- Create or locate a capture surface representing the intended external display workspace.
- Attempt Plan A/Plan B/Plan C in that order.
- Capture frames with timestamps.
- Encode with low-latency settings.
- Send frames over the selected transport.
- Report encode/network stats to receiver and local logs.

Candidate APIs:

- ScreenCaptureKit for capture. [내용 출처 : https://developer.apple.com/documentation/screencapturekit]
- VideoToolbox for hardware encoding. [내용 출처 : https://developer.apple.com/documentation/videotoolbox]
- CGVirtualDisplay/FreeDisplay-style virtual display research for actual extended-display UX. [내용 출처 : https://github.com/huberdf/FreeDisplay]

### 2.2 Windows Receiver App

Responsibilities:

- Accept connection from Primary.
- Decode H.264/HEVC stream.
- Render frames in fullscreen on the iMac 5K panel.
- Apply scaling mode selected by Primary.
- Render cursor overlay separately if implemented.
- Show diagnostics HUD.

Candidate APIs:

- Media Foundation H.264/H.265 path. [내용 출처 : https://learn.microsoft.com/en-us/windows/win32/medfound/h-264-video-decoder]
- FFmpeg fallback for faster codec experimentation. [내용 출처 : https://trac.ffmpeg.org/wiki/HWAccelIntro]
- Direct3D 11 rendering.
- SDL2 only as a bootstrap window/input layer if needed. [내용 출처 : https://wiki.libsdl.org/SDL2/Introduction]

### 2.3 Shared Protocol

Protocol v0 must include:

- magic/version
- session id
- mode id: plan_a_raw, plan_b_5k60_hevc, plan_c_1440p60, etc.
- frame id
- capture timestamp
- encode timestamp
- packet timestamp
- resolution
- fps target
- codec
- color format
- keyframe flag
- payload length

## 3. Plan Selection State Machine

```text
START
  ↓
ENV_PROBE
  ↓
PLAN_A_5K60_RAW_SPIKE
  ├─ pass → CONTINUE_PLAN_A_PRODUCTIZATION
  └─ fail_with_metrics → PLAN_B_5K60_COMPRESSED
        ├─ pass → CONTINUE_PLAN_B_PRODUCTIZATION
        └─ fail_with_metrics → PLAN_C_60HZ_SCALED
              ├─ choose 1440p60 integer
              ├─ compare 4K60
              └─ ship best 60Hz mode
```

Downshift is not a vibe. Downshift requires logs.

## 4. Validation Architecture

Every performance run writes:

```text
benchmarks/runs/YYYY-MM-DD_HHMM_<mode>/
├── metadata.json
├── primary_stats.csv
├── receiver_stats.csv
├── network_stats.txt
├── power_stats.txt
├── screenshots/
└── summary.md
```

## 5. Non-Goals

- Do not implement a landing page before display pipeline works.
- Do not implement cloud sync.
- Do not implement remote internet streaming first.
- Do not claim one-cable charging without hardware proof.
- Do not claim 5K120; the 2015 iMac panel is not a 120Hz target.
