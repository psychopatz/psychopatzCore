# Architecture — Unified Vanilla World Event Semantics

## 1. Objective

Expose Project Zomboid's real world activity as one reusable, bounded semantic event/fact stream owned by PsychopatzCore so ProjectHoomans, DynamicTrading and future adopters can consume the same grounded world truth without depending on one another.

```text
Project Zomboid authority
  -> vanilla event/state/discovery adapter
  -> Core normalized observation
  -> Core location resolution
  -> Core ScopedWorldEvents when episodic
  -> Core WorldKnowledge fact when knowledge-worthy
  -> adopter projection
       ProjectHoomans: witness/hear/told knowledge, demeanor, Beats/Scenes, simulation
       DynamicTrading: MarketEvents, risk/opportunity, pricing/logistics
```

## 2. Single-authority rules

- `PsychopatzScopedWorldEvents` remains the sole shared scoped-event lifecycle authority.
- Core `WorldKnowledge` remains the sole shared fact/actor-knowledge authority.
- Existing Core location/grid primitives remain the shared spatial substrate; adopter-specific region/settlement providers may resolve stable IDs through a narrow adapter.
- `DTCommon.MarketEvents` remains DynamicTrading economic authority, not another world-event ledger.
- Hoomans DialogueBeats/Scene Runtime remains social/presentation policy, not event authority.

## 3. Normalized observation contract

Derive the exact schema against current Core types. Conceptually an observation contains bounded primitives/references only:

```text
sourceID / sourceKind
semanticType
occurredAt / observedAt
phase: start | update | end | discovery | transition
raw position when supplied by PZ
resolved locationRef / regionID / settlementID / localAreaID when known
severity / salience
provenance
bounded source-specific metadata
```

Preserve exact vanilla source identity for diagnostics/coverage while exposing stable semantic categories to consumers.

## 4. Scope policy

Initial global events are deliberately limited to:
- electricity cutoff;
- water cutoff.

Helicopter and localized meta events use region/local-area scope. Randomized-world stories are discovery facts tied to their actual location. Future synthetic crises may use region/faction/settlement/local scopes, but must not default to global merely because location resolution failed.

## 5. Location contract

Reuse the existing Core location system instead of adding a second map model.

- Accept authoritative vanilla `x/y/z`.
- Resolve stable Core/adopter location IDs once per observation or meaningful helicopter region transition.
- Prefer named place/region/settlement/local-area refs over raw coordinates in persistent facts.
- Use coarse/quantized fallback location only when no authoritative named location exists.
- Never persist high-frequency position trails.
- Never make every consumer independently locate the same event.
- A resolver may query adopter-owned settlement/population indexes, but Core must not copy those registries into its state.

## 6. Helicopter episode model

Helicopter is a bounded episode, not telemetry:

```text
inactive -> active: register/start event + fact candidate
active -> active, same coarse location: no write
active -> active, crossed meaningful location bucket: optional capped update/sample
active -> inactive: close event
```

Persist only a small bounded set of meaningful coarse samples (guideline 4–6, subject to profiling) or a compact start/latest/end representation. Reuse an existing shared cadence; never add a per-frame loop.

Actor epistemics reference the same fact/event:
- outdoor direct observer: witnessed/experienced, high confidence;
- indoor nearby listener: environmental/heard-indoor, lower precision;
- conversation recipient: told;
- radio recipient: radio.

Indoor acquisition changes actor knowledge provenance, not event identity.

## 7. Ambient/live meta-event model

Prefer native hooks. `OnAmbientSound(name,x,y)` is authoritative for vanilla ambient meta sounds and already carries event position.

Default retention policy:
- gunfire/scream/alarms: local short-lived event/fact with salience policy;
- dog/wildlife: ephemeral context unless promoted by another domain;
- thunder/weather: context/Beat input, historical only for meaningful episodes;
- utility cutoff: durable historical global fact plus current state;
- helicopter: bounded regional episode and historical fact.

## 8. Randomized-world discovery model

World stories become semantic facts only when actually discovered/observed through a bounded authoritative seam.

Do not scan the whole world for stories.

Preferred strategies:
- zone stories: consume `pickedRzStory`/picked coordinates when the relevant zone is already observed/loaded/discovered;
- vehicle stories: use story/spawn metadata at a verified creation or discovery seam;
- building/dead-survivor/ranch: capture exact story identity only if a cheap authoritative seam exists; otherwise publish grounded observable scene facts using already-relevant local discovery work.

Ambulance crash and similar content are therefore location-grounded discoveries, never global random news.

## 9. Coverage manifest

Development tooling must inspect the current installed PZ runtime and create a deterministic machine-readable coverage manifest. For every discovered source, record:
- source category;
- vanilla ID/class;
- observation seam;
- normalized semantic category;
- location support;
- retention/salience policy;
- Core/Hoomans/DT consumer support;
- evidence-backed gap when unsupported.

Runtime never reflects over the JAR.

## 10. Persistence and dedupe

- Connect `PsychopatzScopedWorldEvents.ToPayload/LoadPayload` to a real persistence owner where event retention requires save continuity.
- Stable IDs/dedupe prevent repeated callbacks or reloads from creating duplicate events.
- Utility transition watermarks prevent repeated cutoff facts.
- Helicopter episode identity prevents duplicate starts within the same occurrence.
- Discovery identity uses stable story/place identity where available or a stable location+semantic fingerprint when exact story identity is unavailable.
- Expired active effects stop affecting consumers while historical facts may remain by retention policy.

## 11. Consumer contract

Consumers react to semantic categories/tags/effects rather than long source-name switches when a category is sufficient.

ProjectHoomans:
- determines who could plausibly witness/hear/learn using bounded nearby actors/settlements and existing spatial services;
- derives branch eligibility from grounded facts and soft choice from numeric disposition/relationship/context;
- may project temporary demeanor/simulation effects through owning systems;
- never creates omniscient dialogue.

DynamicTrading:
- projects only economically relevant Core events into DT MarketEvents;
- uses shared scope/location for settlement/route/caravan effects;
- never feeds market-native events recursively into Core world events.

## 12. Dialogue depth contract

- Preserve max 8 visible offers, max 4 participants and max 8 Scene turns.
- Prefer reusable semantic affordances and `after.recommend` over giant embedded branch trees.
- Important interactive nodes should generally have 3–5 potential semantic directions, with 2–4 surviving contextual filters in ordinary cases.
- Hard constraints represent factual eligibility; numeric utility represents preference/tendency.
- Stance and semantic outcome remain separate.
- Add multiple meaningful terminal outcomes rather than wording-only branches.
- Realization variety happens after semantic selection and may use disposition, relationship, epistemic precision and provenance.

## 13. Performance invariants

Forbidden:
- new independent OnTick loops;
- per-NPC event polling;
- full-world zone/building/story scans;
- continuous helicopter coordinate persistence;
- duplicated event record per actor;
- unbounded event/fact/transcript history;
- rendered-text reparsing for meaning;
- runtime JAR reflection;
- pairwise/N^2 actor propagation.

Required:
- hook-driven ingestion where possible;
- existing coarse shared cadence where hooks do not exist;
- bounded caps/indexes;
- resolve location once;
- actor knowledge stored as refs;
- fail closed on missing authority;
- debug-off/event-heavy performance regression evidence.
