# MacBook Pro Display Capture Smoke

Prompt: MacBook Pro Primary comparison after MacBook Air / iMac tests.

## Captured Displays

| Capture | Pixel size | Display |
|---|---:|---|
| `display_1.png` | 3024x1964 | built-in Color LCD |
| `display_2.png` | 1080x1920 | TFX173T external portrait display |
| `display_3.png` | 1920x1080 | LG IPS FULLHD external display |
| `display_4.png` | 2360x1640 | Sidecar Display |

## Result

macOS `screencapture` can capture all four currently attached displays without a new permission prompt. iBridge still needs ScreenCaptureKit integration before these displays can be used as live capture sources inside the app.
