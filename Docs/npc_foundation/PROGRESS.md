# Core NPC Foundation — Current Progress

Snapshot: 2026-10-20. Evidence basis: source-backed Lua harnesses, focused
module regressions, and static Kahlua verification. No native Project Zomboid
SP/MP or live-game acceptance is claimed.

## Current phase

**P5 — Generic tasks, anchors, and journeys: ACCEPTED developer-side
source/harness evidence.** P6 is the next bounded implementation phase. The
P2 physical-body parity gate remains part of P8.

## Repository evidence

- PsychopatzCore is at `445f0f9` on `main`, ahead of local `origin/main` by
  six commits and one commit behind it. The upstream commit has not been
  force-merged, reset, or discarded.
- ProjectHoomans is at `8de474cc` on
  `codex/contextual-dialogue-quest-framework-0a`, ahead of its configured
  documentation branch by two commits. Its unrelated branch history remains
  intact.
- DynamicTrading remains clean at `d6fccc3d` on `main`/`origin/main`; no DT
  runtime behavior has been changed yet.

## Accepted P0A/P0B foundation

The ownership/risk audit, source-backed parity baseline, read-only
`PNC.Persistence.ImportPlan`, fail-closed source preservation,
metadata-schema-2 `legacyTemplateKey` preservation, relationship/journey
continuity, deferred-root retention, and seed-only generator/policy
provenance gates remain source/harness facts. Normal Hoomans persistence
preserves the available versioned voice profile, authored appearance policy,
generated/default provenance, portable item state, and existing social/location
data without rerolling incomplete legacy values.

## P1 evidence — Core identity and appearance

Core production files in `PsychopatzCore/Actors` provide a Core-owned actor
factory, registry, persistence codec, deterministic generated identity and
appearance, authored appearance policy handling, voice state, namespaced
extensions, duplicate-ID rejection, and clone-on-read boundaries.

`tests/psychopatz_npc_actor_smoke.lua` passed with `/usr/bin/lua`: generated
and authored actors both completed Create → Save → Reload into a fresh
registry → Get; identity, names, voice, appearance, authored item state, and
extensions remained stable. Invalid IDs and duplicate IDs were rejected. The
test confirmed that Hoomans and DynamicTrading runtime modules were not
loaded.

## P2 evidence — Portable personal inventory

`PsychopatzActorInventory.lua` provides deterministic starter equipment,
stable item IDs, portable item records, container references, worn/equipped/
attached slots, exact codec state, and FULL, BASELINE_DELTA, and SEED_ONLY
payloads. Merchant stock and budget are not part of the personal ledger.

`tests/psychopatz_npc_inventory_smoke.lua` and the existing Core inventory
framework/default/reversible regressions passed. JSON sparse-array handling was
updated so nil slots do not shift persisted item state.

## P3 evidence — Non-destructive legacy migration

`PsychopatzActorMigration.lua` and the optional Hoomans
`PNC_Persistence_CoreMigration.lua` adapter implement source validation,
field-ownership checks, source hashing and preservation, idempotent import,
conflict quarantine, transactional registry registration, rollback, disabled
mappings, and safe retry. The Hoomans adapter does not require Core; callers
inject the loaded Core facade and registry.

The focused Hoomans migration, import-plan continuity, parity-baseline, and
seed/delta tests passed 4/4. Source payloads are copied and never rewritten by
the developer-side migration harness.

## P4 evidence — Shared social system

`PsychopatzSocial.lua` is the Core-owned directional social ledger. It
normalizes explicit `npc:`, `actor:`, `player:`, and `steam:` target keys;
stores bounded Approval, Respect, Familiarity, personality, revisions, and
bounded event memories; rejects malformed targets; and gates personality and
event mutation on server authority. Event IDs are deduplicated and state is
validated during actor registration, commit, save, and load.

`PNC_Persistence_CoreSocial.lua` projects existing Hoomans directed social
state into Core without taking ownership of Hoomans records. The adapter
records only authorized Core events and rejects duplicate or client-forged
events.

Evidence:

- `lua tests/psychopatz_npc_social_smoke.lua` passed, including social
  save/reload parity, target validation, authority gating, score bounds,
  memory preservation, and duplicate-event rejection.
- The Hoomans social adapter smoke passed, including real parity fixtures,
  directional relationship and memory projection, authorized event recording,
  duplicate-event rejection, source immutability, and missing-source guards.
- The focused Hoomans regression set passed 5/5: migration, import-plan
  continuity, parity baseline, seed/delta, and social adapter.
- `pz_verify.py` reported zero Kahlua compatibility errors for the Core actor
  directory and the Hoomans social adapter.

## P5 evidence — Generic tasks, anchors, and journeys

The Core actor world now owns bounded location anchors, abstract A-to-B
journeys, deterministic journey progress and arrival state, one-shot arrival
handling, bounded persistent task queues, and bounded scheduler entries.
Journey, task, scheduler, and actor-world state are normalized and validated
through the same Core registry and JSON codec; no Hoomans or DynamicTrading
runtime module is required.

`tests/psychopatz_npc_journey_task_smoke.lua` passed with `/usr/bin/lua`:
anchor creation, deterministic journey progress, task leasing, bounded
scheduling, consumed schedule entries, actor save/reload, arrival position and
anchor restoration, and rejection of a repeated arrival handler all passed.
The P1–P4 Core suite, the four prior Hoomans foundation regressions plus the
social adapter (5/5), and Core actor-directory Kahlua verification remained
green after world normalization.

## Remaining boundaries

P6–P9 production behavior remains open. DT merchant policy integration,
generic journeys/scheduling, map and interaction UI, physical Hoomans body
materialization, provider switching, multiplayer authority/reconnect,
performance, and user-run native SP/MP acceptance are not claimed. No
Workshop publication or live-game test was performed.

## ONE next chunk — P6 shared map and interaction systems

Implement Core map representation and coexistence hooks, portrait and nearby
conversation access, travel markers, and notifications. Keep discovery
knowledge-gated and leave merchant stock, budget, and fulfillment in
DynamicTrading for P7.
