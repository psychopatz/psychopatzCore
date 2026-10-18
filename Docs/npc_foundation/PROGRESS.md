# Core NPC Foundation — Current Progress

Snapshot: 2026-10-18. Evidence scope: remote GitHub main source inspection, no live runtime or local worktree validation. Goal docs are new; no foundation production implementation is claimed.

## Planning input revisions (recheck on agent entry)
- PsychopatzCore main afbc668c8f5affc1f950dd9529604b548b747c6a
- ProjectHoomans main a3eb2e4db553f9c03b7f66a6ff6717878e1668e0
- DynamicTrading main 2b1975a213636095080b223bd3945007f42f86be
- MarketSense dependency version: NOT INSPECTED here; must inspect on entry.

## Verified source findings, not runtime acceptance
- Hoomans identity producer has resolved SurvivorFactory name/voice/appearance; its profile normalizes seeds/archetypes and persisted visual fields.
- Hoomans NewRecord already blends identity, equipment, initial inventory, social, health, presence and runtime data; cannot copy it into Core as-is.
- Hoomans inventory templates generate clothing, bags, weapons and supplies and support SEED_ONLY, BASELINE_DELTA and FULL persistence; Core already has reusable portable inventory/transfer primitives.
- Hoomans map registry patches ISWorldMap.render; travel layer projects markers; hover uses Core PortraitPanel. Map/hover provider still depends on PNC knowledge/faction systems.
- Hoomans personal relationships are directed with canonical queries/commands; stored in Hoomans NPC social records.
- Hoomans persistence docs specify unsupported schema versions are RESET, not migrated — a critical unsafe old-save path needing an explicit staged migrator.
- DTCommon validates nearby/radio access on snapshots and transactions, but radio can currently authorize direct trade; strict physical fulfillment is NOT yet designed/accepted.
- DTHoomans caravan lifecycle depends on PNC mobile factions, and settlement trader binding depends on Hoomans-generated faction staff.
- DT trading MVP progress says native SP/MP final T6 acceptance remains open. Do not mark it closed or subsume it.

## Current phase
P0 — source ownership/extraction audit. Status NOT STARTED as implementation.
Next Chunk EXACTLY P0A (see PHASE_0_EXTRACTION_AUDIT.md).

## Next Chunk: P0A
Build a current-HEAD, field-level source→Core target matrix for NPC identity (including name/seed/voice), appearance/worn visuals, starter item generation, exact portable inventory identity/state, relationships/personality, journey/position and DT merchant linkage. Identify canonical writers, serialized keys, normalization/generator versions and load order. Create ONE runnable source-backed parity baseline using current modules/harness to capture one merchant/NPC before/after legacy serialize/deserialize, verifying no rerolls and enumerating currently failing parity gaps. No gameplay code migration in P0A.

Exit: provenance matrix and no-loss migration preconditions checked into architecture job docs; runnable parity test with honest pass/fail; explicit list of unsupported source versions and blocker/fallback. Only then advance P0B and P1.

## Evidence that remains OPEN
Native SP/MP parity; portrait rendering and actual ISWorldMap interaction; mixed-mod load order; hot provider switch; old save migration; relationship price policy; settlement restock; real trader trade authorization after migration; performance. No tests were run while preparing these goal docs.

## Standing boundary
No Workshop publication or republication. No silent destructive migration. No automated agent claim of manual live gameplay acceptance. Existing DT trading, Radio OS and semantic harness goals remain separate.
