# Agent Runbook — Compact Survivor World Runtime

## Mission

Build one compact Core Survivor World consumed by ProjectHoomans and DTAbstract.

Abstract mode remains lightweight. Hoomans hydrates rich physical/runtime state only when needed. Both modes represent the same persistent actors, factions, communities, groups, journeys, discovery entities and map identities.

## Read order

1. root AGENTS.md;
2. this runbook;
3. README.md;
4. AUDIT.md;
5. ARCHITECTURE.md;
6. COMPACT_PERSISTENCE.md;
7. ROADMAP.md;
8. HARNESS_ACCEPTANCE.md;
9. PROGRESS.md last.

Before editing ProjectHoomans or DynamicTrading, read that repository's root AGENTS.md and inspect branch/upstream/worktree state.

Treat the existing Core NPC Foundation as accepted foundation where not superseded by this compactness goal.

## Mandatory rules

- Core owns reusable survivor-world mechanisms.
- Hoomans owns physical gameplay/runtime policy.
- DynamicTrading owns economics.
- DTAbstract is a lightweight adapter, not a second world.
- one actor/faction/community/group/journey identity survives provider changes;
- abstract actors need no bodies;
- abstract actors need no hydrated FULL inventory;
- AI/body/path/perception/animation runtime is not canonical ModData;
- group journey is stored once;
- portraits work from compact appearance without a body;
- provider runtime is disposable except approved durable deltas;
- same seed/config produces the same canonical world regardless of representation provider;
- map/discovery/debug identity is provider-neutral;
- no permanent duplicate registries/dual writes;
- no silent reset of unknown persistence versions;
- merchant stock/budget stays separate from actor personal inventory;
- ModData footprint is an acceptance requirement.

## Migration discipline

For each PNC subsystem:

1. characterize behavior/persistence;
2. classify generic mechanism vs Hoomans policy/runtime;
3. add parity/footprint tests;
4. implement Core contract;
5. migrate Hoomans;
6. validate;
7. migrate DTAbstract/DTCommon;
8. validate cross-provider parity;
9. remove old active authority;
10. verify no fallback/dual write remains.

Do not wholesale relocate modules based on filenames.

## Persistence discipline

Every canonical field must state owner, persistence class, derivation reason, boundedness, migration behavior and size impact.

Prefer seed/default omission and sparse deltas.

FULL inventory/large resolved tables require explicit evidence.

## Execution

Start at PROGRESS Next Chunk. After every accepted chunk:

1. update PROGRESS;
2. select next mandatory S-phase;
3. continue automatically;
4. stop only for a genuine blocker or after S0–S10 developer gates pass and only native acceptance remains.

## Git

- existing main branches only;
- preserve unrelated work;
- no blind pull/reset/rebase/stash/discard;
- coherent commits per repository;
- no push/Workshop publish unless explicitly authorized;
- never stage DynamicTrading's unrelated mod.info edits.

## Final report

Report measured footprint, compact schema, Core/Hoomans ownership split, inventory modes, appearance/portrait behavior, group travel compression, hydration/dehydration, DTAbstract parity, shared map/discovery/debug parity, removed legacy/static paths, validation counts and remaining native acceptance.
