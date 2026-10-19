# Core NPC Foundation — Goal Navigation

**PARENT GOAL IN PROGRESS** until every mandatory Foundation P1–P9 implementation and developer-side acceptance passes. P0A/P0B are only accepted subphases. P1 is the next chunk, and the agent must immediately continue after acceptance without requesting a new /goal.

Status: P0A/P0B accepted from source/harness evidence; P1 open as the next bounded chunk. Current snapshot: 2026-10-20.
PsychopatzCore is the target owner of shared canonical NPC state; ProjectHoomans and DynamicTrading are adopters. This job is separate from the Dynamic Trading trading-MVP, Radio OS, and Hoomans semantic-dialogue goals.

## Read order
1. AGENT_RUNBOOK.md — durable safety, Git and validation policy
2. ARCHITECTURE.md — target ownership and invariants
3. ROADMAP.md — ordered phases and acceptance gates
4. PROGRESS.md — current verified state and the ONE active Next Chunk
5. P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md — current phase contract
6. PHASE_0_EXTRACTION_AUDIT.md — accepted P0A evidence and historical P0 details
7. GOAL_PROMPT.md — compact autonomous bootstrap

## Current objective
P0B's normal Hoomans serializer/deserializer now preserves authored appearance policy and the complete available voice profile, while generated/default appearance remains an explicit valid case. The evidence is source/harness only; no live-game or Core-writer claim is made.

The ONE next chunk is the smallest real PsychopatzCore actor Create -> Save -> Reload -> Get identity/appearance codec/registry slice.

## Product acceptance
A single Core-generated merchant has a stable identity, name, face, voice, clothing, personal items and exact portable state, directional relationships, world position and journey. DTAbstract can run it without ProjectHoomans. DTHoomans can project the SAME merchant into its live NPC simulation without rerolling, resetting or duplicating anything; returning to abstract retains canonical changes. One DTCommon stock/budget/transaction ledger is shared across modes. Known actors can use bounded map markers/hover portraits; nearby actors can expose Talk; travel between eligible settlements can earn restocks. SP and MP server authority remain intact.

100% canonical data parity is required for common fields, not identical live combat, animation or needs behavior while abstract. Module install/uninstall switching first requires safe save/restart/load behavior; live provider switching is only for adapters already loaded.

## Repositories and audited pre-refresh source heads
- Core: psychopatz/psychopatzCore source baseline `50022acf`; later commits in this goal refresh are documentation-only
- Hoomans: psychopatz/ProjectHoomans main `bc9c64d0`; NPC-foundation evidence exists on a divergent committed history through `9f153c0e`
- Trading: psychopatz/DynamicTrading main `d6fccc3d`

Do not infer local worktree cleanliness from these remote heads. Before editing Hoomans, inspect the actual local branch and safely reconcile the divergent foundation history with unrelated current work. Never force-push, reset or overwrite user changes merely to make histories match.
