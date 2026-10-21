# Roadmap — Grounded World Knowledge & Gossip

Parent status: IN PROGRESS / PLANNED. No implementation acceptance is implied by this planning commit.

A phase is a checkpoint, not completion of the parent goal. The agent must continue autonomously through all developer-owned phases after each accepted phase.

## W0 — authority/source audit and contract freeze

Audit current Core/Hoomans/DT source and actual PZ-facing adapters before adding state. Map authoritative producers, persistence owners, event hooks, existing zombie-density/debug data, conversation projection and DT actor provider seams. Specifically identify the exact authoritative APIs for helicopter, electricity, water and season; do not guess them from old documentation.

Gate: field/authority matrix with source paths and one no-duplication design; real before-state worker gossip trace captured; no production behavior changed unless required to instrument read-only diagnostics.

## W1 — Core WorldFact ledger and actor knowledge primitives

Implement versioned primitive-only fact schema, stable IDs, bounded ledger/index, retention/TTL, actor fact references, provenance/confidence, save/reload and diagnostics. Preserve existing Core actor/Knowledge contracts; do not turn this into a second player-scoped dossier system.

Gate: Core-only publish/query/learn/save/reload/dedupe/expiry/compaction tests; bounded footprint measured; no adopter vocabulary hard-coded into Core.

## W2 — Hoomans authoritative fact adapters

Connect existing Hoomans owners for a first grounded set: member killed/major faction incident, faction destruction/status transition, NPC death where source truth is available, and zombie pressure from existing WorldCensus/Spatial/Perception/horde caches.

Gate: authoritative source event produces exactly one appropriate fact; repeated zombie observations aggregate by band/episode; no extra global zombie scan; source owner remains canonical.

## W3 — Project Zomboid environment adapters

Audit and implement authoritative read/adaptation for helicopter state, power shutoff, water shutoff and season/current seasonal state. Prefer current state projection for derived state and transition facts only when useful.

Gate: testable adapter boundary with truthful unknown/unavailable behavior; no duplicate simulation timers/state; no fabricated event history.

## W4 — actor acquisition/dissemination

Implement experienced/witnessed/faction/public acquisition using existing identity/perception/faction boundaries. Keep exact actor/faction privacy and server authority. No NPC-to-NPC free propagation yet.

Gate: two actors can differ in knowledge of the same fact for a demonstrated reason; save/reload preserves bounded references; unknown actor cannot retrieve hidden fact.

## W5 — grounded gossip conversation projection

Replace scenario-only/manual npcGossip statements with a production grounded provider that ranks authorized known facts and projects a small bounded set into the existing semantic/Core conversation context. Preserve EN/TL and current GOSSIP routes. PBrainZ consumes the same authorized projection.

Gate: real Lua worker: Alice knows a fact and can mention it; Bob does not know it and cannot; no LLM path invents absent facts; provenance/selection trace visible.

## W6 — NPC-to-NPC and radio propagation

On real social/radio opportunities, transfer at most a small bounded number of shareable fact references with source/provenance/confidence, novelty and cooldowns. No global polling graph simulation.

Gate: A witnesses -> tells B -> B can later report as told; no duplicate growth; source chain/certainty visible; unrelated C remains unaware until a legitimate path exists.

## W7 — DynamicTrading adoption

Add DT-owned fact producers/consumers for appropriate trader/caravan/route/market observations through Core. DTAbstract and DTHoomans share the same actor fact knowledge across provider transitions. DTCommon commerce authority remains unchanged.

Gate: Core+DT without Hoomans works; Hoomans+DT same actor preserves knowledge across abstract/materialized transitions; talk about a market fact never bypasses quote/stock/transaction authorization.

## W8 — Semantic Lab World Knowledge inspector

Extend the existing Hoomans Semantic Lab/production Lua worker; do not build a separate app. Add editable fact/knowledge scenarios plus Fact Ledger, Actor Knowledge, Propagation Trace and Gossip Candidate/Ranking/Provenance inspection.

Gate: existing GUI + real worker visually demonstrate fact creation/projection, differing Alice/Bob knowledge, propagation and EN/TL final responses. JSON/schema-only tests cannot close this phase.

## W9 — performance, regression and handoff

Run focused and impacted Core/Hoomans/DT suites, Kahlua/Lua parsing, Semantic Lab doctor/real-worker matrix, persistence footprint and large synthetic actor/fact stress with bounded behavior. Review SP/MP authority and privacy.

Gate: all developer-verifiable requirements W0-W9 green; final status READY FOR USER LIVE TEST. Native Project Zomboid SP/MP/gameplay and Workshop actions are user-owned and remain UNTESTED unless the user performs them.

## Parent completion rule

Do not mark this goal complete after W0, W1, a passing schema test, or a single Hoomans gossip response. Parent completion requires the full grounded cross-mod path: authoritative event -> fact -> legitimate actor knowledge -> grounded conversation -> DT reuse -> offline/PBrainZ parity -> Semantic Lab evidence -> bounded persistence/performance.
