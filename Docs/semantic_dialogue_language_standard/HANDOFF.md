# ConvoEngine Handoff

~~~yaml
status: DIRTY_RESUMABLE
checkpoint_mode: dirty_snapshot
phase_commit: none
phase: S12 final durable commit boundary
active_phase: S12 closure commit/reconciliation
next_chunk: review and commit the already-verified S12-owned Core integration; then activate S13A
planned_next_goal: Docs/semantic_dialogue_language_standard/S13_LAYOUT_NORMALIZATION_AND_DIRECTOR_ARCHITECTURE_FREEZE.md
layout_standard: Docs/semantic_dialogue_language_standard/CONVOENGINE_PHYSICAL_LAYOUT_AND_LOCALIZATION.md
director_architecture: Docs/semantic_dialogue_language_standard/CONVERSATION_DIRECTOR_ARCHITECTURE.md
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
updated_at: 2026-11-19
~~~

## Current participant baseline

~~~text
psychopatzCore   1b4ab2443d3c40fab8b43601cc7e34d29a277d9b
ProjectHoomans   3aaf15c5fa50fa96b3160d680d46ef38dc7faa11
DynamicTrading   bba5004f9a1bb45a093e3a39e045ff6f6bd2ab5a
~~~

ProjectHoomans and DynamicTrading already contain their local S12R2 cleanup
commits. Core still contains the verified swarm integration as uncommitted work.
Do not reset, stash, discard, or overlap it with S13 migration.

## Verified S12 technical state retained

The previous verification established:

~~~text
activeCurrentPsdlIdentityCount = 0
modernization closure = true
reconcile clean = true
desired generated files = 396
model fingerprint = b989f64511baedd83aa44357b7668d20c1ac435200cbf79a297b9a6b5642f23d
two canonical acceptance runs = 9/9 suites
convoScopeOk = true
~~~

This evidence does not substitute for the missing Core commit boundary.

## Newly planned S13

The physical-layout audit found that one semantic model still becomes multiple
physical representations:

- mixed localization authoring forms;
- complete multi-locale corpora embedded into generated Lua;
- duplicate full behavior projections under `Behavior/*` and
  `Behaviors/Director/*`;
- analogous beat projection requiring audit.

S13 will normalize those representations before implementing the Conversation
Director.

Read:

~~~text
CONVOENGINE_PHYSICAL_LAYOUT_AND_LOCALIZATION.md
CONVERSATION_DIRECTOR_ARCHITECTURE.md
S13_LAYOUT_NORMALIZATION_AND_DIRECTOR_ARCHITECTURE_FREEZE.md
~~~

## Immediate action

1. finish the existing S12 Core integration commit without absorbing unrelated work;
2. reconcile S12/S12R1/S12R2 closure docs to the committed vector;
3. require clean participant worktrees and rerun the closure/reconcile sanity gate;
4. only then mark S13A active and inventory all localization/projection shapes.

Do not push, publish Workshop content, or launch native Project Zomboid without
explicit authorization.
