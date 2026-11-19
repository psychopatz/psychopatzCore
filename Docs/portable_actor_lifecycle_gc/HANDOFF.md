---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
state: "CLEAN_CHECKPOINT"
phase: L3
chunk: L3 accepted — actor-level memoryBank, v3 migration, ephemeral indexes, and historical edge compaction complete; ready for L4
retrieval_tier: verify
phase_commit: "self"
phase_commit_phase: "L3"
phase_commit_message: "phase(L3): L3: migrate social storage to bounded actor-level memoryBank and historical edge compaction"
phase_commit_vector: "psychopatz-core=self;project-hoomans=b19d3a0382a9adf1e07eba1af7535f9bd671ec50;dynamic-trading=4ca3c554c1a97fa37d14d070d2317bd240cbb3b6"
phase_residual_vector: "psychopatz-core=886357708bcb89bcc9947c0e344ee00c4159fb229b1a51be638d4d6e64a54077;project-hoomans=916ead90b30fa95f2ddbafec767bfefae15882b95ad8caadbe0a34c7cbbcf53b;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "886357708bcb89bcc9947c0e344ee00c4159fb229b1a51be638d4d6e64a54077"
codebase_memory_indexed_commit: "fba98ab4791bde95a12fb1fcb7fbeede88408d7a"
updated_at: "2026-11-19T15:56:57.311018Z"
---



# Handoff — Portable Actor Lifecycle & Social Garbage Collection

## What became true this session (L3)

- Migrated Core social storage (`PsychopatzSocial.lua` `SCHEMA_VERSION = 3`, `PsychopatzSocialRetention.lua`) from per-relationship `memories` (`N × 64`) to one bounded actor-level `memoryBank[]` (`MAX_ACTOR_MEMORIES = 96`: `16` ANCHOR, `56` LONG, `24` SHORT), with deterministic `v1/v2 -> v3` migration + baseline promotion, `rel.memories` prohibition, FIFO-bounded (`32`) ephemeral indexes, and `CompactHistoricalEdge`/`PruneDefaultEdges`.
- Updated `PsychopatzSocialProjections.lua`, `PsychopatzActorSocialAuthority.lua`, `PsychopatzActorGC.lua`, and `ProjectHoomans` `PNC_Persistence_CoreSocial.lua` (H3A `b19d3a0382a9adf1e07eba1af7535f9bd671ec50`) for `memoryBank` + `refStrength` semantics.
- Measured 100-contact 6400-event actor save = `35,943` bytes (vs `1,606,721` bytes L0 baseline); verified `39/39` Core smoke tests, `5/5` Hoomans tests, `2/2` DynamicTrading tests, and Kahlua lint (`0` errors).

## Exact next action

Continue Batch 2 with **L4 — CodeBuilder Social Policy reference strength and bounded refs** (`social_policy_compiler.py` + Core/Hoomans/DT social policy JSONs + `reconcile.py --apply` + tests).

## Concurrent work

- `psychopatzCore`: unrelated dirty Inventory visual-state work (`PsychopatzItemTransfer.lua`, `PsychopatzItemVisualState.lua`) preserved untouched.
- `ProjectHoomans`: unrelated dirty NPCAuthoring/StartingCompanions/Equipment work preserved untouched (`H3A` committed at `b19d3a0382a9adf1e07eba1af7535f9bd671ec50`).
- `DynamicTrading`: clean (`D0` committed at `4ca3c554c1a97fa37d14d070d2317bd240cbb3b6`).

## Stop condition

Complete L4 verification and local commits, then call `enter_plan_mode` for Batch 3 (L5–L7).
