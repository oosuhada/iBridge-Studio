# Windows Receiver Spec

## Goal

The Windows Receiver is the first-class iMac-side app because the user's iMac currently boots Windows.

## Required modes

1. Synthetic fullscreen benchmark.
2. Network receive and render.
3. H.264 decode.
4. HEVC decode.
5. Scaling comparison.
6. HUD overlay.

## CLI shape

```powershell
ibridge-receiver.exe --listen 0.0.0.0:48320 --fullscreen --display 1
ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60
ibridge-receiver.exe --benchmark-render --mode 5k60
```

## HUD fields

- mode
- resolution
- target fps
- actual fps
- decode ms
- render ms
- network jitter
- bitrate
- dropped frames
- scale filter

## Implementation preference

Start with a minimal C++/CMake app. Use D3D11 if possible. Use SDL2 only if it accelerates bootstrap.
