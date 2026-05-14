# Experiment Report — Windows Receiver Isolation Suite

Date: 2026-05-15 01:26 KST
Prompt: `prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md`
Branch: `feat/plan-a-5k60-benchmark`
Hardware: iMac Late 2015 Windows receiver, AMD Radeon R9 M380 2GB
Transport: none
Mode: local synthetic D3D11 render isolation

## Goal

Separate the Windows receiver's 5K60 bottleneck into:

- CPU synthetic frame fill
- full 5120x2880 BGRA texture upload
- D3D11 draw/present on the iMac 5K panel

## Setup

- Windows 10 Pro
- Display mode: 5120x2880 @ 60Hz
- GPU: AMD Radeon R9 M380
- Build: MSVC manual build, `apps\receiver-windows\build\manual\ibridge-receiver.exe`
- Runs launched through Windows Task Scheduler into the active `홍길동` console session.

## Commands

```cmd
ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen
ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --static-frame
ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --gpu-pattern
ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 15 --fullscreen --gpu-pattern --no-vsync --uncapped
```

## Results

| Mode | Actual fps | Avg fill ms | Avg upload ms | Avg draw/present ms | Avg total ms | P95 total ms | Max total ms | Missed frames |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| dynamic_5k60 | 29.979 | 14.4046 | 18.6822 | 0.2685 | 33.3555 | 34.2572 | 96.7510 | 1799 / 1799 |
| static_once_upload_5k60 | 61.749 | 0.0040 | 0.0168 | 16.1721 | 16.1932 | 16.8029 | 83.6277 | 1684 / 3705 |
| gpu_pattern_5k60 | 61.140 | 0.0000 | 0.0000 | 16.3543 | 16.3546 | 16.7943 | 29.8179 | 1724 / 3669 |
| gpu_pattern_uncapped_5k60 | 290.663 | 0.0000 | 0.0000 | 3.4389 | 3.4392 | 9.0732 | 9.2685 | 0 / 4362 |

## Interpretation

The iMac can present 5K frames at approximately 60Hz when CPU fill and full-frame texture upload are removed. The unthrottled GPU-pattern run reached 290 fps, which means the D3D11 shader/draw/present ceiling is not the main blocker.

The dynamic full-frame CPU-filled BGRA path is not viable for Plan A 5K60. It averaged 33.36 ms per frame and only reached 29.98 fps in this suite. The two largest measured costs were:

- CPU synthetic fill: about 14.40 ms
- full 5K BGRA texture upload: about 18.68 ms

The static and GPU-pattern vsync runs report many frames slightly above the strict 16.667 ms budget because vsync pacing jitters around the threshold. They still delivered about 61 fps. The uncapped run confirms the renderer can draw much faster when not synchronized to the display.

## Decision

- [x] Continue Windows Receiver implementation
- [x] Mark dynamic CPU-filled full-frame upload as a failed Plan A receiver path
- [ ] Do not declare all near-raw paths failed yet

Plan A can only continue if future paths avoid per-frame CPU fill and avoid full BGRA upload, for example GPU-side generation, dirty rects, hardware surfaces, or lower-copy formats. For the external display product path, this result pushes the project toward Plan B compressed/hardware-decoded frames unless transport/capture experiments reveal a better low-copy raw path.

## Next

- Add a lightweight HUD or overlay that exposes current mode/fps/timing during receiver runs.
- Add network receive scaffolding after receiver local benchmark metrics are stable.
- Proceed through Prompt 09 review gate before moving to macOS Primary.
