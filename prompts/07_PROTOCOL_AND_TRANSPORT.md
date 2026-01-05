# Prompt 07 — Shared Protocol and Transport

Goal:
Define a minimal frame protocol for Primary ↔ Receiver.

Requirements:

- versioned header
- mode negotiation
- resolution/fps/codec metadata
- frame ids
- timestamps for latency breakdown
- keyframe flag
- payload length
- dropped frame accounting

Start simple:

1. TCP handshake/control channel.
2. UDP frame channel for low latency.
3. TCP-only fallback for debugging.

Do not implement a complex distributed system. This is a local point-to-point display link.

Verification:
- `specs/protocol_v0.md` updated.
- unit test or parser test for header encode/decode.
- receiver rejects wrong version cleanly.
