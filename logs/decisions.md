# Decisions

ADR summaries.

## 2026-05-15 12:54 — Encode-first profile matrix before receiver recomposition

Decision:
- Do not build Windows receiver synthetic tiled recomposition as the immediate next step.
- First classify sender-side profiles by source Mac and connection class: M1 Max/M1 Air, wired/wireless, full 5K tiled versus single-stream fallbacks.
- Test receiver decode later on the 2015 iMac in both Windows and macOS environments after macOS is installed.

Reason:
- The commercial shape of iBridge needs versatile sender/connection profiles, not a single receiver-specific prototype.
- Current evidence says M1 Max 2x2 tiled HEVC is promising for full-resolution wired sender work, while Air and wireless profiles are still unproven.

## 2026-05-15 13:40 — Do not mix tiled-first benchmarks with fallback profile selection

Decision:
- Run single-stream fallback profile benchmarks before tiled 5K60, or in a separate clean session.
- Treat tiled-first single-stream follow-up results as pessimistic until a safe VideoToolbox reset strategy exists.

Reason:
- Isolated 4096x2304, 3840x2160, 3200x1800, and 2560x1440 HEVC profiles all passed p95 <=16.67 ms across 3/3 repeats.
- Running 2x2 tiled 5K60 first reproduced slow immediate single-stream results, and 4096x2304 remained slow after a 60-second wait.

## 2026-05-15 13:58 — Emergency fallback after tiled 5K60 is 2560x1440 until stronger reset is proven

Decision:
- Do not assume `VTEncoderXPCService` restart is enough to recover high-detail single-stream fallback after tiled 5K60.
- If tiled 5K60 has been active and the app must downshift immediately, treat `2560x1440@60` as the current safe emergency fallback.

Reason:
- Restarting user `VTEncoderXPCService` did not recover 4096x2304 p95; it stayed around 46.5 ms.
- 3200x1800 also stayed slow after the post-tiled state.
- 2560x1440 remained inside budget at p95 10.808 ms.
