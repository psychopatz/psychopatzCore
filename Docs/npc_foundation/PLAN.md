# Core NPC Foundation — Goal Navigation

**PARENT GOAL STATUS: REOPENED FOR PRESENTATION/INTEGRATION RECOVERY.**

A 2026-11-03 audit of DynamicTrading + PsychopatzCore + ProjectHoomans found that the earlier P6/P9 headless acceptance did not satisfy the intended production map architecture.

## Current regression evidence

The original adopter contract required:

> Register Hoomans map layers through one Core registry; avoid duplicate ISWorldMap monkey patches.

Current source instead has:

- active ProjectHoomans `PNC.MapLayers` / map-toolbar host that patches the vanilla map;
- no production `PsychopatzCore.MapOverlayRegistry`;
- DTAbstract code that checks for that nonexistent Core registry and otherwise installs another direct map patch;
- no generic Core authority→client actor/world projection for DTAbstract map/discovery/debug consumers.

Therefore P6/P9 are reopened.

## Read order

1. `AGENT_RUNBOOK.md`
2. `ARCHITECTURE.md`
3. `ROADMAP.md`
4. DynamicTrading `Docs/Jobs/DTAbstractWorldSimulationPresentation/AUDIT.md`
5. DynamicTrading `.../ARCHITECTURE.md`
6. `PROGRESS.md` last

## Current objective

Finish the missing reusable Core production seams:

- one generic world-map host;
- adopter overlay/tool registration;
- bounded actor presentation synchronization;
- real actor-registry persistence integration;
- production provider orchestration support where Core ownership applies.

ProjectHoomans keeps Hoomans-specific map layers/policy.
DynamicTrading keeps DT-specific trader/settlement presentation and economic policy.

## Product acceptance

No duplicate actors, inventories, provider leases, bodies, economy owners, or map hosts.

The same canonical actor/journey state must be visible to authorized clients through a bounded read-only projection and survive production save/reload.

Only after the recovery roadmap is accepted should native SP/MP become the remaining user-owned action.
