# Roadmap — Portable Social State

**Parent status:** IN PROGRESS (P0–P7 accepted; advancing to P8).
**Primary repository:** PsychopatzCore.
**Participants:** ProjectHoomans, DynamicTrading (DTCommon, DTAbstract, optional DTHoomans).
**Completion boundary:** P0-P9 developer-side acceptance across all required repositories.
**Native SP/MP acceptance:** user-owned after developer-side completion.

## P0 — Cross-repo baseline and authority audit

Audit exact current Core/Hoomans/DT social state, actor identity, event identity, persistence, networking and CodeBuilder ownership.

Mandatory evidence includes:

- Core PsychopatzSocial schema, limits, revisions, extensions, memory/event behavior;
- Hoomans RelationshipService/SocialEvent/ConversationMemory/Conduct/Knowledge overlap;
- DynamicTrading actorID/traderID continuity and existing relationship-aware pricing;
- DTAbstract provider continuity without Hoomans;
- current CodeBuilder package routing/IR extension seams;
- representative serialized footprint and query cost;
- current dirty-work ownership so unrelated work is preserved.

**Gate:** one written ownership map classifies each current field/path as Core-generic, Hoomans-specific, DT-specific, projection/cache, duplicate-to-migrate, or legacy-to-remove.

## P1 — Portable contract and migration design

Freeze public contracts for:

- actor refs/player identity;
- directed relationship;
- retention/provenance;
- authorized social event;
- candidate-oriented query projection;
- revision/versioning;
- adopter extension namespace;
- migration/caller-zero policy.

**Gate:** contracts allow Core-only fixture, Hoomans adopter and DTAbstract trader adopter without importing one another.

## P2 — Core bounded retention and consolidation

Evolve PsychopatzSocial in place.

Add typed retention, salience, lazy expiry/strength and consolidation while preserving sparse storage and server authority.

No second Core social service.

**Gate:** repeated-event stress is bounded; high-salience retention behaves deterministically; zero per-tick aging.

## P3 — CodeBuilder Social Policy IR

Extend the existing CodeBuilder framework with portable social policy authoring/IR/runtime plans.

The exact schema name is chosen after P0/P1 evidence; do not force social policy into ConvoEngine if it is a separate semantic domain.

Requirements:

- owner/package routing;
- adopter-neutral canonical source;
- registered typed effect/predicate references;
- bounds/fan-out validation;
- deterministic generation;
- source maps/debug symbols;
- affected semantic fixtures;
- no PZ/PNC/DT implementation calls in portable IR.

**Gate:** one Core fixture package plus adopter packages compile deterministically through one toolchain.

## P4 — Project Hoomans authority reconciliation

Reconcile Hoomans generic relationship/memory overlap with Core.

Keep Hoomans-specific gameplay truth behind adapters; migrate generic shared state/writers to Core where appropriate. Preserve Unified Semantic Evidence and Social Conversation Director contracts.

**Gate:** no duplicate writable generic relationship history; Hoomans NPC social behavior and semantic evidence regressions pass.

## P5 — DynamicTrading / DTAbstract trader adoption

Add canonical trade-domain social event policy and thin DT adapters.

Representative event families should include several of:

- fair/reliable trade;
- repeated trading familiarity;
- gift/help;
- unfair treatment/price grievance where game semantics support it;
- debt fulfilled/defaulted if current product owns debt;
- scam/betrayal only if authoritative gameplay events exist.

Use Core social state for relationship/history while DTCommon retains commercial authority.

**Gate:** Core + DTCommon + DTAbstract works with Project Hoomans absent; abstract trader memory survives remote interactions and representation changes.

## P6 — Trader immersion and conversation integration

Feed bounded Core social projections into:

- existing DT relationship pricing context;
- trader dialogue/ConvoEngine package;
- negotiation/credit/willingness inputs where existing DT policy supports them;
- gossip/knowledge/evidence only through authoritative contracts.

Do not make social state directly set market price or stock.

**Gate:** two traders with different history/personality can respond differently to the same commercial situation without LLM use and without changing economic authority.

## P7 — Multiplayer authority and representation continuity

Prove:

- server-only social mutation;
- replay/idempotency behavior;
- stable player identity across reconnect;
- DTAbstract remote interaction uses same Core actor/social state;
- materialization/dematerialization preserves actor/social revision;
- clients receive bounded projections only;
- Hoomans/DT cross-mod cases do not double-apply events.

**Gate:** protocol/harness tests cover Core-only, Hoomans, DTAbstract and combined installation matrices.

## P8 — Future-autonomy consumer seam

Add a synthetic read-only consumer representing a future advertisement/autonomy resolver.

It must query bounded social features for candidates such as TALK, TRADE, HELP, AVOID or CONFRONT without raw-store access.

**Gate:** portable social state changes candidate features but never selects or executes the action; no LLM required.

## P9 — Scale, cleanup and final developer acceptance

Stress:

- hundreds/thousands of actors with sparse contacts;
- many abstract traders;
- repeated same-pair events;
- high-observer events;
- gossip/provenance;
- long world time;
- server reload/reconnect;
- representation changes;
- mixed Hoomans/DT install.

Final requirements:

- no duplicate generic relationship authority;
- no unbounded event ledger;
- no NxN state;
- bounded memory/consolidation;
- deterministic CodeBuilder output;
- Core-only portability fixture;
- DTAbstract without Hoomans fixture;
- Hoomans adopter fixture;
- combined adopter fixture;
- relevant full tests/static/Kahlua/harness gates pass;
- source saves untouched;
- no Workshop publish/native-game automation.

Only then mark READY FOR USER LIVE TEST.

## Stop rules

A phase is an execution boundary, not the parent completion boundary. After each accepted phase, reconcile docs, make safe participant commits, commit the primary Core handoff last, then continue automatically.

Do not push.

Do not rewrite/discard unrelated dirty work.

Do not solve an adopter problem by hard-coding the adopter into Core.
