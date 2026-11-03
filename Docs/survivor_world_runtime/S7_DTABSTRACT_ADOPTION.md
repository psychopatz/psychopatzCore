# S7 DTAbstract SurvivorWorld Adoption

Snapshot: 2026-11-03.

## Accepted ownership

DTAbstract no longer owns a parallel survivor world.

PsychopatzCore SurvivorWorld owns:

- canonical factions;
- canonical communities/settlements;
- canonical mobile groups;
- canonical actor identity;
- group-shared journeys and projected positions;
- compact world persistence and bootstrap identity.

DTCommon continues to own commercial state:

- trader role binding;
- merchant stock;
- budgets;
- commercial visit/exchange effects;
- commercial lifecycle/cooldowns.

DTAbstract owns only the lightweight representation and notification/radio interaction path.

DTHoomans remains a physical representation/execution provider and no longer registers a second settlement geography authority.

## Standalone bootstrap

DTAbstract activates the Core SurvivorWorld when ProjectHoomans is absent.

The Core bootstrap deterministically exposes two trader caravans by default so DTCommon's bounded two-roaming-trader target binds existing canonical group leaders rather than creating extra actors or groups.

Same seed/anchor/config produces the same Core faction/community/group/actor identities used by the DTAbstract composition.

Untouched abstract actors remain compact and do not require live bodies, AI, or FULL personal inventory.

## Trader binding and traversal

Creating a DTAbstract trader now creates only the DTCommon commercial role record.

It does not create:

- a new survivor actor;
- a new survivor group;
- an actor-owned duplicate journey;
- a static Kentucky settlement.

Movement starts and advances Core GroupJourney on the canonical mobile group. Actor position is projected from that group journey.

Commercial arrival remains exactly-once through DTCommon.

## Representation handoff

DTCommon representation switching passes the source provider's canonical projected position into physical materialization.

DTHoomans returns the body's final physical position on dematerialization.

The return abstract provider rebases the Core group journey from that final position, preserving the same actor/group identity across abstract/physical representation changes.

## Settlement identity

DTCommon registers one Core community settlement-directory provider.

The former DTHoomans settlement-directory provider was removed. DTHoomans travel policy accepts the canonical Core community ID and resolves Hoomans routing against that ID rather than introducing another settlement identity/provider.

Automatic static Kentucky settlement registration is disabled.

## Legacy migration

Recognized pre-S7 standalone DTAbstract actors (`actor:dt:world:*` / `actor:abstract:*`) are rebound once to an unused canonical Core trader-group actor.

The commercial trader record, stock and budget are preserved.

Obsolete actor-owned/static-settlement travel is reset at the canonical home community because it cannot be safely mapped by identity to the new world.

The old standalone actor is retired only after replacement lease acquisition succeeds.

Failed new commercial binding rolls the temporary Core lease back.

## Validation

DynamicTrading:

- full suite: **62/62**;
- abstract map, nearby discovery, debug hub and settlement-directory regressions pass;
- provider hot-swap/handoff/inventory regressions pass;
- same-seed Core identity parity passes with ProjectHoomans absent;
- legacy rebind and failed-bind rollback pass;
- changed production Lua: **11/11** luac and installed-PZ Kahlua;
- duplicate-authority source audit finds no DTAbstract actor-journey/static-world persistence authority;
- only the user's two pre-existing `mod.info` edits remain unstaged.

Core:

- SurvivorWorld-focused tests pass;
- full Lua suite: **138/145**, with the same seven unrelated baseline failures;
- bootstrap production Lua passes luac and installed-PZ Kahlua.

Commits:

- PsychopatzCore `5045522` — expose two canonical trader caravans;
- DynamicTrading `bbd14454` — adopt Core SurvivorWorld in DTAbstract.

## Next

S8 migrates provider-neutral map, discovery, selection/highlight/tracking and debug presentation contracts into Core so abstract and physical compositions expose identical world entities and controls.
