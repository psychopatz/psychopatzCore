# Portable Social State

**Status:** PLANNED — multi-repository developer implementation not started.
**Primary repository:** PsychopatzCore.
**Participant repositories:** ProjectHoomans and DynamicTrading (DTCommon, DTAbstract, optional DTHoomans integration).
**Optional dependency evidence:** MarketSense may be read/tested for economic integration but is not an edit target unless an actual defect requires it.

## Parent objective

Evolve the existing Core PsychopatzSocial actor social authority and the shared CodeBuilder toolchain into one compact, portable, server-authoritative social-state foundation that can be reused by Project Hoomans, DynamicTrading/DTAbstract and future projects.

The system must preserve meaningful directed relationships and bounded social memory with configurable retention, consolidation, provenance, knowledge/evidence integration and multiplayer authority while remaining independent of Project Hoomans physical NPCs and independent of any LLM.

## Why Core owns this

Current repository evidence already establishes:

- PsychopatzCore owns reusable mechanisms and portable contracts;
- Core actor state already contains personality, sparse directional relationships and bounded relationship memories in Actors/PsychopatzSocial.lua;
- Core already supplies stable actor identity/provider continuity used by DTAbstract and materialized adopters;
- DynamicTrading already consumes Core relationship state in DTCommon_CoreActorPolicy.lua for relationship-aware pricing;
- existing portable NPC/conversation architecture already declares shared personality, directional relationship and limited event memory as Core-owned.

This goal therefore evolves the existing Core social authority. It does not create a Project-Hoomans-only social engine and does not create SocialV2.

## Adopter outcomes

### Project Hoomans

Project Hoomans contributes rich game-specific social events, conduct, faction, knowledge, witness context, personality policy and physical NPC integration. Generic state that is useful to other adopters must flow through Core rather than remaining a Hoomans-only duplicate.

### DynamicTrading / DTAbstract

A trader uses the same Core actor identity and social state whether abstract, remotely contacted or physically materialized.

Trade-domain events may affect:

- familiarity;
- approval/respect or future Core generic dimensions;
- bounded memories such as reliable trade, unfair treatment, debt/default, gift/help, betrayal/scam where supported;
- conversation/evidence context;
- trader-specific commercial extensions.

DTCommon retains exclusive ownership of stock, budget, quotes, trade commit, credit policy, commercial eligibility and pricing rules. MarketSense retains economic valuation/classification authority.

DTAbstract must be able to benefit from social memory and relationship state with Project Hoomans absent.

### Future projects

A future adopter should provide:

- Core actor/provider mapping;
- authoritative domain event adapters;
- optional CodeBuilder-owned social policy package;
- read-only social projections;
- domain action/effect authority.

It must not copy the Core social implementation.

## Compiler/CodeBuilder portability rule

Use the existing CodeBuilder framework as the shared compiler/generation service.

Portable social policy must be authored as canonical, validation-friendly data and lowered to a generic Social Policy IR/runtime plan. Do not embed Project Zomboid APIs, PNC names, trader implementation calls or raw ModData paths in canonical portable policy.

The same CodeBuilder framework may later host other portable IR domains such as opportunity/event-director policy and advertisements/affordances. This does not require forcing non-conversation semantics into ConvoEngine; one compiler/toolchain may own multiple typed IR domains.

## Completion boundary

The full multi-repository roadmap in ROADMAP.md is the parent completion boundary. A Core-only implementation is incomplete until both Project Hoomans and DynamicTrading/DTAbstract prove adoption through the public Core seams.

## Read order

1. each participant repository root AGENTS.md;
2. this README;
3. ARCHITECTURE.md;
4. AGENT_RUNBOOK.md;
5. ROADMAP.md;
6. participant adopter docs;
7. HARNESS_ACCEPTANCE.md;
8. PROGRESS.md;
9. HANDOFF.md for the current session baton.
