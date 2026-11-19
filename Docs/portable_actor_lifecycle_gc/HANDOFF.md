---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
state: "CLEAN_CHECKPOINT"
phase: L5
chunk: L5 accepted — Project Hoomans lifecycle bridge, corpse/quest/bond GC roots, and historical knowledge snapshots complete; ready for L6
retrieval_tier: verify
phase_commit: "self"
phase_commit_phase: "L5"
phase_commit_message: "phase(L5): L5: integrate Project Hoomans death, despawn, and durable GC roots with Core lifecycle"
phase_commit_vector: "psychopatz-core=self;project-hoomans=24842f92eb1abd2d7f5acb9035b9d5c61b430848;dynamic-trading=20e9b084272327aa9a9057abf19d10596afbdaa2"
phase_residual_vector: "psychopatz-core=27ef68e132727310ad9a41bd4b650b3f995f6d6abf38771c7ed11a939e6d4480;project-hoomans=f256733365331df4e2458104171b4e24b90912a0f8d34789d18e0a7d2e5057c2;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "27ef68e132727310ad9a41bd4b650b3f995f6d6abf38771c7ed11a939e6d4480"
codebase_memory_indexed_commit: "fba98ab4791bde95a12fb1fcb7fbeede88408d7a"
updated_at: "2026-11-19T16:13:49.310521Z"
---





# Handoff — Portable Actor Lifecycle & Social Garbage Collection

## What became true this session (L5)

- Implemented `ProjectHoomans` H1 & H2 (`24842f92eb1abd2d7f5acb9035b9d5c61b430848`): `PNC_Persistence_CoreLifecycle.lua` bridging `Health.Kill` / `API.Despawn` to Core `Retire` / `HardDelete` and registering `"ProjectHoomans.DurableRoots"` in Core `GC`.
- Added `QuestService.OnNPCDeath`, `MedicalCareService.OnNPCDeath`, post-`RemoveRecord` `faction.memberIDs` cleanup, `BuildPlayerSnapshotForPlayer` historical fallback, and verified `18/18` Hoomans tests (`core_actor_lifecycle_gc`, `factions_foundation`, `quest`, `medical_care`, `core_social`, `death`, `reanimat`) + Kahlua lint (`0` errors).

## Exact next action

Continue Batch 3 with **L6 — Player-character death and multiplayer identity lifecycle** (`PsychopatzPlayerIdentity.lua`, `PNC_PlayerCharacterLifecycle_Callbacks.lua`, `PNC_PlayerCharacterService_Lifecycle.lua`).

## Concurrent work

- `psychopatzCore`: unrelated dirty Inventory visual-state & map hover work preserved untouched.
- `ProjectHoomans`: unrelated dirty NPCAuthoring/StartingCompanions/Equipment/RosterPortrait work preserved untouched (`H1-H2` committed at `24842f92eb1abd2d7f5acb9035b9d5c61b430848`).
- `DynamicTrading`: clean (`D4-policy` committed at `20e9b084272327aa9a9057abf19d10596afbdaa2`).

## Stop condition

Complete L6 and L7 (local commits + `CHECKPOINT_VERIFIED`), then call `enter_plan_mode` for Batch 4 (L8–L9).
