# Audit — Unified Vanilla World Event Semantics

## Scope

Primary repository: `/home/psychopatz/Zomboid/Workshop/psychopatzCore`.
Participants: ProjectHoomans and DynamicTrading.
Installed Project Zomboid runtime was inspected directly from the current Steam installation.
Planning heads: Core `fecc800b05d0874e94a8600833880a77cd967e8d`, Hoomans `7847ccfb833425a2553bd9602aebaf958f76d7ed`, DynamicTrading `feee4da8fe4cab1ff4dcc1066ef1d4548b5728bb`.

## Existing reusable foundation

- Core already owns `PsychopatzScopedWorldEvents`: bounded active/history state, global/region/faction/settlement/local-area scopes, secondary indexes, listeners, aggregate effects and payload serialization.
- Core already owns `WorldKnowledge` / `PsychopatzWorldFact` / actor knowledge with provenance, confidence, retention and bounded per-actor references.
- Core already owns reusable location primitives including `PsychopatzActorLocation` and `PC_GridRegion`.
- DynamicTrading already consumes `PsychopatzCore.ScopedWorldEvents` and keeps its separate `DTCommon.MarketEvents` economic authority.
- ProjectHoomans already has a 10-second environment/Beat cadence, utility readers, `OnElectricityChanged`, `OnAmbientSound`, `OnWorldSound`, WorldKnowledge projection, numeric disposition/demeanor, and scoped-event consumers.

Conclusion: extend existing Core authority. Do not add another event registry, gossip store, location database, timer loop, or Hoomans-owned shared event authority.

## Dialogue depth finding

The current canonical corpus has 13 real flow graphs, all in ProjectHoomans. Average nodes per flow: 4.0; maximum: 6. Average branch offers: 3.85. Only 1 of 13 flows currently has any constrained branch offer.

Depth should increase through reusable semantic affordances, contextual eligibility, numeric utility, alternative outcomes, interruption/resume, multi-actor evidence, consequences and realization variation. Do not build giant sentence trees.

## Vanilla event surfaces verified from the installed build

### Global state transitions

Initial mandatory global events:
- electricity cutoff;
- water cutoff.

Hoomans already derives these from vanilla authority. Electricity exposes `Events.OnElectricityChanged`; water should reuse bounded reconciliation of authoritative sandbox/world state rather than a new poller.

### Helicopter

`zombie.iso.Helicopter` exposes active state and world `x/y` and is server synchronized. No dedicated Lua start/end callback was identified. Detect transitions through an existing bounded shared cadence, sample only meaningful coarse location changes, and never persist continuous flight telemetry.

### Ambient meta events

The installed runtime emits `OnAmbientSound(name, x, y)` from the vanilla ambient constructor. Verified source IDs include:
- `MetaAssaultRifle1`;
- `MetaPistol1`, `MetaPistol2`, `MetaPistol3`;
- `MetaShotgun1`;
- `MetaDogBark`;
- `MetaScream`;
- `MetaOwl`;
- `MetaWolfHowl`.

Normalize them into reusable semantic categories while preserving exact vanilla source ID as bounded metadata.

### Other live signals

V0 must classify and adopt where useful:
- house alarms;
- thunder and weather-period lifecycle;
- significant weather transitions;
- radio/device/news surfaces only where authoritative semantic facts can be obtained without reparsing arbitrary rendered prose;
- any additional vanilla event surface discovered during the installed-build audit.

### Randomized-world discovery content

Installed first-party randomized-world families, excluding helper inner classes:
- randomized building: 45 classes;
- randomized dead survivor: 33 classes;
- randomized vehicle story: 26 classes;
- randomized zone story: 42 classes;
- randomized ranch: 2 classes.

Examples include ambulance crash, bandit road, police blockade/shooting, crash horde, murder scene, survivalist camp, tragic picnic, bandit raid, police-at-house, suicide pact, zombies eating, gunstore siege, looted/burnt/safehouse stories and many others.

Zone stories expose `pickedRzStory` and picked coordinates; the story object exposes `getName()`. Vehicle story spawn data carries story identity and spawn coordinates. `BuildingDef` does not expose an obvious randomized-building identity field, so exact building/dead-survivor provenance must be captured only if a cheap authoritative seam exists. Otherwise publish grounded observable scene facts rather than inventing an internal story class.

## Mandatory coverage manifest

Development tooling must generate a deterministic `VANILLA_EVENT_COVERAGE` manifest from the installed PZ build/source surfaces. Every discovered first-party event/story family must be classified as:
- supported live event;
- supported state transition;
- supported discovery event;
- supported through a generic semantic-family adapter;
- intentionally ephemeral/presentation-only;
- blocked by a missing authoritative observation seam, with evidence.

No silent omission. Runtime must never scan the JAR or continuously enumerate all world stories.

## Performance conclusions

The lightweight route is event/transition driven:
- use native hooks where available;
- reuse an existing shared coarse cadence only where vanilla exposes no hook;
- resolve location once at ingestion/discovery;
- register one canonical event/fact, not one copy per actor;
- actors keep only bounded fact references/provenance;
- do not store per-frame helicopter coordinates;
- do not rescan all cells/buildings/zones/stories;
- do not scan all NPCs for every event;
- low-value ambience is ephemeral by default.

## Location conclusion

Raw `x/y/z` is observation input, not persistent semantic identity. Normalize through a Core location-resolution contract that reuses current Core grid/actor location primitives plus adopter-provided authoritative named region/settlement/local-area resolution. Persist stable location references plus only minimal coarse coordinates when unresolved. Never create a parallel Hoomans-only location store for shared events.

## Ownership conclusion

Core owns normalized observation, bounded scoped-event lifecycle/persistence, event/fact identity and provenance, location-resolution interface, optional PZ adapter capability boundary, and coverage tooling.

ProjectHoomans owns NPC acquisition/witness/hearing policy, demeanor, dialogue/Beat/Scene policy and simulation consequences.

DynamicTrading owns economic interpretation, MarketEvent projection, market pressure, caravan/trader risk and market presentation.
