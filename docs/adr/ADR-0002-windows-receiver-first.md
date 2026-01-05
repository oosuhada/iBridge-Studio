# ADR-0002 — Windows Receiver First

Status: accepted

## Context

The iMac currently boots Windows. Forcing macOS/OCLP before proving value adds friction.

## Decision

Implement macOS Primary → Windows Receiver first. macOS Receiver remains optional.

## Consequences

- More useful immediately on current hardware.
- Receiver implementation can use Windows graphics/media APIs.
- Mac-to-Mac AirPlay/Luna-like experiments are not blocked but are secondary.
