# S6 ProjectHoomans SurvivorWorld Adoption

Snapshot: 2026-11-03.

## Accepted ownership

ProjectHoomans no longer owns a second generic faction/community/location/group persistence authority.

Canonical generic state:

- PsychopatzCore SurvivorWorld RuntimeStore;
- factions;
- communities;
- abstract locations;
- mobile groups;
- shared group journeys;
- population metadata.

Hoomans retains one bounded extension root only for adopter-specific state that Core deliberately does not own:

- faction gameplay policy/provision/emblems/mobile policy/needs and non-generic relation details;
- community capacity/site metadata and Hoomans-only supply detail;
- abstract combat/behavior/action/encounter/runtime-policy data;
- occupancy/history/source-site data required by Hoomans gameplay.

Generic fields are rebuilt into the PNC runtime compatibility views from Core and are not duplicated in the extension root.

## Migration

First supported legacy load:

1. existing PNC faction/community/abstract registries load read-only;
2. Core one-way importer creates the canonical SurvivorWorld;
3. Hoomans-only extension fields are captured;
4. Core and extension roots are persisted;
5. only after both writes succeed are the old generic roots retired;
6. later loads rebuild PNC runtime views from Core + extension state.

Re-import over a non-empty Core world is rejected.

## Mutation authority

Generic mutation paths commit to Core through the Hoomans SurvivorWorld adapter. Focused audit also closed bypasses in:

- abstract scavenging: group resources + location scavenged level;
- abstract casualty reconciliation: group membership.

Group travel already uses Core GroupJourney from S5.

## Save authority cleanup

The production persistence coordinator now performs one SurvivorWorld save for the generic world plus Hoomans extension state.

Legacy result names for factions/communities/abstractWorld remain diagnostic aliases only; they do not trigger separate writes.

Legacy generic Save methods:

- delegate to the active SurvivorWorld cutover;
- fail closed when Core authority is present but cutover is unavailable;
- retain isolated legacy fallback only when the Core authority module is not composed.

Legacy generic roots are therefore read-only migration sources in production.

## Validation

Core:

- SurvivorWorld focused tests pass;
- full suite remains 137/144 with the same seven unrelated baseline failures;
- S6B Core compatibility files pass luac and installed-PZ Kahlua.

ProjectHoomans:

- migration/cutover/reload/save-redirect/adapter tests pass;
- abstract world foundation/phase2 and mobile-group regressions pass;
- full suite: 991/996 with only the same five unrelated semantic/harness failures;
- S6B changed production Lua: 11/11 luac and installed-PZ Kahlua;
- S6C changed production Lua: 4/4 luac and installed-PZ Kahlua;
- git diff checks pass.

Commits:

- Core `4933793` — preserve Hoomans generic world values;
- Hoomans `5d6e1e8e` — route generic mutations through Core;
- Hoomans `ab19fe69` — cut generic persistence over to Core;
- Hoomans `3f523dc8` — remove duplicate active generic save authority.

## Next

S7 migrates DTAbstract onto the same Core SurvivorWorld with ProjectHoomans absent.
