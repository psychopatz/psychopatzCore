# Roadmap — Unified Vanilla World Event Semantics

## Parent objective

Create a Core-owned, lightweight, location-aware semantic bridge for Project Zomboid's vanilla world activity, cover all base-game live/meta/randomized-world event families as far as authoritative runtime evidence permits, make the resulting events/facts reusable by both ProjectHoomans and DynamicTrading, and use that grounded context to deepen dialogue variety and branching without reintroducing performance or persistence problems.

Developer completion is V0–V8. V9 is user-owned native acceptance.

## V0 — Exhaustive vanilla-event topology and coverage manifest

Audit the exact installed PZ build and current three repositories before implementation.

Inventory and classify:
- utility/state transitions;
- helicopter lifecycle and position authority;
- ambient meta sounds and coordinates;
- alarms;
- thunder/weather/climate lifecycle;
- radio/device/event surfaces where semantically authoritative;
- every `zombie.randomizedWorld` first-party package/class, including randomizedBuilding, randomizedDeadSurvivor, randomizedVehicleStory, randomizedZoneStory and randomizedRanch;
- any additional current vanilla event/story mechanism discovered by class/Lua/source inspection;
- current Core location/scoped-event/WorldKnowledge/persistence mechanisms;
- Hoomans event/Beat/spatial/location consumers;
- DynamicTrading scoped-event/market consumers.

Generate a deterministic machine-readable coverage manifest with no silent omissions and explicit unsupported/gap reasons.

**Gate (PASSED in V0):** exact installed-build manifest (`VANILLA_EVENT_COVERAGE.json`, 203 entries), source/event classification, authoritative observation seams, location strategy and consumer map verified via `tools/vanilla_event_coverage/generate_manifest.py --check` and `tests/test_vanilla_event_coverage_manifest.py`.

## V1 — Core normalized event observation and location contract

Add the smallest reusable Core contract required to normalize live events, state transitions and discoveries into existing ScopedWorldEvents/WorldKnowledge.

Requirements:
- stable semantic/source identity;
- bounded metadata;
- event phase/retention/salience;
- one location-resolution seam reusing current Core GridRegion/ActorLocation plus adopter authoritative providers;
- deterministic dedupe/fingerprints;
- no second event store.

If PZ-specific capture lives in Core, isolate it behind an explicit Project-Zomboid adapter namespace/capability so portable event/knowledge APIs do not hard-code game classes.

**Gate (PASSED in V1):** `PsychopatzWorldEventLocation.lua` and `PsychopatzVanillaEventObserver.lua` verified via `tests/psychopatz_vanilla_event_observer_smoke.lua`, `tests/psychopatz_scoped_world_events_smoke.lua`, and `pz_verify.py` (location fallback + zone + adopter provider, fail-closed missing authority, global-scope utility restriction, ephemeral exclusion, cooldown & fingerprint dedupe).

## V2 — Persistence and lifecycle hardening

Connect Core scoped-event payload serialization to the appropriate persistence lifecycle and prove save/load continuity.

Requirements:
- active events survive reload where retention requires;
- expired events do not reactivate;
- historical facts remain according to policy;
- utility transitions and discovery events are exactly-once;
- one scope/source/time bucket cannot accidentally stack duplicate evaluations;
- caps remain enforced after load/migration.

**Gate:** deterministic save/load, duplicate/reload, pruning/history-bound tests and no DT/Core split-brain event lifetime.

## V3 — Global vanilla utilities

Replace synthetic-global-event assumptions for the initial baseline. Global scope is initially reserved for authoritative:
- electricity cutoff;
- water cutoff.

Reuse `OnElectricityChanged` plus the existing bounded authoritative state reconciliation. Do not add another utility poller.

Publish semantic current-state/transition facts and allow Hoomans and DT to consume them independently.

**Gate:** exactly-once power/water transitions in SP/MP-compatible authority paths; save/load safe; no duplicate Beat path; synthetic food/raider/weather events no longer default global.

## V4 — Helicopter regional episode capture

Implement a location-aware helicopter episode using authoritative active/x/y state and the existing shared bounded cadence.

Requirements:
- start/update/end lifecycle;
- region/local-area scope through shared location resolution;
- capped meaningful coarse samples only;
- outdoor witnessed vs indoor heard acquisition;
- rumor/told/radio propagation through existing WorldKnowledge;
- location-grounded realization only when known;
- no continuous trajectory ModData.

**Gate:** deterministic fixtures show one event, bounded samples, indoor/outdoor provenance, coarse location change, episode close/reload and no per-frame/per-NPC work.

## V5 — Vanilla live/meta-event ingestion

Adopt every authoritative live event hook identified by V0, including at minimum:
- gunfire variants;
- scream;
- dog bark;
- owl;
- wolf howl;
- house alarm;
- thunder/weather lifecycle where useful.

Normalize exact source IDs into reusable semantic categories while preserving source detail. Apply salience/retention policy so low-value ambience does not fill persistent knowledge.

**Gate:** every V0 live event marked supported has a fixture; no full-world/NPC scans; low-value ambience remains bounded/ephemeral.

## V6 — Randomized-world discovery integration

Cover all installed randomized-world families as far as an authoritative cheap seam exists.

Mandatory examples include ambulance crash and other vehicle stories, bandit/police/crash/horde stories, camps/murder scenes, dead-survivor scenarios and building/ranch stories.

Rules:
- facts arise from actual world discovery/observation, never global omniscience;
- exact vanilla story identity is used only when authoritative metadata is exposed;
- otherwise publish grounded observable semantic facts rather than fabricated class identity;
- reuse shared location resolution;
- discovery work runs only on already-relevant loaded/observed local content, never world scans;
- update the coverage manifest with exact supported/gap status.

**Gate:** zone and vehicle exemplars including ambulance crash pass; building/dead-survivor/ranch strategy is implemented where feasible and evidence-backed gaps are explicitly documented.

## V7 — ProjectHoomans adoption and deeper branching

Route Core vanilla event facts into existing Hoomans WorldKnowledge and semantic conversation systems.

Requirements:
- actors discuss only facts they plausibly witnessed/heard/were told/read/heard on radio;
- no duplicate per-NPC event records;
- hard branch constraints use fact/item/relationship/location/condition authority;
- numeric disposition/demeanor/relationship/current context drives utility rather than literal trait classes;
- expand the eight thematic interactive families and event/gossip follow-ups with reusable semantic affordances, generally 3–5 potential meaningful directions at important nodes while retaining existing caps;
- support corroboration, contradiction, source questioning, uncertainty, silence, interruption, third-party witness/mediator and multiple terminal outcomes;
- increase realization variety after semantic selection;
- retain canonical EN/TL ownership.

**Gate:** thematic/event matrices prove materially greater branch/outcome diversity, contextual filtering and multi-actor epistemic dialogue without giant trees or fake choices.

## V8 — DynamicTrading adoption and exhaustive regression

DynamicTrading consumes the same Core events directly, not through ProjectHoomans.

Requirements:
- economically relevant utilities, route danger, local discoveries/conditions and future shared tags project one-way into DT MarketEvents/risk/opportunity policy;
- settlement/region effects use shared resolved location/scope;
- DT market-native events never recurse into Core world events;
- DT remains merchant/market authority only.

Run cross-repo regression:
- Core WorldEvents/WorldKnowledge/location/persistence;
- Hoomans dialogue, Beats, spatial, save/load and performance;
- DynamicTrading MarketEvents/pricing/caravan mobility/WorldKnowledge;
- CodeBuilder and Semantic Lab/Observatory where touched;
- Kahlua/static guards;
- event-heavy scale soak and ModData-size/boundedness checks.

**Gate:** every V0 coverage entry is accounted for; supported paths are verified; gaps are evidence-backed; no performance regression or duplicate authority; generated ownership remains clean; docs reconciled.

## V9 — User native SP/MP acceptance

User validates:
- utilities create grounded global knowledge;
- helicopter location and indoor/outdoor rumors are plausible;
- ambient/world-story discoveries are useful but non-spammy;
- ambulance crash and representative stories are location-grounded;
- dialogue has visibly richer outcomes and branches;
- traders react only where economically appropriate;
- save/reload and multiplayer remain stable;
- no noticeable lag or ModData growth.
