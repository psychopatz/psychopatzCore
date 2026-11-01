# PsychopatzCore Modular Capability & Composition Refactor

## Parent objective

Refactor PsychopatzCore into an agent-readable, demand-driven shared framework where installing Core does **not** imply loading or activating every feature. Adopting mods request stable capabilities; Core resolves only the required dependency closure for the current runtime role and activates only those feature lifecycles.

The first proof target is Dynamic Trading: a Dynamic Trading-only configuration must activate only the Core capabilities it actually needs, with unrelated systems remaining unloaded or inactive.

This goal also continues the Project Hoomans refactor principles: strong public module boundaries, fine-grained internals where retrieval benefits, simple code inside domains, and no arbitrary file-count target.

## Completion boundary

The parent goal is complete on the developer side only when the mandatory P0-P10 roadmap is implemented and verified. Finishing the kernel, one feature migration, or the Dynamic Trading pilot does not complete the goal.

Native Project Zomboid SP/MP acceptance remains user-owned. Developer work must continue through all implementable gates before handoff as READY FOR USER LIVE TEST.

## Documents

- `AUDIT.md` — source-backed baseline and current risks.
- `ARCHITECTURE.md` — target capability, lifecycle, ownership, and composition contracts.
- `ROADMAP.md` — complete ordered P0-P10 implementation plan and exit gates.
- `AGENT_RUNBOOK.md` — execution, validation, Git, and cross-repository procedure.
- `HARNESS_ACCEPTANCE.md` — required load-graph, callback, dependency, and regression evidence.
- `PROGRESS.md` — current truth and immediate Next Chunk; read last.

The executable `/goal` prompt is intentionally chat-only per root `AGENTS.md`.
