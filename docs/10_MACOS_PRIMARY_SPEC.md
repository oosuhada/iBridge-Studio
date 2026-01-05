# macOS Primary Spec

## Goal

The macOS Primary runs on MacBook and sends a display stream to Windows Receiver.

## Required modes

1. Synthetic source.
2. Existing display/window capture.
3. Virtual display spike.
4. H.264 low latency.
5. HEVC high quality.
6. LAN transport.
7. Thunderbolt Bridge transport.

## CLI shape

```bash
ibridge-primary --receiver 192.168.2.2:48320 --source synthetic --resolution 5120x2880 --fps 60
ibridge-primary --receiver 192.168.2.2:48320 --source display --display-id <id> --mode 1440p60
ibridge-primary --probe-capture
ibridge-primary --probe-power
```

## Virtual display path

Do not let virtual display difficulty block all progress. Implement synthetic/capture pipeline first, then virtual display.

Research candidates:

- CGVirtualDisplay/FreeDisplay style.
- Dummy display fallback.
- DriverKit only as long-term research.
