---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "V0"
phase_commit_message: "phase(V0): feat(world-events): generate V0 vanilla event coverage manifest"
phase_commit_vector: "psychopatz-core=self;project-hoomans=4450f9a17ab73efa454e5e645af740312e3c888a;dynamic-trading=feee4da8fe4cab1ff4dcc1066ef1d4548b5728bb"
phase_residual_vector: "psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
codebase_memory_indexed_commit: "bbd9fee90a96f63323129ea29e5bf76e2f1525be"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "V1"
chunk: "Core normalized event observation and location contract"
retrieval_tier: "auditor"
updated_at: "2026-11-22T19:36:33.364607Z"
---


# Session Handoff

## What became true

- V0 is complete and verified: `tools/vanilla_event_coverage/generate_manifest.py` deterministically emits `VANILLA_EVENT_COVERAGE.json` (`203` entries across 45 RB, 33 RDS, 26 RVS, 42 RZS, 2 RR Java classes, 21 Lua ranch definitions, and all live/ambient/utility/helicopter/weather hooks; `0` unclassified).
- Verified unregistered Java classes (`RBReverend` and `RDSRatWar`) are explicitly classified as `unsupported_missing_authoritative_seam` with Java line evidence.
- Verified `OnAmbientSound(name,x,y)` and `OnWorldSound` (`Alarm`) plus `IsoChunk.vehicleStorySpawnData` / `Zone.pickedRzStory` / `OnSeeNewRoom` seams.

## Remaining

- V1–V8 implementation and verification.

## Resume

Proceed immediately to V1 (`PsychopatzWorldEventLocation.lua` + `PsychopatzVanillaEventObserver.lua`).

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
