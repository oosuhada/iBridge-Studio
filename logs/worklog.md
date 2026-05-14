# Worklog

Codex must append entries here after every meaningful change.

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
