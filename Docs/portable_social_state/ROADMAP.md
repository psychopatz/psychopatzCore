# Roadmap — Portable Social State

**Parent status:** ACTIVE — post-P9 architecture cleanup required before user live acceptance.
**Primary repository:** PsychopatzCore.
**Participants:** ProjectHoomans, DynamicTrading (DTCommon, DTAbstract, optional DTHoomans).
**Completion boundary:** P0-P12 developer-side acceptance across all required repositories.
**Historical checkpoint:** P0-P9 remain accepted implementation milestones, but the prior final-acceptance claim is superseded by the 2026-11-19 independent audit recorded in AUDIT.md.
**Native SP/MP acceptance:** user-owned only after P12 developer-side completion.

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

P9 was accepted under the original roadmap, but the post-P9 independent audit supersedes that readiness conclusion. Continue through P10-P12.

## P10 — Single persisted generic social authority — ACCEPTED (ProjectHoomans H7)

The post-P9 audit proved that Project Hoomans still serializes generic relationship fields and memories through RelationshipRepository.SerializeRecord(record) while PsychopatzCore independently serializes actor.social.

Runtime convergence is working, but duplicate persistence violates the intended authority and footprint boundary.

Required work:

- make Core actor.social the only persisted generic directed relationship and memory authority for Core-backed actors;
- keep Hoomans-owned morale, conduct, bond or romance, interaction journal and other genuinely PNC-specific state in an explicit Hoomans extension persistence envelope;
- let Hoomans construct an ephemeral runtime convenience view from Core generic social state plus its own extension without persisting the generic projection again;
- replace generic PNC dual-write persistence with direct Core-authoritative mutation or a bounded adapter that writes Core once and refreshes the Hoomans runtime view;
- provide an explicit versioned migration for supported pre-P10 saves that imports legacy PNC generic social state into Core once, then writes only the new authority shape;
- do not keep a permanent compatibility shim;
- prove caller-zero before removing superseded generic persistence and writer paths;
- measure combined Core plus Hoomans serialized footprint so the test catches duplicate storage rather than testing Core alone.

**Gate:** one Core-backed Hoomans NPC serializes generic approval, respect, familiarity, baselines, memories and revisions exactly once in Core; save and reload plus DTAbstract and DTHoomans representation changes preserve that history; Hoomans-specific extensions survive independently; Hoomans social, semantic and conduct regressions remain green.

## P11 — Action-neutral social decision-feature boundary — ACCEPTED

The P8 implementation correctly remained read-only, but PsychopatzSocialProjections.EvaluateAutonomyCandidates currently contains action-specific scoring formulas and recognizes TALK, TRADE, HELP, AVOID, CONFRONT, REPORT and RETALIATE.

That is too much policy for Portable Social State.

Required work:

- keep QueryCandidateProjection and add or normalize a bounded action-agnostic social decision-feature projection;
- expose social facts and features such as trust, grievance pressure, assistance history, familiarity, caution-relevant evidence, provenance confidence, direct or witnessed or hearsay counts, relationship and social revisions, and personality inputs;
- remove concrete action vocabulary and action-specific utility formulas from the Core Actors social subsystem after caller-zero proof;
- put action-specific weighting in the future Autonomy Resolver or advertisement consumer, or in a synthetic external test consumer for this job;
- preserve deterministic, non-mutating, no-LLM behavior and revision-based revalidation.

**Gate:** no production Portable Social State module under Core Actors owns TALK, TRADE, HELP, AVOID, CONFRONT, REPORT or RETALIATE scoring policy, while an external synthetic consumer can still rank those candidates entirely from bounded public social features without raw-store access.

## P12 — Native identity safety and final cross-repository persistence proof — ACCEPTED

Close the remaining native-safety and final-acceptance gap.

Required work:

- remove sandboxed os.* dependence from PsychopatzPlayerIdentity.lua;
- use an existing or newly factored Project Zomboid-safe server-authoritative issuance mechanism for persistent character identity, with collision, reconnect, save-reload and cross-account tests;
- rerun Core-only, Core plus Hoomans, Core plus DTCommon plus DTAbstract with PNC disabled, and combined DTAbstract to DTHoomans to DTAbstract matrices after P10 and P11;
- add a combined persistence test that proves generic social state is not duplicated across Core and Hoomans save payloads;
- rerun scale, consolidation, long-time lazy decay and RuntimeStore chunking;
- rerun CodeBuilder Social Policy determinism and reconcile;
- rerun relevant full Core, Hoomans and DynamicTrading suites and Kahlua or static checks on all touched production files;
- preserve the four already-known unrelated Hoomans baseline failures unless their owner changes independently.

**Gate:** all mandatory developer checks pass, portable social data has one persistent generic authority, social decision output is action-agnostic, native player identity contains no sandboxed os.* dependency, and all required adopter and install matrices remain green.

Only after P12 may the parent return to READY FOR USER LIVE TEST.

## Stop rules

A phase is an execution boundary, not the parent completion boundary. After each accepted phase, reconcile docs, make safe participant commits, commit the primary Core handoff last, then continue automatically.

Do not push.

Do not rewrite/discard unrelated dirty work.

Do not solve an adopter problem by hard-coding the adopter into Core.
