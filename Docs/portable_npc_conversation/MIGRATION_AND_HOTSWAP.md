# Portable Persona, Knowledge and Provider Hot-Swap — Migration Safety

## Mandatory no-loss migration

Existing Core actor identity registry and provider leases are the canonical destination. Existing Hoomans `PNC.Conversation.Memory` has seed-derived, stable pinned background selections and `PNC.NPCKnowledge` persists player-character-specific Knowledge. These are actual owners today; adoption must be staged, not a destructive rename or shadow duplicate.

1. Audit actual field/key/format version and authority in Core actor Factory/Persistence/Social, Hoomans Memory/Knowledge and DTCommon actor-binding. Produce ownership + migration mapping and fixtures of old saves BEFORE changing writers.
2. Introduce versioned Core personal-fact, backstory and Knowledge contracts, with stable-ID registration and source provenance. Implement **idempotent** read/upgrade/write adapters that do not overwrite original Hoomans data before equality, journal or retry-safe parity is established.
3. Detect absent, malformed, future-version, conflicting, already-migrated, deleted/unknown fact and duplicate actor ID cases. Fail closed/quarantine instead of generating a different persona or losing confirmed player evidence. Maintain generator selections across catalog additions and changes.
4. Add alias/reference mapping from Hoomans NPC ID and DT traderID to canonical actorID; never treat bare displayed names as actor keys. Explicitly preserve Hoomans NPC-only extension fields and DT merchant ledgers through mod disable/enable.
5. Verify exactly one authoritative writer per migrated field under each adapter combination. Preserve unknown namespace extensions during Core Save→Load; no copy of merchant stock, currency, quotes, or unsettled transactions into Core actor personal inventory.

## Supported hot-swap

**In-process provider transitions** are supported only when both relevant adapters are already loaded and Core controls their provider leases. Enabling/disabling installed mods at runtime is NOT assumed supported by PZ: validate changes to installed mod configuration over **save/restart/load** separately. Never promise hot-loading unavailable Lua modules.

State transitions for the same actor:
```text
Core actor A (one seed, identity, social, facts, player Knowledge)
    ├─ DTAbstract: abstract/provider lease + RADIO channel
    └─ DTHoomans: materialized/provider lease + NEARBY channel
```

Before transition: server validation and transaction barrier, drain/cancel active operations correctly, snapshot bounded pending dialogue by actor+character, persist dirty Core+DT ledgers idempotently, check lease revision/expected body ID. Then release/dematerialize in owning lifecycle, hand off through Core Provider.Switch/Acquire, materialize/projection to new provider, resume only compatible pending topics. On failure retry/rollback without double body or effects. Session/channel authorization MUST be rechecked after switching (old RADIO proof cannot authorize NEARBY trade/commands).

Do not associate portable NPC existence with a loaded Java `IsoPlayer` or `IsoZombie`; Core must function with no spawned Hoomans body. No permanent duplicate Hoomans actor history or player Knowledge after switch. Protected player Knowledge is not broadcast in generic Core actor projections.

## Save and integration acceptance

Matrix: Core alone; Core + DTCommon + DTAbstract and Hoomans absent; Core + Hoomans; Core + DTCommon + Hoomans + DTHoomans; combined DTAbstract/DTHoomans providers; save/restart with Hoomans added/removed; repeated switch A→B→A; interrupted/failed body creation; MP two players+reconnect; stale and unauthorized request. Assert exact actorID, pinned backstory, personal inventory, relationships, player-specific evidence, pending conversational context/commitments and merchant stock/budget/quotes stay consistent. No duplicate body, double action, content reroll, trade authority bypass or uncaught unknown version. Native PZ SP/MP user-owned; reproduce all safe seams in the real Lua/harness first.
