# receiver-windows

iMac-side Windows receiver.

First target:

1. fullscreen window
2. synthetic 5K60 local renderer benchmark
3. network receive
4. decode
5. render
6. HUD

## Plan A synthetic renderer

The first implemented target is a local D3D11 synthetic renderer. It does not receive network frames or decode video yet.

Build on Windows:

```powershell
cmake -S apps/receiver-windows -B apps/receiver-windows/build -G "Visual Studio 17 2022" -A x64
cmake --build apps/receiver-windows/build --config Release
```

Run the 5K60 receiver-side benchmark:

```powershell
mkdir benchmarks\runs\YYYY-MM-DD_HHMM_plan_a_synthetic_5k60
apps\receiver-windows\build\Release\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --csv benchmarks\runs\YYYY-MM-DD_HHMM_plan_a_synthetic_5k60\receiver_stats.csv
```

Optional ceiling run without display vsync:

```powershell
apps\receiver-windows\build\Release\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 30 --fullscreen --no-vsync --static-frame
```

Isolation modes:

```powershell
# Upload a single static 5K frame once, then present it for 60 seconds.
apps\receiver-windows\build\Release\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --static-frame

# Render a generated shader pattern without CPU frame fill or texture upload.
apps\receiver-windows\build\Release\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 60 --fullscreen --gpu-pattern

# Measure an unthrottled present ceiling without vsync.
apps\receiver-windows\build\Release\ibridge-receiver.exe --synthetic --resolution 5120x2880 --fps 60 --duration 30 --fullscreen --gpu-pattern --no-vsync --uncapped
```

The first acceptance run should keep vsync enabled because iBridge is display-facing software.
