# S4B Deterministic Generation Contracts

Snapshot: 2026-11-03.

## Accepted Core generation authority

PsychopatzCore SurvivorWorld now owns provider-neutral deterministic generation contracts for:

- world-seed resolution;
- population sector IDs and centers;
- population generation IDs;
- generation seed derivation;
- deterministic weighted choice;
- stable faction/community/group/actor IDs;
- default faction/community names;
- default community and mobile-group planning;
- bounded runtime-only adopter generation-policy extensions.

## PNC behavior preserved

The generic seed/name behavior is intentionally compatible with the current serialization-safe PNC algorithms being migrated.

Locked examples:

- generation seed for `123:GROUP:psector_1_2:7:fixture` = `1945112353`;
- settler seed 12345 -> `Clearwater Enclave`;
- looter seed 12345 -> `The Broken Fangs`;
- trader seed 12345 -> `Riverside Exchange Caravan`;
- refugee seed 12345 -> `Hope Collective`;
- looter community -> `Broken Fangs Hold`.

Default generic generation ranges/weights are also extracted from the current PNC population config:

- group size 2–4;
- community size 4–7;
- group type weights for REFUGEE/LOOTER/SCAVENGER/WANDERER;
- community faction weights for settler/trader/refugee/looter;
- generic group-type -> faction-archetype mapping.

## Canonical planning rule

Canonical plans are produced before adopter policy.

A community plan contains only generic world data such as:

- world/sector/generation identity;
- faction ID/archetype/name plan when a new faction is needed;
- community ID/name;
- location;
- compact population count;
- deterministic member actor IDs;
- leader actor ID.

A group plan contains:

- world/sector/generation identity;
- faction ID/archetype/name plan when needed;
- group ID/type/mission;
- location;
- deterministic member actor IDs;
- leader actor ID.

Body/equipment/facility/job/combat/behavior/needs policy is deliberately absent.

## Adopter policy registration

`Generation.Policies` is runtime-only and bounded to 16 registrations.

A registered policy receives a deep copy of the canonical plan and context and may return a serialization-safe extension payload. It cannot mutate canonical plan identity.

Policy presence/absence does not change canonical generation output for the same seed and request.

This is the seam ProjectHoomans may later use for equipment/body/facility policy without owning the Core world.

## Validation

Passing:

- `psychopatz_survivor_world_generation_smoke.lua`;
- exact PNC-compatible seed/name fixtures;
- canonical plan determinism before/after policy registration;
- policy capacity/cleanup;
- no PNC or DynamicTrading dependency;
- full Core Lua sweep: **135/142 pass**, with the same seven unrelated failures verified previously on clean HEAD;
- installed-PZ Kahlua compiler: **6/6 changed S4B production files**;
- `git diff --check`: pass.

S4 is now developer-complete. Next: S5 group-shared traversal and actor projection.
