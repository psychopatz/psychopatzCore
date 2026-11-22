---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "V3"
phase_commit_message: "phase(V3): feat(world-events): add V3 vanilla utility transition adapter and capability"
phase_commit_vector: "psychopatz-core=self;project-hoomans=53e4a0f311264cf1c53bc9a2696171657bc015fe;dynamic-trading=feee4da8fe4cab1ff4dcc1066ef1d4548b5728bb"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "bbd9fee90a96f63323129ea29e5bf76e2f1525be"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "V4"
chunk: "Helicopter regional episode capture"
retrieval_tier: "auditor"
updated_at: "2026-11-22T19:48:55.417009Z"
---





# Session Handoff

## What became true

- V0–V3 are complete and verified across `psychopatzCore` and `ProjectHoomans`.
- `PsychopatzPZWorldEventAdapter` observes authoritative electricity (`IsoWorld:isHydroPowerOn`, `SandboxOptions:doesPowerGridExist`, `OnElectricityChanged`) and water (`SandboxOptions:getWaterShutModifier` vs world days) transitions exactly once across save/reload.
- `ProjectHoomans` `PNC_ScopedWorldEventDirector` forbids global defaults/scopes for synthetic events (`food_crisis`, `agricultural_surplus`, `bandit_bonanza`, `severe_weather`, `epidemic`, `trade_disruption`), and utility beats share Core transitions.

## Remaining

- V4–V8 implementation and verification.

## Resume

Proceed immediately to V4 (helicopter regional episode capture in Core + outdoor witnessed vs indoor heard epistemic acquisition in `ProjectHoomans`).

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
