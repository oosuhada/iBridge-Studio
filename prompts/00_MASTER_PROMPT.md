# Prompt 00 — Codex Master Bootstrap

You are working on iBridge, not on a documentation-only harness.

Read these files first, in order:

1. `README.md`
2. `AGENTS.md`
3. `docs/01_DEV_GUIDE_v0.2.md`
4. `docs/02_ARCHITECTURE.md`
5. `docs/03_DISPLAY_QUALITY_STRATEGY.md`
6. `docs/07_IMPLEMENTATION_ROADMAP.md`
7. `docs/08_VALIDATION_PROTOCOL.md`

Project goal:
Build software that lets an M1/M-series MacBook use a 2015 27-inch iMac Retina 5K as a secondary display without hardware modification.

Important current environment:
- The iMac currently boots Windows.
- Therefore initial implementation is macOS Primary → Windows Receiver.
- macOS Receiver/OCLP is optional and secondary.

Quality ladder:
1. Start with Plan A: 5K 60Hz raw/near-raw feasibility.
2. If Plan A fails, downshift only after logging measured reasons.
3. Then Plan B: 5K 60Hz practical compressed mode.
4. Then Plan C: 60Hz scaled modes optimized for the 5K panel.

Your first task:
Do not implement immediately. Produce a concise repo assessment and a first execution plan.

Required output:
- Assumptions
- Unknowns
- Files you will inspect/create
- 3-step plan with verification for each step
- First branch name
- First commit plan

Do not create CODEX.md or CLAUDE.md. AGENTS.md is the single operating contract.
