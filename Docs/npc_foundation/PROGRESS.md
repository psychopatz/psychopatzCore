# Core NPC Foundation — Current Progress

Snapshot: 2026-10-20. Evidence is limited to source-backed Lua harnesses,
focused regressions, and static Kahlua verification. Native Project Zomboid
SP/MP and live-game acceptance remain user-owned and unclaimed.

## Current phase

**P7 — DynamicTrading merchant policies: ACCEPTED developer-side evidence.**
P8 is next. P2 physical-body parity remains a P8 gate.

## Repository state

- Core: `114e201`, main, local branch ahead of origin by eight and behind by
  one; no upstream history was force-merged, reset, or discarded.
- Hoomans: `e461ccaf`, contextual-dialogue branch, local branch ahead of its
  configured documentation remote by three; unrelated history preserved.
- DynamicTrading: `4fe28f55`, main, one commit ahead of origin; no Workshop
  publication performed.

## Accepted foundation and phase evidence

- P0A/P0B: ownership/risk audit, parity baseline, fail-closed read-only import
  planning, no-loss voice/appearance/inventory/social/location contracts, and
  provenance gates remain source/harness evidence.
- P1: Core actor factory, registry, JSON codec, deterministic identity/voice/
  appearance, authored/generated policy distinction, extensions, duplicate-ID
  rejection, and no PNC/DT runtime dependency. The Core actor smoke passed
  Create → Save → Reload into a fresh registry → Get.
- P2: Core personal inventory has deterministic starters, stable item IDs,
  containers, equipment slots, exact item state, and FULL/BASELINE_DELTA/
  SEED_ONLY payloads. It does not own merchant stock or budget.
- P3: Core/Hoomans migration validates ownership and hashes, preserves source
  payloads, quarantines conflicts, imports idempotently, and supports rollback
  and retry. The focused Hoomans migration/continuity/parity/seed suite passed
  4/4.
- P4: Core directional social state stores bounded Approval, Respect,
  Familiarity, personality, revisions, and event memories; explicit actor and
  player keys, server authority, and event deduplication are enforced. The
  Hoomans social adapter projects once without taking source ownership.
- P5: Core actor-world state now persists bounded tasks, scheduler entries,
  location anchors, abstract journeys, deterministic progress, and one-shot
  arrival handling. Journey/task save-reload smoke passed.
- P6: Core map entries are knowledge-gated and carry stable portraits,
  capabilities, journeys, and provider metadata. Nearby Talk requests are
  server-authorized; notifications are bounded and deduplicated. Hoomans has
  an optional bridge that leaves existing map and portrait UI ownership intact.
- P7: DT persists a compact Core actor merchant policy separately from DT
  virtual stock/budget and Core personal inventory. It supports availability,
  one-shot settlement visits, earned/cooldown restock, capped Core-social
  buy/sell modifiers, authoritative basket fulfillment, and Core map trade
  capability projection.

## Validation evidence

- Core P1–P6 smoke/regression suite passed, including the composition smoke;
  Core actor-directory Kahlua verification reports zero errors.
- Hoomans focused foundation suite passed 6/6 after the P6 bridge and Core
  world normalization; its new adapters report zero Kahlua errors.
- DT focused P7 plus pricing, seed, access, basket, rollback, and T0 suites
  passed 8/8; DTCommon Kahlua verification reports zero errors.
- The unfiltered DT harness retains one pre-existing `dt_caravan_contract`
  failure for missing baseline text `groupSize = GROUP_SIZE`; no caravan file
  changed in P7.

## Boundaries and next chunk

P8–P9 remain open: DTAbstract/DTHoomans provider switching, physical body
leases, materialization/dematerialization, multiplayer authority/reconnect,
performance, and user-run native SP/MP acceptance. No Workshop or live-game
test was performed.

**Next: P8 provider switching and Hoomans integration.** Complete DTAbstract
and DTHoomans adapters, stable Core identity/appearance/inventory/social/world
state across materialization and dematerialization, and single-body lease
ownership.
