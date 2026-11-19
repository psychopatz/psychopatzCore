# Agent Runbook — Portable Social State

## Execution mode

This is a multi-repository unattended developer goal. P0-P9 are accepted historical implementation milestones; complete mandatory cleanup P10-P12 unless blocked by a genuine safety, authority or tooling conflict.

Primary job documentation lives in PsychopatzCore. Participant repositories may carry thin adopter documents, but they do not redefine the parent completion boundary.

## Workspace discovery

At every resume:

1. read root AGENTS.md in Core, ProjectHoomans and DynamicTrading;
2. verify branch/HEAD/upstream/worktree for all participants;
3. verify HANDOFF.md checkpoint vector;
4. treat mismatches as evidence to reconcile, never authorization to reset/stash/discard;
5. inspect exact current source/tests before trusting historical docs.

DTAbstract is a module within the DynamicTrading repository, not a separate Git repository.

## Ownership discipline

Core owns reusable actor/social/compiler mechanisms.

Hoomans owns product-specific social/gameplay policy and rich world authorities.

DTCommon owns commercial truth. DTAbstract owns abstract/remote trader access/provider behavior. DTHoomans owns physical trader adapter behavior where present.

MarketSense is an economic dependency, not a default edit participant.

## Existing mechanisms to evolve

Prefer and extend:

- PsychopatzCore/Actors/PsychopatzSocial.lua;
- PsychopatzActorSocialAuthority.lua;
- Core actor registry/persistence/player identity/provider lease contracts;
- existing CodeBuilder compiler/recipe/package-routing framework;
- Project Hoomans SocialEvent/Relationship/Conduct/Knowledge adapters;
- DynamicTrading DTCommon_CoreActorPolicy and canonical actorID mapping.

Never create a competing SocialV2, relationship database, memory store or second compiler.

## CodeBuilder rule

Author semantic policy once. Compile portable plans and adopter packages from canonical source.

Generated Lua/tables are downstream artifacts. Do not hand-edit them.

Portable policy cannot reference PZ Java objects, raw ModData paths or adopter implementation modules. Use registered typed refs/adapters.

## Multi-repo phase close

When a phase gate passes:

1. update participant docs/evidence;
2. stage only phase-owned paths;
3. preserve unrelated dirty work;
4. commit participant repos first when they changed;
5. update Core HANDOFF.md with the participant commit vector;
6. commit Core last;
7. verify checkpoint vector and residual dirty fingerprints;
8. continue to the next mandatory phase.

No push/rebase/amend/force operation without explicit user authorization.

## Performance and persistence

Measure before changing schema.

Any new persisted field must have clear owner, hard bound, insertion/removal rule, migration rule and measured cost.

No transcript/prose persistence, no per-tick aging, no full actor scans for local candidate queries.

## Validation strategy

Use the cheapest authoritative layer first:

- Core pure/unit storage/policy tests;
- CodeBuilder compiler/determinism tests;
- adopter event integration tests;
- Semantic Harness real Lua worker;
- DT pricing/conversation/provider tests;
- multiplayer/protocol fixtures;
- storage/scale measurements;
- full relevant regressions.

Native Project Zomboid remains user-owned acceptance unless explicitly reassigned.

## Post-P9 cleanup discipline

- Resume at Core PROGRESS.md; do not replay P0-P9.
- P10 owns the single-persistence authority cleanup. Preserve Hoomans-specific morale, conduct, bond and journal state and migrate only generic portable relationship and memory persistence.
- P11 owns the action-neutral social feature boundary. Do not implement the full Event Director, advertisement system or autonomy resolver in this goal.
- P12 owns Project Zomboid-safe player identity and final cross-repository persistence and MP regression proof.
- No permanent legacy compatibility shim: supported old-save handling must be explicit, versioned and bounded, then leave new saves on the single-authority format.
