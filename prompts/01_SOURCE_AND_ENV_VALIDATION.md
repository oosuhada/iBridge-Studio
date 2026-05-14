# Prompt 01 — Source and Environment Validation Sprint

Goal:
Before writing core display code, validate the technical assumptions in the repo and identify which claims are confirmed, plausible, or need local tests.

Tasks:

1. Read `docs/04_SOURCE_LEDGER.md`.
2. Re-check the most important source claims using official docs when possible:
   - iMac Late 2015 ports and 5K panel
   - Thunderbolt Bridge / IP over Thunderbolt
   - TB3-to-TB2 adapter limits
   - ScreenCaptureKit
   - VideoToolbox
   - Windows Media Foundation decode
   - Luna 5K/45Hz limitation
3. Update `docs/04_SOURCE_LEDGER.md` if a source is stale or insufficient.
4. Create `logs/source_validation.md` with:
   - confirmed claims
   - uncertain claims
   - local experiments required
5. Do not implement product code yet.

Verification:
- `logs/source_validation.md` exists.
- Every updated claim has `[내용 출처 : URL]` plain-text source.
- No proprietary reverse engineering instructions were added.
