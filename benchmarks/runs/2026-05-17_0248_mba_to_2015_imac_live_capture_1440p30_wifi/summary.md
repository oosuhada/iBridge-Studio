# MBA to 2015 iMac Live Capture 1440p30 Wi-Fi

- Source: MacBook Air live ScreenCaptureKit display capture.
- Receiver: 2015 27-inch iMac macOS receiver, `oosu@100.84.32.31`, local Wi-Fi IP `192.168.31.187`.
- Profile: `2560x1440 @ 30fps`, HEVC, Annex-B, 15Mbps target, 10 seconds.
- Transport: protocol v0 TCP on port `48320` over local Wi-Fi.

## Result

- Sender requested/submitted/encoded: `300/300/300` frames.
- Sender failed frames: `0`.
- Sender send failures: `0`.
- Sender queue drops: `1`.
- Sender p95 encode latency: about `18.236 ms`.
- Sender max encode latency: `62.843 ms`.
- Receiver frames total: `299`.
- Receiver missing-frame events: one 1-frame gap before frame `6`.

## Read

This proves MacBook Air live screen capture can be sent to and received by the
2015 iMac over Wi-Fi. This is a mirror/live-capture display path, not a true
macOS extended desktop. The remaining product gap is a virtual display source
on the MacBook Air.
