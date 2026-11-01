# PsychopatzCore Modular Capability & Composition Refactor — Agent Runbook

## Read order

Read root `AGENTS.md`, then this runbook, `ROADMAP.md`, `ARCHITECTURE.md`, `AUDIT.md`, `HARNESS_ACCEPTANCE.md`, and `PROGRESS.md` last.

`PROGRESS.md` gives the immediate starting chunk. `ROADMAP.md` gives the full completion boundary.

## Execution contract

Treat the entire mandatory P0-P10 roadmap as one developer assignment. Work one bounded, testable chunk at a time, but after acceptance immediately update progress and continue to the next mandatory chunk. Do not stop because one phase, test, commit, or documentation update completed.

Stop only for:

- all developer-implementable mandatory gates passing, producing READY FOR USER LIVE TEST
- a genuine technical blocker with no safe in-scope fallback
- an authorization/scope conflict
- unsafe concurrent/local user work in the files that must be changed, after independent safe work has been exhausted

## Repository safety

- Existing `main` only; never create a branch.
- Inspect status/upstream before writes and before cross-repository migration.
- Preserve unrelated user changes; never reset, discard, force-push, blind-pull or auto-stash uncertain work.
- The DynamicTrading worktree had an unrelated edit in `DTHoomans_Conversation.lua` during the 2026-11-01 audit. Re-audit before touching DT and preserve it.
- Do not publish Steam Workshop content or launch native Project Zomboid unless the user explicitly authorizes it.

## Refactor discipline

- Start from source evidence and tests, not analyzer score alone.
- Preserve public behavior while moving ownership.
- Prefer lazy capability registration over global feature booleans.
- Move require-time side effects behind feature lifecycle boundaries where safe.
- Keep engine-required early hooks only with explicit rationale and acceptance coverage.
- Do not split files merely because they are large. Extract when responsibilities, lifecycle, authority, persistence, reuse or MCP retrieval improve.
- Do not create abstraction chains that require many files to understand one behavior.
- Core owns reusable mechanism; Hoomans and DynamicTrading retain product-specific policy.

## Validation loop

For each chunk:

1. establish/extend a failing or baseline assertion where feasible
2. implement the smallest coherent ownership change
3. run focused Lua/smoke/static checks
4. run affected integration tests
5. inspect loaded-feature/callback evidence when composition changed
6. run broader regression at phase gates
7. rescan architecture at P5/P10 or after major dependency changes
8. update `PROGRESS.md` with source-backed evidence and the next chunk
9. commit coherent Core changes only when the worktree remains safe
10. continue automatically

Clearly label synthetic/headless/static evidence versus user-owned native SP/MP evidence.

## Cross-repository migration

PsychopatzCore is the architecture owner for the new capability mechanism. Adopter repositories only declare requirements and migrate to stable public seams.

Never use adopter migration as a reason to move adopter-specific business rules into Core.

When an adopter has unrelated dirty work, defer only the conflicting adopter edit; continue independent Core work and record the blocked integration gate honestly.

## Completion report

Report changed repositories/files, exact tests and architecture evidence, feature-load/callback deltas, unresolved user-live gates, commit SHAs, publication status, and whether the parent goal is still IN PROGRESS or READY FOR USER LIVE TEST.
