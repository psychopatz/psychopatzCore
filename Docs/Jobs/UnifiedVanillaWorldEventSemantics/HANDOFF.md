---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
branch: "main"
phase_commit: "self"
phase_commit_phase: "V0 planning checkpoint"
phase_commit_message: "docs: plan unified vanilla world event semantics"
phase_commit_vector: "psychopatzCore=self;ProjectHoomans=4450f9a17ab73efa454e5e645af740312e3c888a;DynamicTrading=feee4da8fe4cab1ff4dcc1066ef1d4548b5728bb"
phase_residual_vector: "psychopatzCore=clean;ProjectHoomans=clean;DynamicTrading=clean"
residual_worktree_fingerprint: "clean"
codebase_memory_indexed_commit: "unknown"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "V0"
chunk: "Installed-build vanilla-event coverage manifest"
retrieval_tier: "auditor"
---

# Session Handoff

## What became true

- Core already owns the correct reusable event (`PsychopatzScopedWorldEvents`), knowledge and location primitives.
- User expanded scope to cover all vanilla live/meta/randomized-world events as far as authoritative lightweight observation permits, with ambulance/world stories treated as location-grounded discoveries.
- Global baseline is restricted to water/electricity cutoff; helicopter is regional/local and must carry bounded location-aware rumor provenance.
- Dialogue depth/variety is part of the same goal and must be driven by semantic affordances, hard eligibility and numeric utility rather than giant static trees.

## Remaining

- V0–V8 implementation and verification.

## Resume

Start V0 by generating the exact installed-build event/story coverage manifest and mapping each entry to an authoritative capture seam, normalized semantic category, location strategy, retention policy and Core/Hoomans/DT consumer path. Do not implement runtime changes until the manifest exposes all first-party categories and evidence-backed gaps.

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
