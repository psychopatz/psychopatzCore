---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "V8"
phase_commit_message: "phase(V8): test(world-events): add V8 scale soak test and close V0-V8 developer roadmap"
phase_commit_vector: "psychopatz-core=self;project-hoomans=4522d6e952708bf3ccb013ce620ad9d698a60cb1;dynamic-trading=62757d0b7fc1c114873735387827ccad9d828077"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "bbd9fee90a96f63323129ea29e5bf76e2f1525be"
state: "CLEAN_CHECKPOINT"
parent_status: "COMPLETE"
phase: "V9"
chunk: "User native SP/MP acceptance"
retrieval_tier: "auditor"
updated_at: "2026-11-22T20:33:41.428196Z"
---










# Session Handoff

## What became true

- All developer phases V0–V8 of `UnifiedVanillaWorldEventSemantics` are complete, verified, and locally committed across `psychopatzCore`, `ProjectHoomans`, and `DynamicTrading`.
- Core owns normalized observation, single-pass location resolution, bounded scoped-event/ledger ModData persistence (`<= 32` active, `<= 64` history, `<= 256` ledger facts), global utility transitions (`electricity_cutoff`, `water_cutoff`), bounded regional helicopter episodes (`<= 5` coarse samples, zero per-tick telemetry), live/meta event ingestion (gunfire, scream, house alarm, severe storm, broadcasts, fire, season) with ephemeral wildlife/thunder filtering, and zero-scan randomized-world discovery (`PsychopatzVanillaDiscoveryAdapter`: `RVS*` including `RVSAmbulanceCrash`, `RZS*`, `RB*`/`RDS*` grounded room observations, and `Ranch` zones; `203` manifest entries with explicit `RBReverend` and `RDSRatWar` gaps).
- ProjectHoomans V7 deepened all 8 thematic interactive families (`60` nodes / avg `7.50`, `132` offers / avg `16.50`, `43` hard-constrained offers across `8/8` flows, `45` distinct outcome keys, `replySemantics`, and `after.recommend`), extended numeric disposition + epistemic/condition/fatigue weighting (`ChoicePolicy.lua`), added third-party witness/mediator interjection outcomes (`TurnPolicy.lua`/`Conversation.lua`, `MAX_PARTICIPANTS = 4`, `MAX_STEPS = 8`), and reconciled all EN/TL CodeBuilder artifacts cleanly.
- DynamicTrading V8 consumes Core `ScopedWorldEvents` and `WorldKnowledge` directly via `DTCommon/DTCommon_CoreWorldEventProjection.lua` and `DTCommon_WorldKnowledge.lua` (standalone without `ProjectHoomans`, coordinated cleanly with `DTHoomans_WorldEventProjection.lua`, ignoring non-economic ambience/campsites, never recursing `dt-market-condition:*`, and reconciling reload state via `OnStateLoaded`).

## Remaining

- V9: User-owned native Project Zomboid SP/MP acceptance testing.

## Resume

All developer work V0–V8 is finished. Proceed only with user-driven native SP/MP acceptance per `ROADMAP.md` V9.

## Evidence

- CODE_VERIFIED: Core scoped-event/WorldKnowledge/location mechanisms exist and DT already consumes Core scoped events.
- CODE_VERIFIED: Hoomans environment cadence is bounded and existing event hooks are reusable.
- RUNTIME_BINARY_VERIFIED: installed PZ JAR exposes helicopter active/x/y, ambient event coordinates, randomized-world class families and story metadata described in `AUDIT.md`.

## Expensive discoveries worth preserving

- Ambient meta events fire `OnAmbientSound(name,x,y)` from the vanilla ambient constructor.
- Zone stories expose `pickedRzStory` and picked coordinates; vehicle spawn data exposes story + spawn coordinates; BuildingDef does not expose an obvious randomized-building identity field.
- Installed randomized-world counts: building 45, dead-survivor 33, vehicle 26, zone 42, ranch 2 (excluding helper inner classes).

## Blockers / open decisions

- Exact cheap capture seam for some randomized building/dead-survivor/ranch identities must be proven in V0. Missing seam is an explicit coverage gap, not permission for a global scan.

## Acceptance

V0 closes only when every installed first-party event/story family is present in the coverage manifest with a supported strategy or evidence-backed gap and the manifest can be regenerated deterministically.
