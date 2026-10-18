# NPC foundation migration risks

Status: P0A audit artifact plus P0B implementation evidence, 2026-10-18.
These controls remain prerequisites for any production import writer. P0A and
the current P0B fixture do not migrate live saves, rewrite ModData, or change
production ownership.

## Confirmed risks and current evidence

| Risk | Evidence | Required control |
| --- | --- | --- |
| Exact-version reset can destroy the only readable copy | Hoomans persistence checks the exact `PERSISTENCE_VERSION` (`16`) and rejects unsupported roots; the documented behavior resets/discards malformed or unsupported records. | Read source roots before Hoomans hydration. Copy the untouched raw payload to a versioned quarantine/backup, validate it, and only then produce a Core import candidate. Never pass an unknown payload through a reset path as an import strategy. |
| Authored appearance policy is currently dropped | Appearance policy schema 2 is consumed by `RollAppearance`, but `Types.NormalizeDefinition` and `Persistence.SerializeRecord` do not carry `record.appearance`. | Add an explicit policy field/adapter before claiming appearance parity. Until then, mark imports requiring exact slots/outfit/voice modes as blocked or preserve them in an opaque source envelope. |
| Full SurvivorFactory voice profile is not serialized | The factory produces `voicePrefix`, `voiceType`, and `voicePitch`; the current identity sanitizer writes only the legacy `voice` field. | Add a versioned Core voice profile and an Hoomans compatibility projection. Do not reconstruct missing voice details from a new factory call. |
| Portable inventory metadata is incomplete | The P0B source-backed characterization passes `customName = "Ledger"` and `itemState.modData.source = "p0b"`, but `legacyTemplateKey = "legacy:p0b:item"` becomes `nil` after the current CoreBridge/delta metadata path. `StateCodec.metadata` has no legacy-template slot. | Add an explicit versioned metadata field or preserve the complete source item envelope. Until then, promote/quarantine records carrying `legacyTemplateKey` or any unrepresentable state. Never silently replace a legacy template with a current template. |
| Seed-only inventory can change when definitions change | Hoomans `SEED_ONLY` replays current archetype/loadout/equipment definitions from seed and generator version. | Require matching generator version, archetype definition revision, equipment pool revision, and template reference. Otherwise use a delta/full payload or quarantine for review. |
| Duplicate identity and trader links can split authority | Hoomans actor IDs, DT `traderID`, DT physical binding `p`, faction binding `g/l/m`, and Core's future actor ID are different namespaces. | Build an immutable mapping ledger. Reject one-to-many and many-to-one collisions unless an explicit, reviewed alias record exists. Keep DT merchant stock separate from personal inventory. |
| Social target identity is exact and directed | Relationship keys include NPC IDs and player account plus character UUID. The service rejects username-only player identity. | Preserve target keys byte-for-byte, deduplicate memory IDs deterministically, and require an authoritative player-character map before importing player relationships. Never substitute a username. |
| Inventory item IDs and body projections can duplicate | Hoomans inventory can be abstract, hydrated into a body, and captured again; body leases and native item instances are not canonical identity. | Import only the portable ledger. Reconcile one body lease after load, with a single transfer token and idempotency key. Never import both an abstract item and a live native copy as independent items. |
| Radio access can authorize distant DT trade today | `DTCommon_TraderService.validateAccess` currently permits `record.a == 1` with an active player radio when no nearby body is present. | Treat radio-authorized physical fulfillment as a known DT migration blocker. P0A does not change it; a later DT phase must separate abstract quotes from physical item transfer and preserve MarketSense valuation. |

## Conditional risks requiring P0B/P1 fixtures

| Risk | Why it matters | Required preflight |
| --- | --- | --- |
| Unsupported or partially indexed source versions | The current audit verified only Hoomans persistence 16 and the listed component schemas. Older Workshop saves and untracked media history were not established as supported inputs. | Enumerate every source version actually present in the target save set. Unknown versions fail closed and remain untouched. |
| Native item type or visual no longer exists | Core compact records may carry a type ID whose Build 42 script or visual is unavailable on the target installation. | Resolve type IDs and visual descriptors before commit. Preserve an opaque source representation or quarantine; do not silently substitute a different item or clothing slot. |
| Position versus active journey conflict | A record can contain position/anchor and an active travel record. Presence materialization also has a body position. | Choose one journey/location authority, compare revisions/timestamps, and emit a conflict report before applying. Never merge by last writer without provenance. |
| Stale body lease / online ID | Body hints are startup hints, not actor identity, and may refer to a body from a prior process or population. | Validate lease, population, online ID, and actor tags against the live registry. If uncertain, quarantine the hint and materialize exactly one fresh projection. |
| Active trade during extraction | DT stock, budget, quote revision, player transfer, and persistence can be observed at different moments. | Acquire server-side transaction/revision fence, snapshot stock and budget together, and replay no in-flight transaction. A failed fence aborts the import. |
| Multiplayer split-brain | Core actor, Hoomans body, and DT merchant services may be loaded by different authorities or module combinations. | Run only on the server authority; verify module manifests, provider registration, save generation, and actor mapping before clients receive a snapshot. |
| Map knowledge leakage | Hoomans map hover and layers gate identity/portrait by knowledge and faction queries. | Import presentation metadata without granting discovery. Recompute per-player knownness from authoritative knowledge state. |
| Physical body simulation crosses the ownership boundary | Core must not own IsoZombie, combat, health, jobs, needs, faction staff, or colony lifecycle. | Keep physical fields in a Hoomans projection/lease adapter. A Core import must contain no Java/native engine objects. |
| MarketSense valuation drift | DT stock and quotes depend on MarketSense intrinsic valuation plus DT margins. | Snapshot valuation inputs/version and keep pricing/fulfillment in DTCommon. Core identity migration must never recalculate or overwrite merchant price policy. |

## Reversible import protocol

The first real import must be a read-only dry run with a durable ledger. The
minimum transaction shape is:

1. Capture source repository/save heads, module manifests, schema versions,
   source record hash, and the raw payload without modification.
2. Validate the source version, actor ID, identity seed, generator references,
   item type/state representability, social target keys, journey/location
   revision, and DT transaction fence.
3. Produce a candidate Core record and a field-level decision log containing
   `copied`, `recomputed`, `projected`, `quarantined`, or `rejected` for every
   field in `FIELD_OWNERSHIP_MATRIX.md`.
4. Serialize the candidate, deserialize it in a fresh in-memory registry, and
   compare canonical hashes for identity, resolved appearance, personal
   inventory, equipment slots, relationships, and location. Compare merchant
   stock/budget separately through DTCommon.
5. Commit only an idempotent mapping ledger and Core record after the complete
   candidate set passes. Keep the raw source and decision log so rollback is a
   delete/disable of the candidate mapping, not a destructive rewrite.

The adapter must refuse to commit if any required field is unknown,
unrepresentable, colliding, or observed during an active transaction. A
successful dry run is not manual SP/MP acceptance and does not authorize
Workshop publication.

## P0B fixture evidence

Hoomans commits `72455cd1` and `3b8404fb` add a read-only
`PNC.Persistence.ImportPlan` and focused smoke tests. The fixture preserves a copied raw
payload and source snapshot, builds a canonical in-memory candidate only when
all required fields are representable, and records field-level actions. It
quarantines missing authored appearance policy, incomplete voice profiles,
missing relationship/location state, unsupported persistence versions, and
items carrying `legacyTemplateKey`. It never calls the reset path or writes
ModData. The focused source-backed suite passed `6/6`; this is harness
evidence, not live-game acceptance.

The focused source-backed suite now passes `8/8`. Generator provenance is
classified as compatible, source-authoritative fallback, or quarantine; a
candidate codec must also preserve its canonical hash. The remaining P0B gate
is field-coverage and rollback-contract review for personality, relationship
memory, journey provenance, opaque nested fields, and decision records. A
seed-only or definition-dependent record must remain source-authoritative or
quarantined; no default or reroll is permitted.

## Explicit P0A boundary

P0A created the matrix, this risk register, and a passing isolated baseline.
It did not change Hoomans generation/persistence, Core production behavior,
DT pricing/access, map behavior, or NPC lifecycle. P0B must resolve the schema
and appearance/voice/item-state conflicts above before a Core actor registry or
import writer is introduced. The P0B contract and evidence are recorded in
`P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md`.
