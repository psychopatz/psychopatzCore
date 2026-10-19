# Core NPC Foundation — Copyable Codex /goal

~~~text
/goal
Repository scope: psychopatzCore (canonical goal owner), ProjectHoomans (legacy generator/persistence + future physical adapter), DynamicTrading (DTCommon economy + DTAbstract/DTHoomans adapters).

Current audited remote heads: Core main 50022acf; Hoomans main bc9c64d0; DynamicTrading main d6fccc3d. Hoomans NPC-foundation evidence exists on a divergent committed history through 9f153c0e. Inspect actual LOCAL branches/status/upstreams before writes; preserve unrelated work and reconcile safely. Never force-push/reset just to align histories.

Read in Core Docs/npc_foundation:
AGENT_RUNBOOK.md -> ARCHITECTURE.md -> ROADMAP.md -> PROGRESS.md -> P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md -> PHASE_0_EXTRACTION_AUDIT.md -> PLAN.md.
Also read ProjectHoomans/AGENTS.md before Hoomans source edits.

Current phase: P0B. P0A is accepted from source-backed evidence. P1 is NOT started.
Accepted foundation includes: field ownership/risk audit; source-backed parity baseline; read-only PNC.Persistence.ImportPlan; fail-closed source preservation; metadata-schema-2 legacyTemplateKey preservation; relationship/journey continuity checks; seed-only generator policy-provenance gating. These are source/harness facts, not live-game acceptance.

Start with ONE Next Chunk only: repair the NORMAL ProjectHoomans serializer/deserializer path for shared appearance + voice continuity. Do not begin the Core production registry yet.

Required implementation:
1. Write normal Types.NewRecord -> SerializeRecord -> DeserializeRecord regressions with NO import-planner sourceSnapshot.
2. Persist/restore complete available survivor voice values: voice, voicePrefix, voiceType, voicePitch under an explicit versioned contract. Old/incomplete input must remain incomplete/source-preserved; never invent values or rerun SurvivorFactory.
3. Persist/restore authored appearance policy schema 2 exactly when it exists, including outfit/slots/wornSlot/itemState.
4. Explicitly distinguish "no authored policy; generated/default appearance is valid" from "authored policy existed and was lost." Default/generated NPCs must not be rejected merely because record.appearance is absent.
5. Preserve the minimum generator/policy provenance needed to prevent incompatible seed-only rerolls.
6. Keep current metadata-schema-2 item parity, relationships and journey tests green.

Next Chunk acceptance: supported current-version generated/default and authored-appearance NPCs both survive ordinary SerializeRecord -> DeserializeRecord without sourceSnapshot; authored appearance and all available voice fields remain identical; generated/default case remains valid; older unsupported/incomplete data fails closed or stays source-authoritative; no in-place save migration, Core writer, DT behavior, Workshop publication or live-game claim.

Important evidence warning: tests/support CandidateCodec() is an in-memory echo/copy helper. It is useful for planner hashing but MUST NOT be cited as real PsychopatzCore persistence acceptance. P1 later requires a real Core Create -> Save -> Reload -> Get codec/registry.

Hard ownership invariants: Core ultimately owns canonical actor identity/factory/resolved appearance/PERSONAL inventory/social/journey/generic map+interaction; DTCommon alone owns MERCHANT stock/budget/pricing/access/restock; Hoomans owns physical body/combat/needs/jobs/factions/colonies. Never merge merchant stock with personal inventory. One actor ID, one journey authority, one personal-item ledger, one body lease. Radio communication is not automatic remote item transfer. Existing DT MVP T6 manual SP/MP gate stays OPEN.

Validation: use real PZ Lua modules and focused source-backed harness tests; run Kahlua/pz_verify and relevant identity/inventory/social regressions. The unrelated ISUI/ISPanel non-game harness failure is not this chunk; document it, do not inflate full-suite success. USER owns final normal-game SP/MP testing.

Git/publication: preserve user work; fetch + fast-forward-safe checks only; no ambiguous pull, destructive reset, rebase across uncertain work or force push. Commit coherent code+tests+docs to authorized GitHub only. NEVER publish/re-publish Steam Workshop or touch workshop publication fields.

After this chunk passes: update durable P0B evidence and choose one bounded follow-up only—either close a remaining migration-compatibility gate or, if P0B exit is fully supported, open P1 with a real Core-only Create -> Save -> Reload -> Get identity/appearance slice.
Report exact files, test commands/results, commit SHAs, unverified/manual gates, and the ONE next chunk.
~~~
