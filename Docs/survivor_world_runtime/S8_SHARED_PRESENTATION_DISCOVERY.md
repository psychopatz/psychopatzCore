# S8 Shared SurvivorWorld Presentation and Discovery

Snapshot: 2026-11-04.

## Accepted ownership

PsychopatzCore SurvivorWorld now owns the reusable presentation/discovery truth used by both ProjectHoomans and DTAbstract:

- canonical per-actor projection keyed by actor ID;
- group/community/faction/role context;
- group-shared journey route/progress/ETA;
- deterministic overlap spreading;
- provider-neutral portrait payload and descriptor conversion;
- selection, highlight and tracking state;
- player-scoped community/group/signal discovery;
- discover-all/reset debug actions, including bounded per-entity reset;
- server-authoritative discovery transport.

Adopters retain only policy/presentation details that are not generic world truth.

ProjectHoomans retains:

- Hoomans-specific visibility and map-command policy;
- tactical colors/icons/labels;
- physical body rendering/AI/runtime behavior;
- radio/contact gameplay actions;
- Hoomans-specific discovery compatibility view for existing callers.

DTAbstract retains:

- trader/commercial labels;
- merchant stock/budget/economy state;
- nearby notification hysteresis/cooldown;
- DTAbstract debug actions that are commercial/provider-specific.

## Core presentation contract

The existing S8A foundation in Core provides canonical actor entries from SurvivorWorld + ActorRegistry.

S8 completion adds:

- bounded demand-driven actor refresh;
- slower bounded discovery refresh;
- a shared client portrait-spec conversion;
- a lazy-loaded provider-neutral map-hover portrait host;
- per-entity discovery reset for debug tooling.

No background Core tick was added. Consumers request projections only while map/nearby/debug surfaces need them.

## Physical/abstract parity

ProjectHoomans registers a provider-neutral Core position provider for materialized bodies.

When a canonical actor has a live Hoomans body:

- actor/group/community identity stays unchanged;
- the live body supplies only the physical position;
- Core reports the provider source;
- all route/group/discovery identity remains Core-owned.

When no live body exists, the same actor falls back to Core group/actor projection.

This keeps marker identity stable across abstract -> physical -> abstract representation changes.

## ProjectHoomans cutover

ProjectHoomans travel/map presentation now consumes Core actor projections first.

For canonical SurvivorWorld actors:

- Core owns projected position and route;
- Core overlap spreading is not repeated by Hoomans;
- Hoomans enriches the entry with its tactical/identity metadata;
- map selection mirrors Core selection;
- map hover mirrors Core highlight;
- map tracking uses Core tracking;
- legacy Hoomans-only actors/death markers remain supported outside the canonical projection.

Generic discovery snapshots/debug actions now use Core transport.

Hoomans-only radio/contact policy remains on the Hoomans command surface.

The server compatibility bridge mutates only Hoomans-owned community/group fields and preserves Core-only signal discovery. Legacy discovery ModData remains a migration/fallback path rather than active generic save authority.

## DTAbstract cutover

DTAbstract no longer keeps transient trader discovery truth.

Nearby trader contact:

- reads the canonical Core actor position;
- maps the trader to its canonical Core group/community;
- advances Core discovery with `mark_contacted`;
- keeps only ephemeral inside/cooldown notification state.

The DTAbstract map now consumes:

- Core community/group/signal discovery;
- Core actor dots;
- Core group routes;
- Core overlap-spread positions;
- Core portrait hover;
- Core selection/highlight/tracking state.

DT-specific trader labels and commercial destination names remain adopter-owned.

The debug hub reads Core actor projection/discovery and uses Core discover/reset actions.

## Performance and debug behavior

- Core actor refresh is demand-throttled rather than a background full-world loop.
- Discovery refresh uses a slower demand throttle.
- Core portrait UI is lazy-required only on actual hover.
- DTAbstract no longer scans/project positions through a second actor-world read model for map/nearby truth.
- Debug discover/reset actions are request-driven and server-authoritative.
- Disabled debug paths do not add a continuous simulation loop.

## Validation

PsychopatzCore:

- S8-focused discovery, presentation and transport tests pass;
- full Lua sweep: **141/148**;
- detached clean HEAD `cae306c`: **141/148** with the exact same seven unrelated failures:
  - `psychopatz_command_hub_callback_smoke.lua`;
  - `psychopatz_image_resolver_smoke.lua`;
  - `psychopatz_label_layout_smoke.lua`;
  - `psychopatz_profiler_client_composition_smoke.lua`;
  - `psychopatz_profiler_server_composition_smoke.lua`;
  - `psychopatz_widget_window_smoke.lua`;
  - `psychopatz_world_inventory_smoke.lua`;
- changed S8 production Lua: **4/4** luac + installed-PZ Kahlua.

ProjectHoomans:

- focused Core world-discovery client/server cutover, live-body projection, travel-directory, map/hover and MP loader regressions pass;
- full suite: **995/1000**;
- the same five unrelated semantic/harness baselines remain:
  - companion camp rejection wording;
  - semantic harness protocol message-bound expectation;
  - horde command acknowledgement wording;
  - horde tactical prompt profanity expectation;
  - local-route fishing wording;
- changed S8 production Lua: **10/10** luac + installed-PZ Kahlua.

DynamicTrading:

- full suite: **62/62**;
- map contract covers Core community/group/signal discovery, actor route, overlap position, hover, select and track;
- nearby-discovery regression proves Core is the durable discovery authority;
- changed S8 production Lua: **3/3** luac + installed-PZ Kahlua;
- the two unrelated `mod.info` edits remain uncommitted.

All three repositories pass `git diff --check` for the S8 slices.

## Commits

- existing Core S8A foundation: `cae306c`;
- PsychopatzCore S8 completion: `baaf075`;
- ProjectHoomans S8 cutover: `5c9988e8`;
- DynamicTrading S8 cutover: `dc13226b`.

## Native status

No native Project Zomboid SP/MP visual acceptance is claimed here.

S8 developer-side acceptance is complete. Native map/hover/provider-transition behavior remains part of the final S10 user-owned acceptance matrix.

## Next

S9 audits and removes remaining DynamicTrading attachment/compatibility paths so DTCommon queries canonical Core communities/actors/groups without redundant world authority, while preserving trader/economy invariants.
