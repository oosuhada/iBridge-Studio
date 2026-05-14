# Implementation Roadmap

## Phase 0 — Repo and Environment Probe

Goal: Codex prepares the repo and probe scripts without writing the full app yet.

Deliverables:

- `scripts/mac_collect_env.sh`
- `scripts/windows_collect_env.ps1`
- `scripts/mac_network_probe.sh`
- `scripts/windows_receiver_probe.ps1`
- `logs/worklog.md` update

Verification:

- Scripts run or clearly state why they cannot run in the current environment.

## Phase 1 — Plan A: 5K60 First Spike

Goal: Test the highest target first.

Deliverables:

- Synthetic frame generator spec
- Windows fullscreen renderer that can display synthetic 5K60 frames locally
- Theoretical bandwidth report
- Transport throughput report
- Downshift decision document

Verification:

- `benchmarks/runs/.../summary.md` exists.
- Actual fps and render time are logged.

## Phase 2 — Core Pipeline

Goal: Build the smallest end-to-end display pipeline.

Deliverables:

- macOS Primary captures a display/window/virtual display candidate.
- Encodes frames with H.264 low latency.
- Sends frames over LAN.
- Windows Receiver decodes and renders fullscreen.
- HUD displays fps/latency/bitrate.

Verification:

- End-to-end video appears on iMac.
- 60-second run with logs.

## Phase 3 — Plan B: 5K60 Practical

Goal: 5K60 compressed mode.

Deliverables:

- HEVC path
- Thunderbolt Bridge profile
- local cursor overlay experiment
- static text quality mode

Verification:

- Compare 5K60 HEVC, 5K45 HEVC, 4K60, 1440p60.

## Phase 4 — Plan C: 60Hz Scaled Product Mode

Goal: Identify the best practical 60Hz mode.

Deliverables:

- 1440p60 integer scaling
- 4K60 mode
- 3200×1800 mode
- screenshot comparison report

Verification:

- At least one 60Hz mode is stable for 30 minutes.

## Phase 5 — Packaging and Usability

Goal: Make it usable.

Deliverables:

- Primary app CLI or simple GUI
- Receiver app packaging
- setup guide
- known limitations
- troubleshooting

## Phase 6 — macOS Receiver / OCLP path

Goal: Optional Mac-to-Mac path if Windows Receiver proves inadequate.

