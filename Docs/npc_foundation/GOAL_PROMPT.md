# Core NPC Foundation — Copyable Codex /goal

```text
/goal

Repository scope: psychopatzCore (canonical owner), ProjectHoomans (legacy
generator/persistence and future physical adapter), DynamicTrading (DTCommon
economy plus DTAbstract/DTHoomans adapters).

Read in Core Docs/npc_foundation in order:
AGENT_RUNBOOK.md -> ARCHITECTURE.md -> ROADMAP.md -> PROGRESS.md ->
P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md ->
PHASE_0_EXTRACTION_AUDIT.md -> PLAN.md.
Read ProjectHoomans/AGENTS.md before Hoomans edits. Inspect actual local
branches/status/upstreams before writes; preserve unrelated work; no ambiguous
pull, reset, rebase across uncertain work, force-push, or Workshop publication.

P0B is accepted from source/harness evidence at Hoomans f7bfd6b6. Its normal
serializer/deserializer contract preserves the version-1 complete-or-incomplete
voiceProfile, authored appearance policy schema 2, generated/default-vs-authored
appearanceContract, and generator/policy provenance. CandidateCodec remains an
in-memory planner helper, not Core persistence. No live-game SP/MP acceptance is
claimed; the unrelated ISUI/ISPanel non-game harness failure remains documented.

Start with ONE Next Chunk only: implement the smallest real Core-only
identity/appearance Create -> Save -> Reload -> Get codec/registry slice.
Prove stable actor identity, resolved appearance/voice, generated/default versus
authored state, duplicate-ID rejection, and no dependency on PNC or DT. Do not
begin portable inventory, social, journey, map, DT behavior, Hoomans body
projection, provider switching, save migration, or Workshop work.

Hard ownership invariants: Core owns canonical actor identity/factory/resolved
appearance/personal inventory/social/journey/generic map+interaction; DTCommon
alone owns merchant stock/budget/pricing/access/restock; Hoomans owns physical
body/combat/needs/jobs/factions/colonies. Never merge merchant stock with
personal inventory; one actor ID, journey authority, personal-item ledger, and
body lease. Radio communication is not automatic remote item transfer. Existing
DT MVP T6 manual SP/MP gate stays OPEN. USER owns normal-game SP/MP testing.

Validation: use real Core Lua modules and a focused source-backed harness;
verify Kahlua/pz_verify and the relevant identity/appearance regressions. Do not
cite CandidateCodec as acceptance. Commit coherent Core code/tests/docs to the
authorized GitHub destination only; never publish Steam Workshop.

Report exact files, commands/results, commit SHAs, unverified/manual gates, and
the ONE next chunk.
```
