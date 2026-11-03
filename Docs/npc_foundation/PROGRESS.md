# Core NPC Foundation — Progress

## Current status — 2026-11-03

**REOPENED — developer-side presentation/integration work remains.**

The 2026-10-20 P1–P9 headless acceptance is retained as historical foundation. It is no longer sufficient to claim READY FOR USER LIVE TEST because a new native/source audit found production integration gaps.

## Re-audit repositories

- PsychopatzCore: `main` at `23be8741ad3298ed02332a1cc40df257905fc122`, ahead of `origin/main` by 1.
- DynamicTrading: `main` at `57140979111109ba620a690811484b17cbab34e2`, ahead by 9.
- ProjectHoomans: `main` at `a68dd50e3c2ec7d127cb86de02b85c2505b410aa`, matching `origin/main`.

Worktrees were clean before documentation recovery.

## Accepted foundation retained

P1–P5 canonical actor/identity/inventory/social/journey mechanics remain accepted unless new evidence regresses them.

Core projected journey-position support added at `23be8741` is also useful and retained.

## Reopened findings

1. Core has data-side actor map contracts but no generic production vanilla-world-map overlay host.
2. ProjectHoomans still owns the active generic `PNC.MapLayers`/`PNC_MapToolbar` map host.
3. DTAbstract has a second fallback `ISWorldMap.render` patch because the Core registry it looks for does not exist.
4. This violates the original Hoomans adopter contract requiring one Core registry and no duplicate map monkey patches.
5. DTAbstract client map/discovery/debug code reads a client actor registry without a production authority→client actor/world synchronization path.
6. Earlier Core P6 acceptance therefore proved map/presentation data contracts, not the complete shared production UI host/network integration.
7. Provider adapters are compatible, but DTAbstract production orchestration still needs completion.

## Active phase

**C1 — Generic Core map host + fail-first integration coverage**

## Immediate Next Chunk

1. Add fail-first Core tests for one map host, register/unregister, load order, and consumer isolation.
2. Inventory all ProjectHoomans generic map-host/toolbar callers before migration.
3. Define the minimal Core map overlay/tool registry.
4. Add split server/client fail-first coverage for bounded actor presentation projection.
5. Coordinate with the DynamicTrading recovery roadmap R0/R1.
6. Continue through C2–C6 automatically after each accepted chunk.

## Remaining mandatory work

- C1 Core map host.
- C2 Hoomans + DTAbstract migration to the Core host.
- C3 authoritative client presentation sync.
- C4 production actor persistence integration.
- C5 production provider orchestration support.
- C6 cross-repository developer acceptance.

## Historical evidence

The 2026-10-20 P1–P9 acceptance remains evidence for canonical actor, inventory, social, journey, provider and adopter foundations. It must not be interpreted as current proof that the production map/network/persistence integration is complete.
