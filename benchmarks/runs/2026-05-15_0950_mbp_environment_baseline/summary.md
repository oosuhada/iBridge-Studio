# MacBook Pro Environment Baseline

Prompt: MacBook Pro Primary comparison after MacBook Air / iMac tests.

## Machine

- Hostname: `Gabriels-MacBook-Pro.local`
- User: `gabriel`
- Model: MacBook Pro `MacBookPro18,4`
- Chip: Apple M1 Max
- CPU cores: 10
- GPU cores: 24
- Memory: 32 GB
- Power: AC power, battery 100%

## Displays

| Display | Resolution | Notes |
|---|---:|---|
| Built-in Color LCD | 3024x1964 | main display |
| TFX173T | 1080x1920 | external portrait display |
| Sidecar Display | 2360x1640 | AirPlay virtual display, iPad Air 5 candidate |
| LG IPS FULLHD | 1920x1080 | external FHD display |

## Validation

- `swift build --package-path apps/primary-macos -c release`: passed
- `python3 apps/shared-protocol/test_protocol_v0.py`: passed
- `ibridge-primary --list-encoders`: passed

## Notes

- Tailscale status shows the Windows iMac as `oosu-imac` at `100.86.52.88`.
- The environment is a better Primary candidate than the MacBook Air for sustained tests, but actual iMac receiver decode/render still needs Windows-side execution.
