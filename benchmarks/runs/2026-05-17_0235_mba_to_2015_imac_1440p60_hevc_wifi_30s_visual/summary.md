# MBA to 2015 iMac 1440p60 HEVC Wi-Fi Visual Smoke

- Source: MacBook Air M1, synthetic NV12.
- Receiver: 2015 27-inch iMac macOS receiver, user `oosu`, Wi-Fi `192.168.31.187`.
- Transport: protocol v0 TCP on port `48320` over local Wi-Fi.
- Profile: `2560x1440 @ 60fps`, HEVC, Annex-B, 25Mbps target, 30 seconds.
- Visual status: user reported visible change on the iMac panel during the smoke. Remote `screencapture` was not treated as authoritative because it appeared to capture the desktop/background instead of the receiver display layer/fullscreen Space.

## Result

- Sender requested/submitted/encoded: `1800/1800/1800` frames.
- Sender failed frames: `0`.
- Sender send failures: `0`.
- Sender queue drops: `2`.
- Sender p95 encode latency: `9.730 ms`.
- Sender max encode latency: `34.592 ms`.
- Sender p95 send time: `0.096 ms`.
- Sender max send time: `95.444 ms`.
- Receiver frames total: `1798`.
- Receiver missing-frame events: 2 events, 1 frame each, before frames `1407` and `1437`.
- Receiver log captured the primary handshake and frame receive diagnostics.

## Read

This is the first MacBook Air -> 2015 iMac macOS receiver visual smoke over Wi-Fi. It proves the conservative 1440p60 HEVC path can encode, send, receive, and visibly change the iMac display. It does not prove smooth display quality because Wi-Fi ICMP jitter remains high, the sender queue dropped 2 frames in 30 seconds, and the receiver observed the same 2 missing frames.

Keep 5K, tiled 5K, and high-detail fallback work blocked on wired transport.
