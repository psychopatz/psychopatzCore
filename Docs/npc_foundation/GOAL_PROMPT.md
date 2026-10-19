# Core NPC Foundation — Continuous full-goal Codex /goal

```text
/goal
Repository scope: psychopatzCore (canonical shared NPC owner), ProjectHoomans (legacy source and physical adapter), DynamicTrading (DTCommon economy and abstract/Hoomans providers).

PARENT GOAL: IMPLEMENT AND VALIDATE THE ENTIRE APPROVED CORE NPC FOUNDATION ROADMAP P1–P9. This is NOT a P1-only assignment. P0A/P0B source-backed audits and persistence work have been recorded accepted; they do not finish the parent goal. Parent status remains IN PROGRESS until all mandatory developer-owned features/integrations/regressions across the THREE repos pass.

READ Core Docs/npc_foundation/AGENT_RUNBOOK.md, ARCHITECTURE.md, ROADMAP.md, P0B_CANONICAL_SCHEMA_AND_MIGRATION_CONTRACT.md, PHASE_0_EXTRACTION_AUDIT.md, PLAN.md, and PROGRESS.md LAST. Read ProjectHoomans/AGENTS.md before Hoomans edits. Verify actual local branch/upstreams/dirty worktrees and paired Core/DT versions. Preserve unrelated changes; no blind pull, force/reset/stash or Workshop publication.

CONTINUOUS EXECUTION: Work on ONE safely bounded implementation chunk at a time. For every phase, verify actual source state, implement production code, execute real Core/Hoomans/DT Lua harness and relevant regressions, measure where required, commit coherent changes, record verified evidence/remaining issues in PROGRESS, THEN IMMEDIATELY ADVANCE TO THE NEXT MANDATORY CHUNK WITHIN THIS SAME /goal. Do not pause or declare done because P1 passes, a commit was pushed, docs updated, or a small unit suite is green. If one safe phase is blocked, continue independent required work and record the blocker. No repeated requests for authorization already granted by repository policy.

START CURRENT CHUNK P1: implement actual Core-only actor Create -> Save -> Reload in a fresh registry -> Get identity/appearance/voice contract. Reject duplicate IDs; prove generated and authored visuals, version behavior, no PNC/DT dependency. Existing CandidateCodec is planning-only, not persistence acceptance. P0B's Hoomans serializer retains voiceProfile and authored appearance but is only one precursor.

AUTOMATIC NEXT CHUNKS: P2 real portable personal inventory with seed/delta/full fidelity; P3 safe idempotent source-preserving legacy migration; P4 shared directional social/relationships; P5 generic actor scheduler, anchors and journey; P6 map/portrait/interaction/notification integration; P7 DTCommon merchant policies and authorized fulfillment; P8 provider switching (DTAbstract/DTHoomans) and Hoomans physical/body lease; P9 cross-repository regression, backwards compatibility, multiplayer authority, resource limits and complete developer acceptance.

MANDATORY FINAL PRODUCT: A stable Core canonical actor usable without Hoomans, with unchanged identity/appearance/voice/personal-item/social/journey state across real codec save/reload and authorized provider switching; DT merchant budgets/stocks remain separate from NPC inventory, and Hoomans alone owns physical NPC body/needs/combat/colony. No duplicate actors, items, leases, actions, map hooks or economy owners. Check all repo/module compatibility matrices.

Do not launch native Project Zomboid SP/MP, host server, install or publish Workshop; those are user-owned. Do complete all headless real Lua, source-backed, Kahlua and supported UI tests before handoff. CUA apps=[] alone does not block work.

FINAL STATUS only (1) READY FOR USER LIVE TEST when EVERY developer-owned P1–P9 gate is satisfied with cited real-source/run evidence and no remaining mandatory implementation, or (2) BLOCKED with exact technical/authorization evidence and safe work exhausted. Never use COMPLETED for only one subphase. Continue autonomously rather than awaiting another /goal.
```
