# Core NPC Foundation — Copyable Codex /goal

Paste from the Core NPC foundation job, not the current Dynamic Trading root trading-MVP goal.

~~~text
/goal
Goal: Extract a canonical modular NPC foundation from ProjectHoomans into PsychopatzCore, preserving 100% canonical data parity and safe DTAbstract <-> DTHoomans presentation switching; DynamicTrading remains merchant authority. THIS IS AN IMPLEMENTATION JOB, NOT WORKSHOP PUBLICATION.

Repository scope (inspect current local worktrees and HEADs first):
- psychopatzCore: Core owner; Docs/npc_foundation is the authoritative goal folder.
- ProjectHoomans: legacy NPC factory, portrait, inventory, social, map and body adapter.
- DynamicTrading: DTCommon economy plus optional DTAbstract and DTHoomans adapters.
Do not assume published GitHub main is the local worktree state.

Read in this order in psychopatzCore/Docs/npc_foundation:
AGENT_RUNBOOK.md -> ARCHITECTURE.md -> ROADMAP.md -> PROGRESS.md -> PHASE_0_EXTRACTION_AUDIT.md -> PLAN.md.
Also read ProjectHoomans/AGENTS.md and the latest Hoomans persistence/identity/inventory/relationships docs and DynamicTrading/Docs/trading/DT_TRADING_MVP_PROGRESS.md.

Start with exactly P0A from PROGRESS and PHASE_0_EXTRACTION_AUDIT: inspect current generation and persistence; write a field-level source-to-Core ownership matrix and reversible migration risks; create ONE source-backed executable legacy NPC serialize/deserialize parity baseline. No broad production refactor in P0A. When evidence passes the phase gate, update durable progress and proceed automatically in bounded ordered chunks P0B -> P1..P9 as documented.

Critical invariants: Core owns actor ID, factory/resolved appearance, portable PERSONAL inventory, social records, travel, generic map and interaction presentation; DTCommon alone owns MERCHANT stock/budget/price/access/restock; Hoomans owns live body, combat, needs and colonies. Create identity/clothes/items only ONCE, never reroll on mode change. Preserve Hoomans original records with staged versioned import before its exact-version reset path; preserve player-character keys/memories and exact item state. One actor ID, inventory authority, journey owner and body lease. No PNC dependency in trading-only Core. A radio is communication, not automatic remote item teleportation. Keep existing DT trading MVP T6/manual acceptance OPEN.

Verify actual PZ Lua behavior, source-backed harness integration, Kahlua, server authority, module combinations, save/restart, snapshots and regression tests. No meaningless JSON-only acceptance. Report static, harness and live-game evidence separately; USER owns final manual in-game SP/MP test. NEVER publish or republish Steam Workshop, alter unrelated Radio OS/semantic jobs, touch live saves, or claim missing runtime gates passed. Read Hoomans AGENTS.md before source edits.

Preserve user work; safe fetch/fast-forward checks, no force push or destructive reset; commit coherent verified source/docs only at authorized GitHub destinations. On genuine destructive data ambiguity/conflict ask instead of guessing; otherwise continue only to next coherent accepted phase chunk. At each checkpoint report files, executed checks, open failures, commits, exact next chunk.
~~~
