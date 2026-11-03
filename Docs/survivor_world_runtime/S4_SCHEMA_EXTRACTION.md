# S4A Survivor World Schema Extraction

Snapshot: 2026-11-03.

## Accepted Core generic records

PsychopatzCore now exposes one bounded, serialization-safe SurvivorWorld schema for:

- factions;
- communities;
- abstract locations;
- mobile groups;
- population sectors/bootstrap metadata;
- generation provenance/site history;
- player-scoped community/group/signal discovery.

The implementation lives under `PsychopatzCore/World/SurvivorWorld/`. A thin stable public facade exists at `PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld.lua`; it does not own a second registry.

## Bounds

- factions: 256;
- communities: 512;
- abstract locations: 4096;
- mobile groups: 1024;
- population sectors: 4096;
- discovery players: 256;
- group members: 128;
- discovery entries per player: 4096;
- generation provenance: 4096;
- site history: 4096;
- serialized SurvivorWorld envelope: 32 MiB hard cap.

Mutation and persistence boundaries reject oversized input. Direct normalizers remain deterministic by deduplicating, sorting, then truncating bounded collections.

## Generic PNC fields preserved

Faction:

- stable ID/seed/name/archetype/status;
- leader/member actor IDs;
- tags;
- generic diplomacy summary: standing, trust, fear, grievance, state, war/alliance/truce timestamps;
- lifecycle timestamps/revision;
- generation provenance.

Community:

- stable ID/seed/faction/name/mode/profile/status;
- canonical position/radius/site;
- leader/member actor IDs;
- population summary;
- security/morale;
- generic resource summary;
- lifecycle timestamps/revision;
- generation provenance.

Mobile group:

- stable ID/seed/faction/home community/type;
- leader/member actor IDs;
- mission/state;
- current and target locations;
- shared state timestamps;
- generic resources/morale;
- generation provenance;
- revision.

Abstract location:

- stable ID/seed/kind/position;
- generic tags/resources;
- scavenged level/danger;
- revision/provenance.

Population:

- world seed/string;
- generation serial/bootstrap state;
- starter community;
- bounded sectors/site history/provenance/committed generations.

Discovery:

- community/group/signal identities;
- discovery phase/source/time/position;
- arrival/presence summary;
- bounded faction-known metadata.

## Deliberately excluded Hoomans policy/runtime

The Core import contract does not carry:

- faction gameplay policy/provision/needs/excursion implementation;
- diplomacy incident histories/treaty implementation details;
- group combat profiles;
- behavior/ambient/player-roam AI;
- encounter reports/cooldowns;
- Hoomans community facilities/jobs;
- body/AI/path/perception/animation runtime;
- diagnostics/debug caches.

Those remain adopter policy/runtime unless a later Core contract explicitly requires a generic equivalent.

## Migration contract

`SurvivorWorld.Import.FromPNC()`:

- accepts plain serialization-safe tables;
- requires no PNC or DynamicTrading module/global;
- does not mutate the source;
- preserves existing PNC entity IDs;
- maps settlement discovery to generic community discovery;
- maps mobile-group discovery to generic group discovery;
- preserves signal discovery;
- rejects over-capacity source data rather than silently dropping records.

New Core-generated IDs use deterministic prefixes such as `faction_`, `community_`, `agroup_`, `aloc_`, and `psector_`.

## Validation

Passing:

- `psychopatz_survivor_world_registry_smoke.lua`;
- `psychopatz_survivor_world_pnc_import_smoke.lua`;
- `psychopatz_survivor_world_schema_smoke.lua`;
- `psychopatz_survivor_world_bounds_smoke.lua`;
- full Core Lua sweep: 134/141 pass with the same seven unrelated failures verified on clean HEAD;
- `luac -p`: all changed production Lua passes;
- installed-PZ Kahlua compiler: 14/14 SurvivorWorld/composition production files pass;
- `git diff --check`: pass.

Next: S4B deterministic generation contracts.
