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
