# ADR-0001 — Use AGENTS.md as the single agent operating file

Status: accepted

## Context

Earlier drafts had AGENTS.md, CODEX.md, and CLAUDE.md. The user is delegating to Codex and requested consolidation.

## Decision

Use only AGENTS.md. Do not create CODEX.md or CLAUDE.md.

## Consequences

- Less duplication.
- Codex has one source of truth.
- Claude/Cursor can still read AGENTS.md if needed.
