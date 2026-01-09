# Current Work

Date: 2026-05-16

Branch: `feat/plan-a-5k60-benchmark`

Draft PR: https://github.com/oosuhada/iBridge/pull/1

## Current Goal

Build and measure the macOS Primary -> Windows iMac Receiver path for using a 2015 27-inch iMac Retina 5K as a software external display.

## Current Status

- Prompt 00, 01, 02, 06, 05, 07, 03, 04, and 08 have been run with 09 review gates after implementation prompts.
- Windows iMac SSH over Tailscale works at `100.86.52.88`.
- Windows Receiver can run D3D11 fullscreen synthetic benchmarks from the active Windows console session.
- macOS Primary can generate synthetic frames and encode H.264/HEVC via VideoToolbox.
- Protocol v0 has a fixed 80-byte header and parser tests.
- Plan B 5K60 compressed mode was attempted and currently fails practical gates due to H.264 encode failure, HEVC latency, and slow TCP/Tailscale transport.
- Plan C scaled modes have an engineering comparison; `3200x1800 @ 60fps` is the temporary engineering default, but text quality is not validated.
- Current transport results are classified as Tailscale / likely Wi-Fi 2.4GHz / TCP early experiments and are not representative of LAN or Thunderbolt Bridge.
- macOS Primary now separates VideoToolbox output callback timing from TCP socket send timing with a bounded async sender queue.
- Windows Receiver has a new offline Media Foundation compressed file decode/render smoke path, but live TCP compressed decode/render is still pending Windows-side validation.
- MacBook Pro `MacBookPro18,4` / M1 Max has now been tested as a Primary candidate on branch `feat/plan-a-5k60-benchmark`.
- On the MacBook Pro, forcing `com.apple.videotoolbox.videoencoder.ave.hevc` and disabling low-latency rate-control produced the best Plan C encode results so far.
- A local ignored `reference/` workspace has been created for clean-room study of mature capture, encode, transport, decode, and frame-pacing implementations.
- `reference/BetterDisplay` is now an explicit Git submodule on BetterDisplay's `opensource` branch so MacBook Pro, MacBook Air, and Codex Cloud sessions can fetch the same HiDPI/virtual-display reference from GitHub.
- The reference scope has been widened beyond macOS-to-Windows. Mac-to-Mac routes are now explicitly in scope if an older macOS install on the iMac creates a stronger technical path.
- Nested `.git` directories have been removed from the ignored `reference/` clones so VS Code only sees the outer iBridge repository. BetterDisplay is the exception and is intentionally represented as a top-level submodule.
- Reference analysis now points to concrete next spikes: VT property matrix, Annex-B fixture path, bounded receiver pacing, GPU-native decode/render, and a local Mac virtual-display smoke.
- iMac setup prep is documented with a Windows inventory script and a conservative remote-vs-physical-access boundary for Boot Camp/macOS work.
- Primary VideoToolbox encoding has been rechecked with reference-informed controls. Plan B 5K60 still fails before any receiver dependency; 3200x1800 and 3840x2160 are the current strongest encode-only candidates.
- Primary encoding now has source strategy probes for synthetic BGRA, synthetic NV12, static-frame skipping, ScreenCaptureKit capture, 5K45/5K30, and 2x2 tiled HEVC sessions.
- Tiled 5K60 has a stronger encode-only path after deeper investigation: per-tile PTS was corrected, and `2x2 30Mbps/tile reset180 inflight1` sustained 30 seconds at 60.009 effective fps with p95 12.690 ms. Reset-frame max spikes around 100-136 ms remain unresolved, but deadline analysis shows only 18/1800 logical frames exceeded 16.67 ms.
- Direction corrected: before building Windows tiled receiver composition, iBridge should finish sender-side transmission profiles for M1 Max/M1 Air and wired/wireless paths. Windows/macOS receiver decode should be tested later after the iMac has both OS environments available.
- Added a transmission profile matrix and encode-first script. Latest M1 Max quick retest keeps the 2x2 tiled HEVC 5K60 path promising, while current single-stream 4096x2304/3200x1800 retests missed the 60Hz encode budget and need repeat isolation/profile tuning.
- Re-isolated M1 Max single-stream profiles. When run without tiled 5K60 first, 4096x2304, 3840x2160, 3200x1800, and 2560x1440 all passed p95 <=16.67ms across 3/3 repeats. The slow quick-matrix fallback results are now attributed to tiled 5K60 contaminating immediate follow-up single-stream VideoToolbox state.
- Restarting the user `VTEncoderXPCService` did not recover post-tiled 4096x2304/3200x1800 performance. After tiled contamination, 2560x1440 remained inside budget and is the current safest emergency fallback.
- M1 MacBook Air `MacBookAir10,1` sender profile matrix has now been run locally for 30 seconds per case. Only `2560x1440 @ 60` synthetic NV12 HEVC passed the 16.67 ms p95 encode budget; `3200x1800`, `3840x2160`, and 2x2 tiled 5K60 missed the sender-only 60Hz budget.
- MacBook Pro current-path Tailscale ping to the Windows iMac was rechecked from `macbook-pro`: 20/20 received, min/avg/max/stddev `9.451/73.839/507.671/107.944 ms`. This path remains too jittery to choose display profiles; wired Thunderbolt Bridge or 1GbE tests are still the next transport gate.
- MacBook Pro current-path formal network matrix over Tailscale recorded 100-packet ping with 2.0% loss and min/avg/max/stddev `8.198/61.867/485.532/58.935 ms`. MBP currently lacks `iperf3` and Tailscale CLI, so throughput and direct/relay status remain unmeasured on this path.
- Encoder reset/session strategy now has reference-backed probe controls. `--tile-segment-hints` applies VideoToolbox concatenate/source-frame-count hints to per-tile reset segments, and `--tile-reset-stagger-frames` can stagger per-tile resets for comparison.
- Initial M1 Max reset strategy probes favor `2x2 tiled HEVC 5K60 + reset180 + inflight1 + tile segment hints + simultaneous reset`: segment hints reduced logical frames over 16.67 ms in short probes, while staggered reset lowered max spike but spread reset misses across more frames.
- Clean-session fallback gate now has a dedicated script. Current uptime was 2936 minutes, so the valid clean-session run was skipped; dirty current-session controls were mixed, with one pass followed by a repeat failure. This keeps high-detail fallback switching unsafe for product defaults.
- The current four-device lab inventory is documented: M1 Max MacBook Pro 32 GB, M1 MacBook Air 8 GB, 2017 21.5-inch Retina 4K iMac 8 GB / Radeon Pro 555 / macOS, and 2015 27-inch Retina 5K iMac 8 GB / Radeon R9 M380 / macOS + Windows boot.
- The next physical test order is documented in `docs/16_DEVICE_AND_TEST_PLAN_2026-05-16.md`: start with MacBook Pro -> 2017 4K iMac over wireless, Ethernet, then Thunderbolt; then MacBook Pro -> 2015 5K iMac wireless/Ethernet; then repeat the same practical paths with MacBook Air; leave 2015 iMac Thunderbolt 2 cases blocked until the TB2 cable/adapter chain is available.
- Current OS state changed: MacBook Pro and MacBook Air are on macOS Tahoe 26; both iMacs are on macOS Sequoia through OCLP.
- AirPlay Receiver is not visible from the MacBook Pro to the iMacs. Keep AirPlay as a comparison-only path and continue iBridge over local network transport.
- MacBook Pro -> 2017 iMac direct Ethernet is now physically connected and measured: MBP `en9` `169.254.6.144` to iMac `169.254.63.68`, `1000baseT <full-duplex>`, 100-packet ping min/avg/max/stddev `0.425/0.810/1.379/0.235 ms`.
- The same 2017 iMac over 5GHz Wi-Fi local IP `192.168.31.249` is reachable but jittery: 100-packet ping min/avg/max/stddev `3.706/53.842/409.182/70.703 ms`.
- 2017 iMac `iperf3 -s` is now running after manual Homebrew permission repair. Current direct Ethernet IP is `169.254.70.114`.
- MacBook Pro -> 2017 iMac 1GbE matrix passed: ping `0.826/1.518/2.372/0.231 ms`, TCP to iMac `939.14 Mbps`, TCP reverse `937.50 Mbps`, UDP 30/60/120 Mbps all 0% loss.
- MacBook Pro -> 2017 iMac 5GHz Wi-Fi matrix is much weaker: ping `3.663/56.773/261.386/70.416 ms`, TCP to iMac `86.54 Mbps`, TCP reverse `68.66 Mbps`, UDP 120 Mbps received `103.72 Mbps` with `8.202%` loss.
- 2017 iMac SSH is now repaired: `sudo ssh-keygen -A` created host keys, the MacBook Pro public key is in `authorized_keys`, and SSH works over Tailscale and direct 1GbE.
- 2017 iMac remote prep is active: `caffeinate -dimsu` prevents sleep, and `/usr/local/bin/iperf3 -s` is listening on TCP `5201`.
- Post-repair direct 1GbE TCP spot check reached `937.86 Mbps` received over `169.254.70.114`.
- Scope correction: the 2017 21.5-inch iMac is a 4K receiver target only. Run live receiver work up to `3840x2160@60` on it; reserve `4096x2304`, 5K, and tiled 5K-style profiles for the 2015 27-inch Retina 5K iMac.
- MacBook Air has started the parallel 2015 27-inch Retina 5K iMac Wi-Fi path while MacBook Pro continues 2017 iMac work. Tailscale shows the 2015 iMac as `gabriels-imac27-2015` at `100.84.32.31` with local-direct endpoint `192.168.31.187:41641`.
- MacBook Air -> 2015 iMac 5GHz/local Wi-Fi reachability is confirmed, but the path is jittery: 100-packet ping to `192.168.31.187` had 0% loss with min/avg/max/stddev `3.819/51.446/420.666/88.334 ms`. TCP ports `22` and `5201` are open; `48320` is refused.
- MacBook Air could not complete iperf throughput from this machine yet because local `iperf3` is missing and Homebrew failed on macOS 26.5 / dirty `/opt/homebrew`. SSH to the 2015 iMac is also blocked by missing MacBook Air key authorization, despite the port being open.
- MacBook Air Homebrew was repaired enough to install `iperf3`, and the MacBook Air -> 2015 iMac Wi-Fi throughput matrix now exists. Ping remains jittery at min/avg/max/stddev `3.690/30.495/258.942/44.687 ms`, but throughput is usable for low-bandwidth smoke testing: TCP to receiver `154.09 Mbps`, TCP reverse `129.43 Mbps`, UDP 30Mbps `0%` loss, UDP 60Mbps `0.333%` loss, UDP 120Mbps `0.003%` loss.
- MacBook Air SSH to the 2015 iMac is now fixed with the existing `~/.ssh/ibridge_imac_ed25519` key. The active macOS user is `oosu`, so use `ssh -i ~/.ssh/ibridge_imac_ed25519 oosu@100.84.32.31`. Remote prep is active: `caffeinate -dimsu` and `iperf3 -s` are running, Wi-Fi is `en1`, and the local IP is `192.168.31.187`.
- MacBook Air -> 2015 iMac macOS receiver visual smoke passed at conservative `2560x1440@60` HEVC over Wi-Fi. Sender encoded 1800/1800 frames over 30s with 0 send failures and p95 encode `9.730 ms`; receiver logged the handshake and `1798` received frames. Two sender queue drops matched two receiver missing-frame events, so this proves the path works but does not prove smooth display quality.
- MacBook Pro -> 2017 4K iMac live macOS receiver plumbing now works over direct 1GbE. The remote Intel iMac builds `apps/receiver-macos`, receives HEVC Annex-B protocol v0 frames, and the user observed the iMac screen changing.
- Live `1920x1080@60` HEVC smoke sent 300/300 frames with sender drop/send failure 0 and receiver logged 300 frames.
- Live `3840x2160@60` HEVC smoke sent 720/720 frames with sender drop/send failure 0 and receiver logged frames through 660 before disconnect. This proves live 4K plumbing, but not final smooth 4K60 because encode callback latency was high in this run.
- Remote SSH `screencapture` did not reliably capture the receiver's AVSampleBufferDisplayLayer/active Space, even when the user could see the iMac screen change. Treat receiver runtime logs plus direct visual observation as stronger evidence than SSH screenshots for this path.
- BetterDisplay current app can likely solve the source-Mac virtual display / HiDPI setup piece, but it does not replace iBridge transport/receiver. `reference/BetterDisplay` is BetterDummy OpenSource Edition on the `opensource` branch; it is enough for CGVirtualDisplay clean-room study, not enough to fork the full current BetterDisplay v4 product.
- MacBook Air -> 2015 iMac live screen-capture smoke also works at `2560x1440@30` HEVC 15Mbps over Wi-Fi. This is a mirror/live-capture path, not yet a true macOS extended desktop. Added helper scripts to start/stop the 2015 iMac receiver and start a long-running MacBook Air live capture session.
- User configured a macOS `Virtual 16:9` extended display at `1920x1080`. `scripts/start_mba_to_2015_imac_live_capture.sh` now defaults to capture display index `1`, `1920x1080@30`, HEVC 8Mbps, and receiver `100.84.32.31`, so the helper path targets the virtual extended display instead of the built-in display.
- BetterDisplay `Virtual 16:9` is now configured as an extended display. macOS reports it as `3840x2160` backing pixels with UI looking like `1920x1080 @ 60Hz`.
- iBridge can capture the BetterDisplay virtual screen and send it to the 2017 iMac receiver. Live `3840x2160@60` capture submitted/encoded `299/600` changed frames with 0 send failures; downscaled `1920x1080@60` submitted/encoded `255/600` changed frames with 0 send failures.

## Key Results

- Plan A dynamic 5K60 CPU-filled BGRA upload on iMac: 29.979-36.034fps depending on run; not viable.
- Receiver GPU/static 5K present path: about 61fps; iMac can present 5K60 when full-frame CPU upload is removed.
- Primary 1440p60 H.264/HEVC encode works but initial callback latency is high.
- H.264 5120x2880 @ 60 target produced status `-10279` for every frame in the current VideoToolbox path.
- HEVC 5120x2880 @ 60 target encoded, but 120Mbps TCP to Windows sink took 38.60s for 1s of frames.
- Plan C receiver static scaled-render modes all reached about 60fps.
- MacBook Pro HEVC 3200x1800 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC: avg encode 16.612 ms, p95 16.777 ms.
- MacBook Pro HEVC 3200x1800 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, DataRateLimits: 5s sustained avg 11.583 ms, p95 11.766 ms.
- MacBook Pro HEVC 3840x2160 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, DataRateLimits: 5s sustained avg 15.457 ms, p95 15.831 ms.
- MacBook Pro HEVC 4096x2304 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, DataRateLimits: 5s sustained avg 17.292 ms, p95 17.231 ms.
- MacBook Pro HEVC 5120x2880 @ 60, 120Mbps, forced `ave.hevc`, no low-latency RC, speed priority: 5s sustained avg 100.617 ms, p95 119.982 ms.
- MacBook Pro synthetic NV12 HEVC 3840x2160 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 11.557 ms, p95 11.906 ms.
- MacBook Pro synthetic NV12 HEVC 4096x2304 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 12.898 ms, p95 13.245 ms.
- MacBook Pro -> 2017 iMac live `1920x1080@60` HEVC: frames requested/submitted/encoded `300/300/300`, sender drops `0`, send failures `0`, avg encode `13.325 ms`, p95 encode `19.448 ms`, avg send `0.074 ms`.
- MacBook Pro -> 2017 iMac live `3840x2160@60` HEVC: frames requested/submitted/encoded `720/720/720`, sender drops `0`, send failures `0`, avg encode `56.705 ms`, p95 encode `73.049 ms`, avg send `0.047 ms`. Receiver logged protocol handshake and frame receipt; user-visible screen changed, but remote screenshot was not reliable.
- BetterDisplay virtual-screen live capture to 2017 iMac, `3840x2160@60`: submitted/encoded `299/600`, sender drops `0`, send failures `0`, avg encode `32.346 ms`, p95 encode `64.015 ms`, avg send `0.468 ms`; receiver logged `299` frames.
- BetterDisplay virtual-screen live capture to 2017 iMac, downscaled `1920x1080@60`: submitted/encoded `255/600`, sender drops `0`, send failures `0`, avg encode `13.793 ms`, p95 encode `22.332 ms`, avg send `0.510 ms`; receiver logged `255` frames.
- MacBook Pro ScreenCaptureKit HEVC 3840x2160 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 16.363 ms, p95 18.412 ms.
- MacBook Pro ScreenCaptureKit HEVC 5120x2880 @ 60, forced `ave.hevc`, DataRateLimits: 3s avg 302.354 ms, p95 360.042 ms.
- MacBook Pro synthetic NV12 HEVC 5120x2880 @ 30, forced `ave.hevc`, DataRateLimits: 3s avg 19.296 ms, p95 19.824 ms.
- MacBook Pro 2x2 tiled-session approximation for 5120x2880 @ 60 using four 2560x1440 NV12 HEVC sessions: per-tile avg 6.496-9.528 ms, p95 10.568-11.254 ms; recomposition is unimplemented.
- MacBook Pro 2x2 tiled HEVC 5120x2880 @ 60, corrected per-tile PTS, 30Mbps/tile, reset every 180 logical frames, max 1 in-flight logical frame: 30s sustained avg 12.100 ms, p95 12.690 ms, effective 60.009 fps, max 135.530 ms on reset frames.
- MacBook Pro transmission profile quick retest, 2x2 tiled HEVC 5120x2880 @ 60, 30Mbps/tile, reset180, inflight1: 5s avg 12.501 ms, p95 13.222 ms, effective 60.040 fps, max 123.935 ms; only 2/300 logical frames exceeded 16.67 ms.
- Same quick retest, single HEVC 4096x2304 @ 60, 120Mbps: avg 25.717 ms, p95 46.742 ms; current session missed the 60Hz encode budget despite earlier stronger runs.
- Same quick retest, single HEVC 3200x1800 @ 60, 60Mbps: avg 23.614 ms, p95 41.764 ms; lower-bandwidth wireless-style profile did not reduce encode latency in this run.
- Re-isolated single-stream stability, `PRIORITIZE_SPEED=unset`, 3 repeats: 4096x2304 median p95 13.050 ms, 3840x2160 11.669 ms, 3200x1800 11.250 ms, 2560x1440 10.636 ms.
- Re-isolated single-stream stability, `PRIORITIZE_SPEED=on`, 3 repeats: 4096x2304 median p95 13.087 ms, 3840x2160 11.668 ms, 3200x1800 11.218 ms, 2560x1440 6.455 ms.
- Post-tiled recovery probe: restarting `VTEncoderXPCService` did not recover 4096x2304; p95 stayed around 46.5 ms immediately and after 60 seconds. 3200x1800 solo also stayed slow at p95 41.839 ms, while 2560x1440 stayed safe at p95 10.808 ms.
- Encoder reset strategy probe, 6s M1 Max tiled 5K60: baseline simultaneous reset avg 13.199 ms, p95 14.330 ms, max 132.700 ms, 7/360 logical frames >16.67 ms. Segment hints simultaneous reset avg 13.362 ms, p95 14.158 ms, max 134.008 ms, 4/360 logical frames >16.67 ms. Segment hints staggered reset avg 13.300 ms, p95 14.243 ms, max 113.596 ms, 8/360 logical frames >16.67 ms and 4/360 >33.33 ms.
- Post-reset-strategy fallback probe still showed the post-tiled slow state: 4096x2304 p95 46.578 ms, 3200x1800 p95 42.273 ms, 2560x1440 p95 16.866 ms. Because the machine was already in a slow state, this confirms the risk but is not a clean recovery A/B.
- Clean-session guard run skipped because uptime was 2936 minutes. Dirty control run passed once (`4096x2304` p95 14.918 ms, `3200x1800` p95 11.444 ms), but immediate repeat failed (`4096x2304` p95 46.669 ms, `3200x1800` p95 42.616 ms). Treat high-detail fallback after tiled 5K60 as unstable.
- M1 Air HEVC 2560x1440 @ 60, 25Mbps: avg 8.145 ms, p95 9.296 ms, max 20.146 ms; passes p95 encode budget and is the realistic Air default.
- M1 Air HEVC 3200x1800 @ 60, 35Mbps: avg 18.873 ms, p95 38.897 ms, max 325.872 ms; fails 60Hz encode budget.
- M1 Air HEVC 3840x2160 @ 60, 45Mbps: avg 18.727 ms, p95 54.584 ms, max 233.527 ms; fails 60Hz encode budget.
- M1 Air 2x2 tiled HEVC 5120x2880 @ 60, 25Mbps/tile, reset180, inflight1: effective 41.599 fps, avg 23.626 ms, p95 23.718 ms, max 72.096 ms; all 1800 logical frames exceeded 16.67 ms, so this is not worth continuing on M1 Air without a major new strategy.
- MacBook Pro display-sized synthetic sources for built-in XDR, external portrait display, Sidecar iPad, and HDMI FHD display all encoded successfully with forced `ave.hevc`.
- MacBook Pro to iMac Tailscale path is reachable, but ping is jittery: 20-packet ICMP min/avg/max/stddev 14.484/108.629/423.525/96.505 ms.
- MacBook Pro to iMac Tailscale recheck remains jittery: 20-packet ICMP min/avg/max/stddev `9.451/73.839/507.671/107.944 ms`.
- MacBook Pro to iMac formal Tailscale network matrix: 100-packet ICMP `98/100` received, 2.0% loss, min/avg/max/stddev `8.198/61.867/485.532/58.935 ms`; not suitable for display transport decisions.
- MacBook Air to 2015 iMac local Wi-Fi/Tailscale-direct spot check: `tailscale ping` reached `gabriels-imac27-2015` via `192.168.31.187:41641`; 100-packet local ping min/avg/max/stddev `3.819/51.446/420.666/88.334 ms`.
- MacBook Air to 2015 iMac Wi-Fi iperf matrix: TCP to receiver `154.09 Mbps`, TCP reverse `129.43 Mbps`; UDP 30/60/120Mbps received `29.99/59.78/119.95 Mbps` with `0/0.333/0.003%` loss. ICMP latency spikes remain too high for smooth-display confidence.
- MacBook Air to 2015 iMac macOS receiver smoke, `2560x1440@60` HEVC 25Mbps TCP over Wi-Fi for 30s: sender `1800/1800` encoded, 0 send failures, 2 sender queue drops, p95 encode `9.730 ms`, receiver `1798` frames with two 1-frame missing events. User visually confirmed the iMac panel changed during the smoke.
- MacBook Air to 2015 iMac live capture smoke, `2560x1440@30` HEVC 15Mbps TCP over Wi-Fi for 10s: sender `300/300` encoded, 0 send failures, 1 sender queue drop, receiver `299` frames. A 3s script validation run then passed with `90/90` encoded and 0 drops.
- MacBook Air virtual extended display smoke, `Virtual 16:9` at `1920x1080@30` HEVC 8Mbps over Tailscale: sender `90/28/28` over 3s, 0 failed frames, 0 send failures, 0 queue drops. Low submitted-frame count is expected for a mostly static extended display.
- macOS internal alpha packaging now exists. `scripts/package_macos_alpha.sh` builds the sender and receiver, creates an ad-hoc signed `iBridge Receiver.app`, includes a package-local virtual-display sender launcher, and emits `dist/iBridge-0.1.0-alpha.zip`.
- Current package verification passed script syntax, Swift release builds, zip generation, byte-identical sender copy, and app signature verification.
- Current live sender smoke from this MacBook Pro is blocked because the active external display state changed to AirPlay `Gabriel의 iMac` 1080p and `ibridge-primary --list-displays` returned `capture_display_count=0`; reconnect BetterDisplay `Virtual 16:9` as an extended display before retrying the packaged sender.
- Wired high-quality alpha profile now exists as `PROFILE=lan-readable` and `Start iBridge LAN High Quality.command`: `2560x1440@30`, HEVC, 35Mbps, sender queue 12, capture queue 6. This is the current readability-first LAN default.
- Direct 1GbE synthetic receiver smoke confirms transport stability for higher-detail profiles: `2560x1440@30 35Mbps` encoded `150/150`, sender drops `0`, send failures `0`, avg send `0.060 ms`, p95 send `0.098 ms`; p95 encode was `25.772 ms`.
- Screen capture now has `--capture-max-in-flight-frames`, and wired profiles set it to `1` to prefer newer frames over a stale encode backlog when high-detail capture falls behind.
- Packaged LAN high-quality live virtual capture now works again after ScreenCaptureKit exposed `capture_display_count=2`; auto-selected `display_index=1` and sent `2560x1440@30 35Mbps` for a 3s smoke with `46/46` encoded, 0 send failures, 0 sender drops, p95 encode `17.101 ms`, and p95 send `0.877 ms`.

## Files Likely Relevant Next

- `apps/primary-macos/Sources/iBridgePrimary/main.swift`
- `apps/receiver-windows/src/main.cpp`
- `benchmarks/plans/network_matrix.md`
- `scripts/mac_network_matrix.sh`
- `scripts/windows_network_matrix.ps1`
- `scripts/mac_plan_c_encode_matrix.sh`
- `scripts/mac_vt_property_matrix.sh`
- `scripts/mac_encode_strategy_matrix.sh`
- `benchmarks/runs/2026-05-15_1213_tiled_5k60_reset_sustain_30s/summary.md`
- `benchmarks/runs/2026-05-15_1212_tiled_5k60_reset_sustain_10s/summary.md`
- `benchmarks/runs/2026-05-15_1222_tiled_5k60_reset180_sustain_30s/summary.md`
- `docs/13_TILED_5K60_STRATEGY.md`
- `docs/14_TRANSMISSION_PROFILE_MATRIX.md`
- `docs/15_ENCODER_RESET_STRATEGY.md`
- `scripts/mac_encoder_reset_strategy_probe.sh`
- `scripts/mac_clean_session_encoder_probe.sh`
- `scripts/mac_transmission_profile_matrix.sh`
- `scripts/mac_single_stream_stability_matrix.sh`
- `benchmarks/runs/2026-05-15_1258_transmission_profile_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1306_transmission_profile_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1344_mbp_current_path_probe/ping_20_imac_tailscale.txt`
- `benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix/tailscale/ping_100.txt`
- `benchmarks/runs/2026-05-16_2350_mbp_to_2017_imac_lan_wifi/summary.md`
- `benchmarks/runs/2026-05-17_0025_mbp_to_2017_imac_iperf/summary.md`
- `benchmarks/runs/2026-05-17_0135_mba_to_2015_imac_wifi5/wifi5-2015-imac/summary.md`
- `benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf/wifi5-2015-imac/summary.md`
- `benchmarks/runs/2026-05-17_0235_mba_to_2015_imac_1440p60_hevc_wifi_30s_visual/summary.md`
- `scripts/start_2015_imac_receiver_macos.sh`
- `scripts/start_mba_to_2015_imac_live_capture.sh`
- `scripts/stop_2015_imac_receiver_macos.sh`
- `benchmarks/runs/2026-05-15_1330_single_stream_stability_unset/aggregate.md`
- `benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on/aggregate.md`
- `benchmarks/runs/2026-05-15_1358_encoder_service_restart_probe/`
- `benchmarks/runs/2026-05-15_1415_encoder_reset_strategy_probe/`
- `benchmarks/runs/2026-05-15_1424_encoder_reset_strategy_probe_summary_fix/`
- `benchmarks/runs/2026-05-15_1550_clean_session_probe_guard/`
- `benchmarks/runs/2026-05-15_1552_dirty_session_encoder_probe/`
- `benchmarks/runs/2026-05-15_1553_dirty_session_encoder_probe_repeat/`
- `scripts/analyze_tiled_deadline.py`
- `benchmarks/runs/2026-05-15_1056_vt_property_matrix/summary.csv`
- `benchmarks/runs/2026-05-15_1058_vt_targeted_sustain/summary.md`
- `benchmarks/runs/2026-05-15_1129_encode_strategy_matrix/summary.md`
- `apps/shared-protocol/protocol_v0.py`
- `specs/protocol_v0.md`
- `benchmarks/runs/2026-05-15_0238_plan_b_5k_hevc_120mbps_tcp/summary.md`
- `benchmarks/runs/2026-05-15_0255_plan_c_scaled_modes/mode_comparison.md`
- `benchmarks/runs/2026-05-15_1000_mbp_encoder_id_probe/summary.md`
- `benchmarks/runs/2026-05-15_1012_mbp_display_resolution_encode/summary.md`
- `logs/review_gate.md`
- `logs/worklog.md`
- `reference/README.md`
- `docs/11_REFERENCE_TECH_ANALYSIS.md`
- `docs/12_IMAC_SETUP_PREP.md`
- `docs/16_DEVICE_AND_TEST_PLAN_2026-05-16.md`
- `.gitmodules`
- `reference/BetterDisplay`
- `scripts/windows_imac_setup_inventory.ps1`

## Commands Run

- `swift build --package-path apps/primary-macos -c release`
- `python3 apps/shared-protocol/test_protocol_v0.py`
- `bash -n scripts/mac_encode_strategy_matrix.sh`
- `DURATION=3 scripts/mac_encode_strategy_matrix.sh`
- `DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 RUN_ROOT=benchmarks/runs/2026-05-15_1258_transmission_profile_matrix scripts/mac_transmission_profile_matrix.sh`
- `DEVICE_PROFILE=m1air PROFILE_SET=air DURATION=30 scripts/mac_transmission_profile_matrix.sh`
- `ssh macbook-pro 'cd ~/development/iBridge && git pull --rebase'`
- `ssh macbook-pro 'ping -c 20 100.86.52.88'`
- `ssh macbook-pro 'cd ~/development/iBridge && DURATION=10 RUN_ROOT=benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix scripts/mac_network_matrix.sh --case tailscale --receiver-ip 100.86.52.88 --tailscale-name 100.86.52.88'`
- `REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=unset RUN_ROOT=benchmarks/runs/2026-05-15_1330_single_stream_stability_unset scripts/mac_single_stream_stability_matrix.sh`
- `REPEATS=3 DURATION=5 COOLDOWN_SECONDS=3 PRIORITIZE_SPEED=on RUN_ROOT=benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on scripts/mac_single_stream_stability_matrix.sh`
- `pkill -x VTEncoderXPCService` followed by 4096x2304, 3200x1800, and 2560x1440 fallback probes.
- `bash -n scripts/mac_encoder_reset_strategy_probe.sh`
- `DURATION=6 RUN_FALLBACK=1 RUN_ROOT=benchmarks/runs/2026-05-15_1415_encoder_reset_strategy_probe scripts/mac_encoder_reset_strategy_probe.sh`
- `DURATION=6 RUN_FALLBACK=0 RUN_ROOT=benchmarks/runs/2026-05-15_1424_encoder_reset_strategy_probe_summary_fix scripts/mac_encoder_reset_strategy_probe.sh`
- `RUN_ROOT=benchmarks/runs/2026-05-15_1550_clean_session_probe_guard scripts/mac_clean_session_encoder_probe.sh`
- `DURATION=6 FALLBACK_DURATION=5 REQUIRE_CLEAN_BOOT=0 RUN_ROOT=benchmarks/runs/2026-05-15_1552_dirty_session_encoder_probe scripts/mac_clean_session_encoder_probe.sh`
- `DURATION=10 FALLBACK_DURATION=5 REQUIRE_CLEAN_BOOT=0 RUN_ROOT=benchmarks/runs/2026-05-15_1553_dirty_session_encoder_probe_repeat scripts/mac_clean_session_encoder_probe.sh`
- Windows MSVC `cl` build for `ibridge-receiver.exe`
- Windows iMac Task Scheduler D3D11 fullscreen benchmark runs
- `scripts/mac_power_probe.sh`
- `git pull --rebase --autostash`
- `git submodule add -f -b opensource https://github.com/waydabber/BetterDisplay.git reference/BetterDisplay`
- `ping -c 100 -i 0.2 169.254.63.68`
- `ping -c 100 -i 0.2 192.168.31.249`
- `nc -vz -G 2 169.254.63.68 22`
- `nc -vz -G 2 192.168.31.249 22`
- `nc -vz -G 2 169.254.63.68 5201`
- `nc -vz -G 2 192.168.31.249 5201`
- `brew install iperf3`
- `RUN_ROOT=benchmarks/runs/2026-05-17_0025_mbp_to_2017_imac_iperf DURATION=20 scripts/mac_network_matrix.sh --case 1gbe-2017-imac-retry --receiver-ip 169.254.70.114`
- `RUN_ROOT=benchmarks/runs/2026-05-17_0025_mbp_to_2017_imac_iperf DURATION=10 scripts/mac_network_matrix.sh --case wifi5-2017-imac --receiver-ip 192.168.31.249`
- `ssh gabrieljang@100.89.104.119 'hostname; whoami; sw_vers; command -v iperf3 || true; pgrep -fl iperf3 || true'`
- `ssh gabrieljang@100.89.104.119 'nohup caffeinate -dimsu > ~/ibridge-remote/caffeinate.log 2>&1 &'`
- `ssh gabrieljang@100.89.104.119 'nohup /usr/local/bin/iperf3 -s > ~/ibridge-remote/iperf3-server.log 2>&1 &'`
- `iperf3 -c 169.254.70.114 -t 5 --json`
- `git pull --ff-only`
- `ping -c 20 -i 0.2 100.84.32.31`
- `tailscale ping --c 5 100.84.32.31`
- `ping -c 20 -i 0.2 192.168.31.187`
- `RUN_ROOT=benchmarks/runs/2026-05-17_0135_mba_to_2015_imac_wifi5 DURATION=10 scripts/mac_network_matrix.sh --case wifi5-2015-imac --receiver-ip 192.168.31.187 --tailscale-name 100.84.32.31`
- `brew install iperf3` (failed; local Homebrew issue)
- `cd /opt/homebrew && git fetch --depth=1 origin master && git reset --hard origin/master`
- `brew update`
- `brew install iperf3`
- `DURATION=20 RUN_ROOT=benchmarks/runs/2026-05-17_0208_mba_to_2015_imac_iperf scripts/mac_network_matrix.sh --case wifi5-2015-imac --receiver-ip 192.168.31.187 --tailscale-name 100.84.32.31`
- `swift build --package-path apps/primary-macos -c release`
- `swift build --package-path apps/receiver-macos -c release`
- `ssh -i ~/.ssh/ibridge_imac_ed25519 oosu@100.84.32.31 'cd ~/development && git clone https://github.com/oosuhada/iBridge.git ... && swift build --package-path apps/receiver-macos -c release'`
- `ssh -i ~/.ssh/ibridge_imac_ed25519 oosu@100.84.32.31 'nohup ~/development/iBridge/apps/receiver-macos/.build/release/ibridge-receiver-macos --port 48320 --fullscreen ... &'`
- `apps/primary-macos/.build/release/ibridge-primary --synthetic --source synthetic-nv12 --resolution 2560x1440 --fps 60 --duration 30 --codec hevc --bitrate-mbps 25 --data-rate-limit-mbps 25 --disable-low-latency-rate-control --encoder-id com.apple.videotoolbox.videoencoder.ave.hevc --disable-frame-reordering --disable-open-gop --payload-format annex-b --send-host 192.168.31.187 --send-port 48320`
- `apps/primary-macos/.build/release/ibridge-primary --screen-capture --source screen-capture --capture-display-index 0 --resolution 2560x1440 --fps 30 --duration 10 --codec hevc --bitrate-mbps 15 --send-host 192.168.31.187 --send-port 48320`
- `DURATION=3 scripts/start_mba_to_2015_imac_live_capture.sh`

## Known Issues

- Plan B 5K60 compressed encode is still not viable on the current MBP Primary path.
- Tiled 5K60 encode-only p95 is now promising, but reset-frame spikes around 100-133 ms would likely be visible unless the receiver hides, drops, or staggers them.
- Single-stream fallback results are stable when isolated, but become pessimistic when run immediately after tiled 5K60. Benchmark and product profile switching should not run tiled first and then immediately judge single-stream fallback performance.
- `VTEncoderXPCService` restart alone does not clear the post-tiled slow state for 4096x2304/3200x1800. Treat 2560x1440 as the current safest post-tiled emergency fallback until a stronger reset strategy is proven.
- VideoToolbox segment hints improve tiled reset deadline counts but do not yet prove recovery from post-tiled high-detail fallback contamination. A clean-session or reboot-start A/B is still required.
- Dirty current-session clean-gate controls are mixed: one high-detail fallback pass followed by a repeat failure. Do not promote 4096x2304/3200x1800 fallback switching until a fresh-boot run and repeat both pass.
- M1 Air should not default above `2560x1440 @ 60` based on current encode-only evidence.
- M1 Air tiled 5K60 is substantially below target in the current probe; do not spend receiver implementation time on Air-specific tiled 5K60 unless a new sender strategy changes this signal.
- The 2017 21.5-inch iMac should be used before the 2015 27-inch iMac for wired Mac-to-Mac receiver prep because it already boots macOS and has Thunderbolt 3; the 2015 iMac Thunderbolt 2 cases remain blocked until a real Thunderbolt 2 data cable/adapter chain is available.
- BetterDisplay is a submodule, so clones on the MacBook Air must run `git submodule update --init --recursive reference/BetterDisplay`.
- BetterDisplay installation alone should not be described as a complete iMac external-display solution; it is a source-side virtual display / HiDPI helper unless paired with iBridge or another transport/receiver.
- The current `reference/BetterDisplay` submodule is not the full modern BetterDisplay v4 codebase. Use it for `CGVirtualDisplay` patterns, and use `reference/SimpleDisplay` / `reference/FreeDisplay` as additional virtual-display references.
- Compressed decode/render on Windows is not implemented.
- UDP frame transport is specified but not implemented.
- ScreenCaptureKit capture is implemented as a benchmark source, but not yet connected to live receiver transport/decode/render.
- Text-quality screenshots are pending.
- Power cable/drain-rate tests require physical cable changes.
- LAN/Thunderbolt Bridge throughput tests require physical cable changes and `iperf3` on both machines.
- The current MBP shell did not expose `tailscale` CLI for direct/relay status capture.
- MBP and the 2017 iMac now have `iperf3`; remote SSH non-login shells on the iMac need `/usr/local/bin/iperf3` because Homebrew is not in `PATH`.
- Current 5GHz Wi-Fi to the 2017 iMac has severe jitter and should not be used to select high-detail display profiles.
- Current 5GHz/local Wi-Fi from MacBook Air to the 2015 iMac has enough throughput for low-bandwidth smoke testing, but ICMP latency spikes remain severe. Use only `2560x1440@60` HEVC-class experiments on this path; do not use it to validate smooth 5K/high-detail behavior.
- MacBook Air -> 2015 iMac Wi-Fi receiver smoke had 2 drops/missing frames in 30 seconds. Treat it as functional reachability/visual proof, not a smooth-display pass.
- Current MacBook Air -> 2015 iMac path is mirror/live-capture only. True extended desktop still needs a virtual display source on the MacBook Air, then ScreenCaptureKit can capture that virtual display.
- MacBook Air SSH auth to the 2015 iMac works for user `oosu`; prior `gabrieljang`/`gabriel` attempts failed because those were not the active account for this receiver.
- MacBook Air local Homebrew cannot currently install `iperf3`; do not reset `/opt/homebrew` without user approval.
- Windows compressed file decode/render code needs MSVC build/run validation on the iMac.
- MacBook Pro SSH auth to Windows iMac is blocked; port 22 is open but the MBP key is not accepted.
- Forced encoder ID plus low-latency rate-control currently fails `VTCompressionSessionCreate` with `-12902`; forced `ave.hevc` works when low-latency rate-control is disabled.
- `prompts/10_PACKAGING_AND_RELEASE.md` is blocked until at least one end-to-end display mode works.

## Next Steps

1. Use M1 Air `2560x1440 @ 60` HEVC as the realistic default candidate; only retest `3200x1800 @ 60` after profile tuning or thermal isolation.
2. Continue MacBook Pro -> 2017 4K iMac over 1GbE as the primary receiver path; treat current 5GHz Wi-Fi as a degraded comparison path.
3. Add sender backpressure/frame dropping for live 4K so encode latency stays bounded when VideoToolbox falls behind.
4. Add explicit capture display selection by display name/ID for `Virtual 16:9`; current tests used `--capture-display-index 0`, which worked but is brittle across display order changes.
5. Keep `3840x2160`, `3200x1800`, and `2560x1440` as the 2017 iMac receiver profiles; keep `4096x2304` as a sender-only or 2015 5K iMac candidate.
6. Keep 2x2 tiled HEVC 5K60 as the top full-resolution M1 Max + best-wired candidate for the 2015 27-inch Retina 5K iMac only; solve/reset-hide the reset spikes before calling it display-smooth.
7. For immediate extended-display-style use, keep `Virtual 16:9` set to `1920x1080`, run `scripts/start_2015_imac_receiver_macos.sh`, move windows onto `Virtual 16:9`, then run `scripts/start_mba_to_2015_imac_live_capture.sh`; stop with `scripts/stop_2015_imac_receiver_macos.sh`.
8. After a reboot/login, run `scripts/mac_clean_session_encoder_probe.sh` within 15 minutes. If both the first clean run and an immediate repeat pass 4096x2304/3200x1800 p95 <=16.67 ms, high-detail fallback switching can be reconsidered; otherwise keep product fallback limited to 2560x1440.
9. Test receiver decode separately on iMac Windows and iMac macOS: Media Foundation/D3D11 versus VideoToolbox/Metal.
10. Only after sender profiles and OS-specific decode candidates are settled, build tiled protocol metadata and receiver recomposition.
11. Implement dirty-region/cursor-separate logic after a live capture path exists, because static skipping alone only proves the encoder-side principle.
12. Capture screenshots and text-quality scoring after compressed decode/render works.
