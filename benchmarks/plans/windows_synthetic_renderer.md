# Windows Synthetic 5K60 Renderer Plan

Prompt: `prompts/02_PLAN_A_5K60_FIRST_SPIKE.md`

## Goal

Measure whether the Windows-booted iMac can locally display generated 5120x2880 frames at 60 fps without network, decode, or capture overhead.

This isolates the receiver-side floor:

```text
CPU synthetic frame generation
-> D3D11 texture upload
-> fullscreen draw
-> present
-> per-frame timing CSV
```

## Target Command

```powershell
cmake -S apps/receiver-windows -B apps/receiver-windows/build -G "Visual Studio 17 2022" -A x64
cmake --build apps/receiver-windows/build --config Release
apps\receiver-windows\build\Release\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --csv benchmarks\runs\YYYY-MM-DD_HHMM_plan_a_synthetic_5k60\receiver_stats.csv
```

Use `--no-vsync` only for a separate GPU upload/render ceiling run. The first acceptance run should keep vsync on because the product target is display-like behavior.

## Metrics

Required metrics:

- target fps
- actual fps
- frame budget in ms
- synthetic CPU fill ms
- D3D11 texture upload ms
- draw/present ms
- total frame ms
- missed frames
- p95 total frame ms
- max total frame ms

## Pass Gate

Plan A receiver-side rendering can continue only if:

- actual fps >= 58 for a 60-second 5120x2880 run;
- p95 total frame time <= 16.667 ms;
- missed frames are explained and rare;
- no receiver crash or device loss occurs.

## Fail Gate

Plan A raw/near-raw should move toward Plan B if the iMac cannot locally render synthetic 5K60 without network/decode overhead, especially if:

- actual fps < 55;
- p95 total frame time is consistently above 16.667 ms;
- D3D11 upload/present alone exceeds the frame budget;
- fullscreen 5K mode is unavailable on the Windows iMac.

## Artifacts

Expected run folder:

```text
benchmarks/runs/YYYY-MM-DD_HHMM_plan_a_synthetic_5k60/
├── receiver_stats.csv
├── summary.md
└── screenshots/
```
