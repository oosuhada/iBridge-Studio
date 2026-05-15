# Worklog

Codex must append entries here after every meaningful change.

## 2026-05-15 10:06 — Add local encoder reference clone workspace

Prompt: user request to clone and study open-source encoding/decoding references
Changed files:
- .gitignore
- reference/README.md
- docs/04_SOURCE_LEDGER.md
- logs/worklog.md
Verification:
- [x] Clone selected reference repositories under ignored `reference/`.
- [x] Search cloned repositories for capture, VideoToolbox, decode, transport, and frame pacing implementation targets.
- [x] Run git status and diff checks.
Result:
- Cloned seven reference repositories and recorded first-pass source map in `reference/README.md`.
Next:
- Decide whether the next iBridge implementation spike should target VideoToolbox property matrix, UDP/FEC transport, or Windows D3D11VA decode/render first.

## 2026-05-15 10:18 — Expand references for codec and Mac-Mac routes

Prompt: user clarified encoding/decoding references should be broader, and Mac-Mac should remain in scope if it has advantages
Changed files:
- reference/README.md
- docs/current-work.md
- logs/worklog.md
Verification:
- [x] Cloned additional codec, hardware SDK, Windows decode/render, WebRTC, transport, remote desktop, and macOS virtual display references under ignored `reference/`.
- [x] Recorded commit hashes for the expanded reference set.
- [x] Searched reference set for low-latency codec settings, hardware encode/decode paths, Media Foundation/D3D11VA, WebRTC/RTP packetization, and macOS virtual display APIs.
- [x] Run git status and diff checks.
Result:
- The local reference set now covers Windows and Mac-Mac routes instead of assuming macOS-to-Windows is the only target.
Next:
- Use `reference/README.md` to pick a focused next spike: Mac-Mac virtual display + VideoToolbox path, Windows D3D11VA receiver path, or transport/frame pacing path.

## 2026-05-14 22:08 — Prompt 00 repo assessment

Prompt: prompts/00_MASTER_PROMPT.md
Changed files:
- logs/worklog.md
Verification:
- [x] Read required Prompt 00 bootstrap files.
- [x] Inspected top-level repo structure, app placeholders, scripts, and git status.
- [ ] Git branch/status validation as normal repo skipped because /Users/gabrieljang/development/iBridge is not currently inside a Git worktree.
Result:
- Repo is in documentation/scaffold stage with app directories and probe scripts present, but no implementation project files yet.
Next:
- Start prompts/01_SOURCE_AND_ENV_VALIDATION.md by validating sources and running lightweight local environment probes.

## 2026-05-14 22:08 — Prompt 01 source and environment validation

Prompt: prompts/01_SOURCE_AND_ENV_VALIDATION.md
Changed files:
- .gitignore
- docs/04_SOURCE_LEDGER.md
- logs/source_validation.md
- logs/worklog.md
Verification:
- [x] Initialized Git repository on main and connected origin to https://github.com/oosuhada/iBridge.git.
- [x] Re-checked key Apple, Microsoft, and Astropad public source claims.
- [x] Ran scripts/mac_collect_env.sh logs/env successfully.
- [x] Wrote logs/source_validation.md with confirmed claims, uncertain claims, and required local experiments.
- [x] Kept product code unchanged.
Result:
- Prompt 01 validation is complete enough to proceed to environment probing and Plan A benchmark preparation.
Next:
- Run Windows receiver environment collection on the iMac.
- Start prompts/02_PLAN_A_5K60_FIRST_SPIKE.md after receiver/network facts are available or clearly logged as pending.

## 2026-05-14 22:20 — Prompt 02 Plan A 5K60 first spike

Prompt: prompts/02_PLAN_A_5K60_FIRST_SPIKE.md
Changed files:
- apps/receiver-windows/CMakeLists.txt
- apps/receiver-windows/README.md
- apps/receiver-windows/src/main.cpp
- benchmarks/theory/5k60_bandwidth.md
- benchmarks/plans/windows_synthetic_renderer.md
- benchmarks/plans/transport_benchmark.md
- benchmarks/runs/2026-05-14_2220_plan_a_pending/summary.md
- logs/experiments.md
- logs/questions.md
- logs/worklog.md
Verification:
- [x] Calculated 5K60 RGB24, YUV 4:2:0, and BGRA32 bandwidth with shell arithmetic.
- [x] Created a no-network Windows D3D11 synthetic renderer scaffold for 5120x2880 frame upload/draw/present timing.
- [x] Created Plan A transport benchmark plan for LAN and Thunderbolt Bridge iperf3/ping.
- [x] Wrote pending benchmark summary under benchmarks/runs/2026-05-14_2220_plan_a_pending/summary.md.
- [ ] Windows build/run skipped because this MacBook Air session does not have CMake, Windows SDK headers, or the Windows iMac receiver environment.
Result:
- Plan A is not downshifted. Raw RGB24 over 1GbE/TB2 looks mathematically constrained, but receiver render and measured transport data are still required.
Next:
- Build and run the synthetic renderer on the Windows iMac, then record receiver_stats.csv and a measured summary.

## 2026-05-15 01:07 — Record Plan A Windows synthetic benchmark result

Prompt: prompts/02_PLAN_A_5K60_FIRST_SPIKE.md
Changed files:
- benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/console.txt
- benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/receiver_stats.csv
- benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/run_status.txt
- benchmarks/runs/2026-05-15_0107_plan_a_synthetic_5k60/summary.md
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] Pulled result zip from Windows iMac over SSH/SCP.
- [x] Parsed console output and receiver_stats.csv.
- [x] Recorded actual fps, p95/max frame time, missed frame count, and likely bottleneck.
Result:
- Dynamic 5120x2880 CPU-filled BGRA32 full-frame upload measured 36.034 fps and missed every 16.667 ms frame budget.
Next:
- Run static-frame and no-vsync static-frame isolation variants from the iMac interactive desktop.

## 2026-05-15 01:20 — Prompt 09 review gate after Plan A spike

Prompt: prompts/09_REVIEW_GATE.md
Changed files:
- logs/review_gate.md
- logs/worklog.md
Verification:
- [x] Reviewed Prompt 02 against build/run/log/downshift criteria.
- [x] Confirmed measured Windows iMac result exists.
- [x] Confirmed no Plan A downshift was made without isolation follow-up.
Result:
- Prompt 02 passes review with required static/no-vsync isolation follow-up before Plan A closure.
Next:
- Start prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md.

## 2026-05-15 01:26 — Prompt 06 receiver synthetic isolation modes

Prompt: prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md
Changed files:
- apps/receiver-windows/README.md
- apps/receiver-windows/src/main.cpp
- benchmarks/runs/2026-05-15_0126_receiver_isolation_suite/*
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] Rebuilt `ibridge-receiver.exe` on Windows iMac with MSVC.
- [x] Ran dynamic 5K60, static once-upload 5K60, GPU-pattern 5K60, and GPU-pattern uncapped 5K60 from the active console session.
- [x] Recorded receiver CSV/console/status artifacts and summary.
Result:
- Dynamic CPU-filled full-frame BGRA upload measured 29.979 fps and failed the 5K60 frame budget.
- Static once-upload and GPU-pattern vsync modes reached about 61 fps.
- GPU-pattern no-vsync uncapped reached 290.663 fps.
Next:
- Run prompts/09_REVIEW_GATE.md for Prompt 06, then proceed to Prompt 05 if review passes.

## 2026-05-15 01:32 — Add receiver HUD overlay

Prompt: prompts/06_WINDOWS_RECEIVER_IMPLEMENTATION.md
Changed files:
- apps/receiver-windows/README.md
- apps/receiver-windows/src/main.cpp
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] Rebuilt `ibridge-receiver.exe` on Windows iMac with MSVC.
- [x] Ran interactive desktop HUD smoke test through Task Scheduler.
- [x] Smoke test exited with code 0 and reported `hud=on`.
Result:
- Receiver fullscreen synthetic runs now show a top-left HUD with mode, running fps, total frame time, fill time, upload time, and present time.
Next:
- Run prompts/09_REVIEW_GATE.md for Prompt 06.

## 2026-05-15 01:35 — Prompt 09 review gate after Windows receiver milestone

Prompt: prompts/09_REVIEW_GATE.md
Changed files:
- logs/review_gate.md
- logs/worklog.md
Verification:
- [x] Reviewed receiver build, interactive runs, benchmarks, logs, and known failures.
- [x] Confirmed network/decode/scaling receiver tasks remain explicitly open.
Result:
- Windows Receiver local benchmark milestone passes review; proceed to macOS Primary implementation while preserving receiver follow-ups.
Next:
- Start prompts/05_PRIMARY_MACOS_IMPLEMENTATION.md.

## 2026-05-15 01:40 — Prompt 05 macOS Primary synthetic encoder

Prompt: prompts/05_PRIMARY_MACOS_IMPLEMENTATION.md
Changed files:
- apps/primary-macos/Package.swift
- apps/primary-macos/README.md
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- benchmarks/runs/2026-05-15_0140_primary_1440p60_h264/*
- benchmarks/runs/2026-05-15_0140_primary_1440p60_hevc/*
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] H.264 synthetic 2560x1440 @ 60 target for 2 seconds encoded 120/120 frames.
- [x] HEVC synthetic 2560x1440 @ 60 target for 2 seconds encoded 120/120 frames.
Result:
- Primary synthetic source and VideoToolbox H.264/HEVC paths are functional.
- First encode latency measurements are too high for product use and require low-latency tuning.
Next:
- Run prompts/09_REVIEW_GATE.md for Prompt 05.

## 2026-05-15 01:45 — Prompt 09 review gate after macOS Primary milestone

Prompt: prompts/09_REVIEW_GATE.md
Changed files:
- logs/review_gate.md
- logs/worklog.md
Verification:
- [x] Reviewed Primary build, H.264/HEVC encode runs, benchmark summaries, and open failures.
Result:
- macOS Primary synthetic encode milestone passes review; ScreenCaptureKit capture and transport remain open.
Next:
- Start prompts/07_PROTOCOL_AND_TRANSPORT.md.

## 2026-05-15 01:52 — Prompt 07 protocol v0 and parser tests

Prompt: prompts/07_PROTOCOL_AND_TRANSPORT.md
Changed files:
- apps/shared-protocol/README.md
- apps/shared-protocol/protocol_v0.py
- apps/shared-protocol/test_protocol_v0.py
- specs/protocol_v0.md
- logs/worklog.md
Verification:
- [x] `python3 apps/shared-protocol/test_protocol_v0.py`
- [x] `git diff --check`
Result:
- Protocol v0 now defines TCP control negotiation, UDP frame chunks, TCP frame fallback, ping/echo clock-offset estimation, fixed 80-byte frame header, frame ids, timestamps, keyframe/config flags, payload length, and dropped-frame counters.
- Shared parser tests caught and fixed an initial header-size mismatch before commit.
Next:
- Run prompts/09_REVIEW_GATE.md for Prompt 07.

## 2026-05-15 01:56 — Prompt 09 review gate after protocol milestone

Prompt: prompts/09_REVIEW_GATE.md
Changed files:
- logs/review_gate.md
- logs/worklog.md
Verification:
- [x] Reviewed Prompt 07 against protocol fields, parser tests, version rejection, scope, and known runtime gaps.
Result:
- Protocol v0 parser/spec milestone passes review. Runtime sender/receiver integration remains open for Prompt 03.
Next:
- Start prompts/03_PLAN_B_5K60_PRACTICAL.md.

## 2026-05-15 02:38 — Prompt 03 Plan B compressed transport attempt

Prompt: prompts/03_PLAN_B_5K60_PRACTICAL.md
Changed files:
- apps/primary-macos/README.md
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- apps/receiver-windows/CMakeLists.txt
- apps/receiver-windows/README.md
- apps/receiver-windows/src/main.cpp
- benchmarks/runs/2026-05-15_0210_plan_b_5k_h264_tcp/*
- benchmarks/runs/2026-05-15_0220_plan_b_5k_hevc_local60/*
- benchmarks/runs/2026-05-15_0235_plan_b_5k_hevc_120mbps_local/*
- benchmarks/runs/2026-05-15_0238_plan_b_5k_hevc_120mbps_tcp/*
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] Windows MSVC build of `ibridge-receiver.exe`
- [x] H.264 5120x2880 @ 60 target encode/TCP attempt
- [x] HEVC 5120x2880 @ 60 target local encode attempt
- [x] HEVC 5120x2880 @ 60 target, 120Mbps, TCP sink attempt
Result:
- H.264 5K60 produced zero payloads with status -10279.
- HEVC 5K60 encoded locally, but encode latency was too high for 60Hz.
- HEVC 5K60 120Mbps TCP reached the Windows sink with all 60 frames, but took 38.60 seconds and measured only 3.092 Mbps receive throughput on the current path.
Next:
- Run prompts/09_REVIEW_GATE.md for Prompt 03 before moving to Plan C.

## 2026-05-15 02:45 — Prompt 09 review gate after Plan B

Prompt: prompts/09_REVIEW_GATE.md
Changed files:
- logs/review_gate.md
- logs/worklog.md
Verification:
- [x] Reviewed Prompt 03 against 5K compressed attempt, build/run/log, failure classification, and downshift criteria.
Result:
- Prompt 03 passes as a measured failed Plan B attempt with decode/render gap explicitly open.
Next:
- Start prompts/04_PLAN_C_60HZ_SCALED_MODES.md.

## 2026-05-15 02:55 — Prompt 04 Plan C scaled modes

Prompt: prompts/04_PLAN_C_60HZ_SCALED_MODES.md
Changed files:
- apps/receiver-windows/README.md
- apps/receiver-windows/src/main.cpp
- benchmarks/runs/2026-05-15_0255_plan_c_scaled_modes/*
- logs/experiments.md
- logs/worklog.md
- specs/protocol_v0.md
Verification:
- [x] Windows MSVC build of `ibridge-receiver.exe`
- [x] iMac Windows D3D11 scaled-render suite through Task Scheduler
- [x] macOS Primary HEVC 120Mbps local encode suite
Result:
- All receiver scaled-render modes reached about 60fps.
- 3200x1800 had the best short-run Primary HEVC encode latency.
- Screenshot/text-quality scoring remains pending because compressed decode/render is not implemented.
Next:
- Run prompts/09_REVIEW_GATE.md for Prompt 04.

## 2026-05-15 03:02 — Prompt 09 review gate after Plan C

Prompt: prompts/09_REVIEW_GATE.md
Changed files:
- logs/review_gate.md
- logs/worklog.md
Verification:
- [x] Reviewed Prompt 04 against mode comparison, logs, build/run verification, and visual-quality gaps.
Result:
- Prompt 04 passes as an engineering comparison; screenshot/text-quality scoring remains pending.
Next:
- Start prompts/08_POWER_PROBE.md.

## 2026-05-15 03:08 — Prompt 08 power probe setup

Prompt: prompts/08_POWER_PROBE.md
Changed files:
- logs/power_probe.md
- logs/worklog.md
- scripts/mac_power_probe.sh
Verification:
- [x] `scripts/mac_power_probe.sh`
- [x] `pmset -g batt`
- [x] `system_profiler SPPowerDataType`
- [x] `ioreg -rn AppleSmartBattery`
Result:
- Current MacBook Air snapshot is battery power, 98%, not charging, no AC charger connected.
- Manual test matrix is documented for no cable, iMac USB-A, iMac TB2 adapter, and PD hub baseline across idle/streaming workloads.
Next:
- Run prompts/09_REVIEW_GATE.md for Prompt 08.

## 2026-05-15 03:12 — Prompt 09 review gate after power probe

Prompt: prompts/09_REVIEW_GATE.md
Changed files:
- logs/review_gate.md
- logs/worklog.md
Verification:
- [x] Reviewed Prompt 08 against script, current baseline, manual matrix, and no-wattage-claim rule.
Result:
- Prompt 08 passes as a setup/current-snapshot probe; physical cable/drain-rate tests remain pending.
Next:
- Do not run prompts/10_PACKAGING_AND_RELEASE.md until an end-to-end display mode works.

## 2026-05-15 08:54 — Focused Plan C pipeline spike setup

Prompt: user-requested Plan C end-to-end preparation after Plan B/Plan C findings
Changed files:
- apps/primary-macos/README.md
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- apps/receiver-windows/CMakeLists.txt
- apps/receiver-windows/README.md
- apps/receiver-windows/src/main.cpp
- benchmarks/plans/network_matrix.md
- benchmarks/runs/2026-05-15_0854_encoder_lowlatency/*
- benchmarks/runs/2026-05-15_encoder_matrix_smoke/*
- benchmarks/runs/2026-05-15_primary_lowlatency_smoke/*
- benchmarks/runs/2026-05-15_sender_queue_loopback_smoke/*
- benchmarks/runs/primary_encoder_list_latest.txt
- docs/04_SOURCE_LEDGER.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- scripts/mac_network_matrix.sh
- scripts/mac_plan_c_encode_matrix.sh
- scripts/windows_network_matrix.ps1
Verification:
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] `ibridge-primary --list-encoders`
- [x] `ibridge-primary` HEVC 2560x1440 120Mbps 5s local encode
- [x] `ibridge-primary` HEVC 3200x1800 120Mbps 5s local encode
- [x] `ibridge-primary` H.264 5120x2880 120Mbps 1s probe
- [x] Loopback TCP drain with `nc` confirmed async sender queue records send timing without receiver app.
- [x] `LIMIT_CASES=1 DURATION=1 scripts/mac_plan_c_encode_matrix.sh`
- [ ] Windows MSVC build skipped because SSH to `100.86.52.88` failed with `Permission denied` and this MacBook Air does not have the Windows SDK.
- [ ] LAN/Thunderbolt Bridge network matrix skipped because physical cables are not attached in this session.
Result:
- Primary callback timing and socket send timing are now separated in CSV diagnostics.
- Network matrix docs/scripts leave explicit room for 5GHz Wi-Fi, 1GbE LAN, Thunderbolt Bridge, and Tailscale direct/relay tests.
- Offline Windows compressed file decode/render path is implemented but not yet built on Windows.
Next:
- Build the receiver on Windows and run `--decode-file` with a known-good compressed sample.
- Extend decode from offline files to protocol v0 TCP payloads.
- Run live Plan C end-to-end before UDP or tiled 5K work.

## 2026-05-15 10:12 — MacBook Pro Primary comparison

Prompt: user requested cloning iBridge to the MacBook Pro and testing the MBP environment
Changed files:
- apps/primary-macos/README.md
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- benchmarks/runs/2026-05-15_0950_mbp_environment_baseline/*
- benchmarks/runs/2026-05-15_0952_mbp_encoder_baseline/*
- benchmarks/runs/2026-05-15_1000_mbp_encoder_id_probe/*
- benchmarks/runs/2026-05-15_1005_mbp_to_imac_tailscale_probe/*
- benchmarks/runs/2026-05-15_1010_mbp_display_capture_smoke/*
- benchmarks/runs/2026-05-15_1012_mbp_display_resolution_encode/*
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] Cloned `feat/plan-a-5k60-benchmark` into `/Users/gabriel/Development/iBridge`.
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] `python3 apps/shared-protocol/test_protocol_v0.py`
- [x] `ibridge-primary --list-encoders`
- [x] MBP automatic encoder baseline for HEVC/H.264 Plan C modes.
- [x] Added and built `--encoder-id` option for VideoToolbox encoder isolation.
- [x] MBP forced `ave.hevc` encoder probe.
- [x] `screencapture` captured built-in, external portrait, Sidecar, and external FHD displays.
- [x] Display-resolution synthetic encode probe for all four active displays.
- [x] Tailscale reachability probe to Windows iMac.
- [ ] Live receiver send/decode test skipped because Windows iMac receiver port `48320` was not listening and SSH auth from this MBP is blocked.
Result:
- Best MBP Plan C result is HEVC 3200x1800 @ 60, 120Mbps with forced `com.apple.videotoolbox.videoencoder.ave.hevc` and low-latency rate-control disabled: avg encode 16.612 ms, p95 16.777 ms.
- H.264 5K still fails with payload 0.
- Sidecar and both external displays are visible to macOS and capturable by `screencapture`, but iBridge live ScreenCaptureKit capture is not implemented yet.
Next:
- Authorize MBP SSH key on the Windows iMac or manually start the receiver on the iMac.
- Run live TCP Plan C from MBP using forced `ave.hevc`.
- Keep LAN/Thunderbolt Bridge tests separate from Tailscale.

## 2026-05-15 10:40 — Reference technology analysis and iMac prep

Prompt: user requested deeper reference analysis and actionable prep before physical iMac access
Changed files:
- docs/04_SOURCE_LEDGER.md
- docs/11_REFERENCE_TECH_ANALYSIS.md
- docs/12_IMAC_SETUP_PREP.md
- docs/current-work.md
- logs/worklog.md
- reference/README.md
- scripts/windows_imac_setup_inventory.ps1
Verification:
- [x] Removed nested `.git` directories from ignored `reference/` clones.
- [x] Confirmed no nested `.git` directories remain under `reference/`.
- [x] Reviewed reference implementations for virtual displays, ScreenCaptureKit, VideoToolbox properties, Annex-B adaptation, UDP/RTP packetization, frame pacing, and D3D11VA decode/render.
- [x] Added a Windows iMac inventory script that avoids printing SSH key contents or environment secrets.
Result:
- Reference analysis now maps mature implementations to iBridge-specific next spikes instead of only listing repositories.
- Mac-to-Mac is treated as a first-class route, with local Mac virtual-display smoke testing identified as the safest immediate experiment.
- Remote macOS installation/boot switching is classified as unsafe until an existing macOS volume and remote recovery path are confirmed.
Next:
- Run the Windows inventory script from RDP or an already-authorized shell on the iMac.
- Choose the next implementation spike: VT property matrix plus Annex-B fixture path, or Windows compressed decode/render smoke.

## 2026-05-15 11:00 — Encoding-first VT property spike

Prompt: user challenged whether Plan A/B encode is satisfied before any iMac connection
Changed files:
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- apps/primary-macos/README.md
- benchmarks/runs/2026-05-15_1056_vt_property_matrix/*
- benchmarks/runs/2026-05-15_1058_vt_targeted_sustain/*
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- scripts/mac_vt_property_matrix.sh
Verification:
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] `python3 apps/shared-protocol/test_protocol_v0.py`
- [x] `bash -n scripts/mac_vt_property_matrix.sh`
- [x] `DURATION=2 FPS=60 scripts/mac_vt_property_matrix.sh`
- [x] Targeted 5-second sustained probes for 3200x1800, 3840x2160, 4096x2304, and 5120x2880.
Result:
- Added explicit VT controls for temporal compression, frame reordering, open GOP, speed priority, max frame delay count, DataRateLimits, and Annex-B payload extraction.
- Corrected default encode policy to allow temporal compression while keeping frame reordering disabled.
- Plan B 5K60 still fails before receiver connection: best 5K sustained probe was avg 100.617 ms, p95 119.982 ms.
- 3200x1800 and 3840x2160 with forced `ave.hevc`, no low-latency RC, and DataRateLimits fit the synthetic encode-only 60 Hz budget in the 5-second probe.
Next:
- Compare these settings against real ScreenCaptureKit/IOSurface frames before proceeding deeper into receiver integration.

## 2026-05-15 11:32 — Encode source strategy matrix

Prompt: user requested tests for ScreenCaptureKit/IOSurface, NV12 input, unchanged-frame skipping, tiled encoding, and 5K45/5K30 before iMac connection
Changed files:
- apps/primary-macos/Package.swift
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- apps/primary-macos/README.md
- benchmarks/runs/2026-05-15_1129_encode_strategy_matrix/*
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- scripts/mac_encode_strategy_matrix.sh
Verification:
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] `bash -n scripts/mac_encode_strategy_matrix.sh`
- [x] `DURATION=3 scripts/mac_encode_strategy_matrix.sh`
- [x] Targeted ScreenCaptureKit 5120x2880 @ 60 follow-up.
Result:
- Added source modes for `synthetic-bgra`, `synthetic-nv12`, `synthetic-static-skip`, and `screen-capture`.
- ScreenCaptureKit real capture can now feed VideoToolbox directly.
- Single-session 5K60 HEVC still fails badly even with ScreenCaptureKit and NV12-style improvements.
- 3840x2160 and 4096x2304 NV12 synthetic 60Hz look strong; ScreenCaptureKit 4K60 is close but p95 is still above 16.67 ms in this 3s run.
- 2x2 tiled 5K60 approximation shows per-tile encode latency inside the 60Hz budget, but tiled protocol/recomposition is not implemented.
Next:
- Treat tiled encoding as the next Plan B experiment if preserving 5K logical resolution matters.
- Treat 4096x2304 or 3840x2160 as the stronger single-session 60Hz fallback candidates.

## 2026-05-15 11:45 — In-process tiled encode follow-up

Prompt: user asked whether NV12 4K/4096x2304 and tiled encoding were actually tested, then asked to continue the next step
Changed files:
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- apps/primary-macos/README.md
- benchmarks/runs/2026-05-15_1138_inprocess_tiled_5k60/*
- benchmarks/runs/2026-05-15_1140_inprocess_tiled_reuse_5k60/*
- benchmarks/runs/2026-05-15_1141_inprocess_tiled_reuse_steady_5k60/*
- benchmarks/runs/2026-05-15_1141_inprocess_tiled_long_gop_5k60/*
- benchmarks/runs/2026-05-15_1142_inprocess_tiled_h264_5k60/*
- benchmarks/runs/2026-05-15_1143_sck_4096x2304_duration_5s/*
- benchmarks/runs/2026-05-15_1144_sck_3840x2160_duration_5s/*
- benchmarks/runs/2026-05-15_1144_nv12_3840x2160_5s_solo/*
- benchmarks/runs/2026-05-15_1144_nv12_4096x2304_5s_solo/*
- benchmarks/runs/2026-05-15_1144_encode_followup/summary.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- scripts/mac_encode_strategy_matrix.sh
Verification:
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] In-process 2x2 HEVC tiled 5K60 fresh NV12 tile probe.
- [x] In-process 2x2 HEVC tiled 5K60 reusable-buffer lower-bound probes.
- [x] In-process 2x2 H.264 tiled 5K60 probe.
- [x] ScreenCaptureKit 3840x2160 and 4096x2304 duration-based probes.
- [x] Solo synthetic NV12 3840x2160 and 4096x2304 5-second sustained probes.
Result:
- `synthetic-nv12-tiled` now measures synchronized logical-frame completion time inside one Primary process.
- Solo synthetic NV12 3840x2160 @ 60 passes 5-second encode budget: avg 11.297 ms, p95 11.665 ms.
- Solo synthetic NV12 4096x2304 @ 60 passes 5-second encode budget: avg 12.629 ms, p95 12.957 ms.
- In-process 2x2 HEVC tiled 5K60 has a promising short-run lower bound, but fails sustained 5-second testing due to accumulated VideoToolbox latency after about 3 seconds.
- In-process 2x2 H.264 tiled 5K60 is not viable.
- ScreenCaptureKit duration probes show fewer than target frames on a static screen; treat SCK as changed-frame driven, not as proof of continuous 60fps full-frame capture.
Next:
- Prefer single-session 4096x2304 or 3840x2160 for the next receiver/decode step.
- Keep tiled 5K60 as a research branch only until backpressure/drop/staggering can keep four sessions sustainable.

## 2026-05-15 12:13 — Tiled 5K60 backpressure and reset probe

Prompt: user asked to continue from the previous tiled 5K60 result and investigate it first because Plan A targets 5K60
Changed files:
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- apps/primary-macos/README.md
- scripts/mac_encode_strategy_matrix.sh
- benchmarks/runs/2026-05-15_1206_tiled_5k60_backpressure_probe/*
- benchmarks/runs/2026-05-15_1207_tiled_5k60_pts_fix_probe/*
- benchmarks/runs/2026-05-15_1209_tiled_5k60_tile_shape_probe/*
- benchmarks/runs/2026-05-15_1211_tiled_5k60_session_reset_probe/*
- benchmarks/runs/2026-05-15_1212_tiled_5k60_reset_sustain_10s/*
- benchmarks/runs/2026-05-15_1213_tiled_5k60_reset_sustain_30s/*
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] 2x2 tiled 5K60 backpressure matrix.
- [x] 2x2 tiled 5K60 PTS-fix probe.
- [x] 1x4/2x2/4x1/4x2/2x4 tile-shape probe.
- [x] 2x2 session-reset probe.
- [x] 10-second 2x2 reset150/inflight1 sustained probe at 30Mbps/tile and 60Mbps/tile.
- [x] 30-second 2x2 reset150/inflight1 sustained probe at 30Mbps/tile.
Result:
- Fixed the in-process tiled benchmark PTS bug: each tile encoder now gets per-session logical-frame PTS instead of interleaved global frame IDs.
- Added `--tile-max-inflight-logical-frames` and `--tile-reset-every-frames`.
- No-reset tiled 5K60 still fails sustained 5-second p95 after about frame 180.
- `2x2`, `30Mbps/tile`, `reset150`, `inflight1` sustained 30 seconds at effective 60.002fps with avg 12.374 ms and p95 12.920 ms.
- Reset-frame max spikes remain around 100-133 ms and are the main caveat before this can become a smooth display path.
Next:
- Keep tiled 5K60 as the top Plan B prototype candidate if preserving full 5120x2880 logical resolution matters.
- Investigate reset-spike mitigation before receiver work, or design the receiver protocol so reset/keyframe spikes can be dropped, hidden, or staggered.
- Add tiled metadata/decode/recomposition only after deciding how to handle reset spikes.

## 2026-05-15 12:22 — Tiled 5K60 strategy and reset180 probe

Prompt: user asked whether 2x2 tiled 5K60 is viable and asked to search current encoding trends while improving the approach
Changed files:
- docs/04_SOURCE_LEDGER.md
- docs/13_TILED_5K60_STRATEGY.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- scripts/analyze_tiled_deadline.py
- benchmarks/runs/2026-05-15_1220_tiled_5k60_reset_interval_probe/*
- benchmarks/runs/2026-05-15_1222_tiled_5k60_reset180_sustain_30s/*
Verification:
- [x] Searched Apple and NVIDIA primary/official sources for VideoToolbox, ScreenCaptureKit queue behavior, split-frame encoding, and low-latency HEVC trends.
- [x] `scripts/analyze_tiled_deadline.py` generated deadline analysis for the reset180 30-second run.
- [x] 20-second reset interval probe for reset150/reset180/reset210.
- [x] 30-second reset180 sustain probe.
Result:
- reset180/inflight1 improved the tiled HEVC path to 30-second avg 12.100 ms, p95 12.690 ms, effective 60.009 fps.
- reset210 failed p95, so the useful reset interval is currently around 180 logical frames.
- Deadline analysis shows only 18/1800 logical frames exceed 16.67 ms and 10/1800 exceed 33.33 ms.
- Current encoding trends support the manual tiled direction: NVIDIA's current split-frame encoding for HEVC/AV1 uses independent frame partitions to increase single-stream speed when one encoder is not enough.
Next:
- Build receiver-side tiled composition with stale-tile reuse and HUD counters before trying full tiled decode.
- Add tiled protocol metadata after the synthetic receiver composition path is clear.

## 2026-05-15 12:54 — Sender transmission profile matrix

Prompt: user corrected the next step away from Windows tiled rendering and toward sender-side profiles for M1 Max/M1 Air wired/wireless combinations.
Changed files:
- docs/04_SOURCE_LEDGER.md
- docs/14_TRANSMISSION_PROFILE_MATRIX.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- scripts/mac_transmission_profile_matrix.sh
- benchmarks/runs/2026-05-15_1258_transmission_profile_matrix/*
Verification:
- [x] Searched current Apple official sources for M1 Max media engines, M1 media engine context, current MacBook Pro AV1 decode direction, M1 Air ports/Wi-Fi, Thunderbolt Bridge, and iMac 2015 connection limits.
- [x] `bash -n scripts/mac_transmission_profile_matrix.sh`
- [x] `DEVICE_PROFILE=m1max PROFILE_SET=quick DURATION=5 RUN_ROOT=benchmarks/runs/2026-05-15_1258_transmission_profile_matrix scripts/mac_transmission_profile_matrix.sh`
Result:
- Added an encode-first transmission profile matrix for M1 Max/M1 Air and wired/wireless paths.
- Added a repeatable sender profile benchmark script that records sanitized system profile data, encoder list, per-case logs, summary CSV, and tiled deadline analysis.
- Current M1 Max quick retest keeps 2x2 tiled HEVC 5K60 promising: avg 12.501 ms, p95 13.222 ms, effective 60.040 fps; 2/300 logical frames exceeded 16.67 ms.
- Current single-stream fallback retests were slower than earlier runs, so 4096x2304/3200x1800 should be re-isolated before becoming default profiles.
Next:
- Run the Air profile set on the M1 Air.
- Run wired M1 Max tests after Thunderbolt Bridge or 1GbE is physically connected.
- Defer receiver decode/recomposition work until sender profiles and iMac OS-specific decode targets are clearer.

## 2026-05-15 13:40 — Single-stream fallback stability isolation

Prompt: user asked MBP Codex to continue with M1 Max single-stream, wired/wireless profile, and later decode planning work while waiting for cables and M1 Air results.
Changed files:
- scripts/mac_single_stream_stability_matrix.sh
- scripts/mac_transmission_profile_matrix.sh
- docs/14_TRANSMISSION_PROFILE_MATRIX.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- benchmarks/runs/2026-05-15_1330_single_stream_stability_unset/*
- benchmarks/runs/2026-05-15_1333_single_stream_stability_speed_on/*
- benchmarks/runs/2026-05-15_1338_transmission_profile_recheck/*
- benchmarks/runs/2026-05-15_1341_post_tiled_recovery/*
Verification:
- [x] `bash -n scripts/mac_single_stream_stability_matrix.sh`
- [x] 3-repeat isolated single-stream matrix with `PRIORITIZE_SPEED=unset`
- [x] 3-repeat isolated single-stream matrix with `PRIORITIZE_SPEED=on`
- [x] Re-ran transmission quick matrix to reproduce slow single-stream after tiled-first order.
Result:
- Added a single-stream stability matrix for 4096x2304, 3840x2160, 3200x1800, and 2560x1440.
- Isolated single-stream HEVC profiles passed p95 <=16.67 ms across all tested repeats.
- Tiled-first mixed-order tests still made immediate single-stream fallback results slow, and 4096x2304 remained slow after a 60-second wait.
- Updated transmission matrix ordering so single-stream probes run before tiled probes.
Next:
- Do not benchmark fallback profiles immediately after tiled 5K60.
- Investigate safe VideoToolbox encoder-service reset/restart before product-mode fallback switching.
- Run network matrices after Thunderbolt Bridge and Ethernet cables arrive.

## 2026-05-15 13:58 — Encoder service restart probe

Prompt: continue local MBP work by testing whether post-tiled fallback slowdown can be recovered before cables arrive.
Changed files:
- docs/14_TRANSMISSION_PROFILE_MATRIX.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- benchmarks/runs/2026-05-15_1358_encoder_service_restart_probe/*
Verification:
- [x] Restarted user `VTEncoderXPCService` and reran 4096x2304 fallback.
- [x] Rechecked 4096x2304 after 60 seconds and with `prioritize_speed=unset`.
- [x] Checked 3200x1800 and 2560x1440 post-slow-state fallback behavior.
Result:
- `VTEncoderXPCService` restart did not recover 4096x2304 or 3200x1800 performance after tiled contamination.
- 2560x1440 stayed within budget and is the current safest emergency fallback after tiled 5K60.
Next:
- Treat high-detail fallback switching after tiled 5K60 as unsafe until a stronger reset/session strategy is proven.
- Keep waiting for M1 Air results and physical cable tests for Thunderbolt Bridge / Ethernet.

## 2026-05-15 14:24 — Encoder reset/session strategy probe

Prompt: user asked to find stronger encoder reset/session strategies using references.
Changed files:
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- scripts/mac_encoder_reset_strategy_probe.sh
- docs/04_SOURCE_LEDGER.md
- docs/15_ENCODER_RESET_STRATEGY.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- benchmarks/runs/2026-05-15_1415_encoder_reset_strategy_probe/*
- benchmarks/runs/2026-05-15_1424_encoder_reset_strategy_probe_summary_fix/*
Verification:
- [x] Searched Apple VideoToolbox docs for compression-session lifecycle, prepare, complete, parallelization, concatenate hints, source frame count, and max frame delay.
- [x] Inspected local FFmpeg, OBS, and Swift Transcoding VideoToolbox references.
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] `bash -n scripts/mac_encoder_reset_strategy_probe.sh`
- [x] `DURATION=6 RUN_FALLBACK=1 RUN_ROOT=benchmarks/runs/2026-05-15_1415_encoder_reset_strategy_probe scripts/mac_encoder_reset_strategy_probe.sh`
- [x] `DURATION=6 RUN_FALLBACK=0 RUN_ROOT=benchmarks/runs/2026-05-15_1424_encoder_reset_strategy_probe_summary_fix scripts/mac_encoder_reset_strategy_probe.sh`
Result:
- Added VideoToolbox segment-hint controls: `MoreFramesBeforeStart`, `MoreFramesAfterEnd`, and `SourceFrameCount`.
- Added tiled automatic segment hints and staggered per-tile reset probing.
- Segment hints reduced short-run logical frames over 16.67 ms compared with baseline simultaneous reset.
- Staggered reset lowered the worst max spike but spread reset misses across more logical frames, so it is not the default candidate yet.
- Post-probe high-detail fallback remained slow, but this was not a clean A/B because the machine was already in a post-tiled slow state.
Next:
- From a known-clean login/reboot state, run segment-hints tiled first and immediately test high-detail fallback recovery.
- Keep `2560x1440@60` as the safe emergency fallback until clean-session recovery is proven.

## 2026-05-15 15:53 — Clean-session fallback gate script

Prompt: user asked to proceed with the remaining clean-session test.
Changed files:
- scripts/mac_clean_session_encoder_probe.sh
- docs/15_ENCODER_RESET_STRATEGY.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
- benchmarks/runs/2026-05-15_1550_clean_session_probe_guard/*
- benchmarks/runs/2026-05-15_1552_dirty_session_encoder_probe/*
- benchmarks/runs/2026-05-15_1553_dirty_session_encoder_probe_repeat/*
Verification:
- [x] `bash -n scripts/mac_clean_session_encoder_probe.sh`
- [x] `swift build --package-path apps/primary-macos -c release`
- [x] Clean-session guard run skipped current session because uptime was 2936 minutes.
- [x] Dirty current-session control run.
- [x] Dirty current-session repeat run.
Result:
- Added a dedicated clean-session gate script that refuses valid runs after `CLEAN_BOOT_MAX_MINUTES` unless explicitly overridden.
- Current session was not clean enough for the requested proof.
- Dirty controls were mixed: the first run passed high-detail fallback, but the immediate repeat failed 4096x2304/3200x1800 fallback p95 badly.
Next:
- After reboot/login, run `scripts/mac_clean_session_encoder_probe.sh` within 15 minutes and repeat once if it passes.
- Keep product emergency fallback at `2560x1440@60` until both clean runs pass.

## 2026-05-15 13:18 — M1 Air sender profile matrix

Prompt: user asked to pull latest branch and run the M1 Air encode-only sender profile matrix
Changed files:
- apps/primary-macos/Sources/iBridgePrimary/main.swift
- benchmarks/runs/2026-05-15_1306_transmission_profile_matrix/*
- docs/14_TRANSMISSION_PROFILE_MATRIX.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] `git status -sb`
- [x] `git pull --rebase`
- [x] `hostname && whoami && pwd && sysctl -n hw.model`
- [x] `DEVICE_PROFILE=m1air PROFILE_SET=air DURATION=30 scripts/mac_transmission_profile_matrix.sh`
- [x] `bash -n scripts/mac_transmission_profile_matrix.sh`
- [x] `swift build --package-path apps/primary-macos -c release`
Result:
- The latest branch fast-forwarded cleanly before local work.
- Added `@preconcurrency import ScreenCaptureKit` so Swift 6 can build the benchmark on the M1 Air without treating `SCStream` Sendable warnings as errors.
- M1 Air `2560x1440 @ 60` HEVC passed the sender p95 budget: avg 8.145 ms, p95 9.296 ms, max 20.146 ms.
- M1 Air `3200x1800 @ 60`, `3840x2160 @ 60`, and 2x2 tiled `5120x2880 @ 60` failed the 16.67 ms p95 encode budget.
- The tiled Air probe reached only 41.599 effective logical fps and had 1800/1800 logical frames over 16.67 ms.
Next:
- Treat `2560x1440 @ 60` HEVC as the realistic M1 Air default.
- Keep tiled 5K60 focused on M1 Max/best-wired paths; do not implement an Air-specific tiled receiver path from this result.

## 2026-05-15 13:45 — Plan next transport gate

Prompt: user confirmed the MBP vs M1 Air tiled speed gap and asked to plan/proceed with the next step
Changed files:
- benchmarks/runs/2026-05-15_1344_mbp_current_path_probe/*
- docs/14_TRANSMISSION_PROFILE_MATRIX.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] `ssh macbook-pro 'hostname; whoami; pwd'`
- [x] `ssh macbook-pro 'cd ~/development/iBridge && git pull --rebase'`
- [x] `ssh macbook-pro 'networksetup -listallhardwareports; ifconfig ...'`
- [x] `ssh macbook-pro 'ping -c 20 100.86.52.88'`
Result:
- MacBook Pro repo is updated to the Air result commit.
- MacBook Pro currently has Wi-Fi active; Thunderbolt Bridge and USB/Ethernet adapter interfaces are inactive.
- Current Tailscale path to the Windows iMac is reachable but jittery: min/avg/max/stddev `9.451/73.839/507.671/107.944 ms`.
Next:
- Run `scripts/mac_network_matrix.sh` on the MacBook Pro only after Thunderbolt Bridge or 1GbE is physically connected and an `iperf3` server is running on the iMac.
- Keep receiver tiled composition deferred until sender profile plus physical transport have a credible path.

## 2026-05-15 13:51 — Current Tailscale network matrix

Prompt: user asked to continue the next experiment
Changed files:
- benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix/*
- docs/14_TRANSMISSION_PROFILE_MATRIX.md
- docs/current-work.md
- logs/experiments.md
- logs/worklog.md
Verification:
- [x] `ssh macbook-pro 'cd ~/development/iBridge && DURATION=10 RUN_ROOT=benchmarks/runs/2026-05-15_1349_current_tailscale_network_matrix scripts/mac_network_matrix.sh --case tailscale --receiver-ip 100.86.52.88 --tailscale-name 100.86.52.88'`
- [x] Copied the MBP artifact back into this repo and removed the untracked remote copy.
- [x] `bash -n scripts/mac_network_matrix.sh`
Result:
- Current MBP-to-iMac Tailscale path had 100-packet ping loss/jitter: 98/100 received, 2.0% loss, min/avg/max/stddev `8.198/61.867/485.532/58.935 ms`.
- MBP did not have `iperf3` installed, so throughput was not measured.
- MBP SSH shell did not expose `tailscale` CLI, so direct/DERP status was not captured.
Next:
- Install or expose `iperf3` on MBP and iMac before throughput experiments.
- Run the real transport matrix only after Thunderbolt Bridge or 1GbE is active.
