[{"Phase":"**C1 — actual worker conversation audit and correction baseline**","Status":"**COMPLETE**","Required_result":"Reusable Core-backed compound speech-act, pending-question binding, causal-reference uncertainty and EN/TL regression verified in the real Hoomans Lua worker."},{"Phase":"**C2 — Core portable persona and Knowledge authority**","Status":"**COMPLETE**","Required_result":"Versioned Core seed/backstory/Knowledge contracts, idempotent Hoomans migration, two-player privacy/dossier and Core-only independent save/reload."},{"Phase":"**C3 — shared offline conversational competence**","Status":"**COMPLETE**","Required_result":"Core dialogue service over the existing parser/router/state; compound turns, pending acts, contextual resolution, uncertainty and localized response keys; Hoomans production boundary uses the same service."},{"Phase":"**C4 — Hoomans/DynamicTrading integration**","Status":"**COMPLETE**","Required_result":"Hoomans contextual providers plus authenticated DTAbstract/DTHoomans Talk share Core actor/conversation authority; trade, quest and transaction ownership remains with existing owners."},{"Phase":"**C5 — safe provider hot-swap and persistence**","Status":"**COMPLETE**","Required_result":"Actor/body/provider lease/trader identity invariant, bounded continuity, restart/save continuity and no duplicate effects, stale authorization or privacy leak."},{"Phase":"**C6 — full Semantic Lab acceptance and handoff**","Status":"**COMPLETE**","Required_result":"Actual GUI/real Lua worker Core-only/Hoomans/DTAbstract/DTHoomans/combined matrix, EN/TL, per-player privacy, bounded footprint and full regressions; READY FOR USER LIVE TEST after all developer-owned gates pass."}]

**Updated:** 2026-10-21. **C1–C6 developer-owned acceptance complete. READY FOR USER LIVE TEST. Native Project Zomboid SP/MP/live-server and Workshop actions remain user-owned.**

**PARENT:** **COMPLETE FOR DEVELOPER-OWNED WORK; READY FOR USER LIVE TEST.** C1–C6 acceptance is complete. Native Project Zomboid SP/MP/live-server and Workshop actions remain user-owned.

## C1 acceptance evidence

- Core commit `5ef6690`: bounded `PsychopatzCore.Semantics.DialogueTurn` built on the existing candidate parser, plus a direct Core smoke test.
- Hoomans commit `86852303`: compound submission, reciprocal wellbeing and causal context-reference semantics, greeting answer binding, truthful uncertainty, EN/TL keys, and real-worker regression coverage.
- Verified commands and exits: doctor `0`; Core turn smoke `0`; Core pattern smoke `0`; Hoomans Python C1/identity regression `12 tests, 0`; focused Lua `3/3, 0`; `pz_verify` SemanticCatalog Kahlua `0 errors, exit 0`.
- Real displayed EN dialogue: residence — “I don't have a confirmed home to tell you about.”; causal follow-up — “I don't know why that is; I only know what I can confirm.”; greeting — “Hello. Good to see you.” followed by “How have you been?”; compound response — “Doing okay, all things considered.” TL compound translation resolved with no fallback.
- Graph limitation: runtime media trees are excluded or not tracked by the graph index; changed runtime source was therefore read and verified directly.

## C2-A acceptance evidence — portable Core actor state

- Core commit `223808f`: versioned `PsychopatzActorPersona` backstory selection metadata and bounded `PsychopatzActorKnowledge` with confirmed/known/suspected states, sparse values, evidence, server authority, per-player isolation, registry commits, provider projections and legacy-compatible persistence.
- Hoomans commit `41a49775`: stable Hoomans backstory selections flow through the existing Core migration candidate; `PNC.Persistence.CoreKnowledge` projects the existing server-authoritative per-character dossier facts and evidence into the Core contract without writing a duplicate Hoomans store.
- Core commands and exits: `lua5.3 tests/psychopatz_actor_persona_knowledge_smoke.lua` `0`; `lua5.3 tests/psychopatz_npc_actor_smoke.lua` `0`; `lua5.3 tests/psychopatz_npc_social_smoke.lua` `0`; `lua5.3 tests/psychopatz_npc_acceptance_matrix_smoke.lua` `0`; `pz_verify.py --dir .../Actors --kahlua --severity ERROR --no-snippets` `0` errors; `luac5.3 -p` changed Core files `0`.
- Hoomans commands and exits: `python3 tests/run_tests.py pnc_npc_foundation_core_knowledge_adapter_smoke pnc_npc_foundation_core_migration_smoke pnc_npc_foundation_import_plan_smoke pnc_backstory_persistence_stability_smoke --verbose` `4/4`; migration assertion rerun `1/1`; `pz_verify.py --dir .../PNC/Core/Persistence --kahlua --severity ERROR --no-snippets` `0` errors; `luac5.3 -p` changed Hoomans files `0`.
- Evidence includes stable identity seed, authored/versioned backstory IDs, no biography paragraph, disclosure source/event/tags, confirmed versus suspected values, two player keys, save/reload and existing Hoomans backstory/import-plan compatibility. Hoomans ModData remains authoritative during this bridge; no automatic duplicate write is performed.

## C2-B acceptance evidence — authorized Knowledge handoff

- Hoomans commit `beb65430`: `PNC.Persistence.CoreKnowledge.CommitForPlayer` is an explicit server-only handoff from the existing player-scoped Hoomans dossier into a Core actor registry commit. Client authority is rejected; the imported player state is isolated and survives Core save/reload.
- Verified with the real Hoomans test harness: `python3 tests/run_tests.py pnc_npc_foundation_core_knowledge_adapter_smoke pnc_npc_foundation_core_provider_smoke pnc_npc_foundation_core_migration_smoke --verbose` — `3/3`; Persistence Kahlua scan — `0 errors`; Lua parse — exit `0`.

## C2-C next bounded chunk — measurable deliverables

1. Bind the Core actor projection to the existing Hoomans runtime/body and Dossier paths so abstract and physical providers read one actor identity without replacing Hoomans body/quest behavior.
2. Exercise Core actor/provider leases, identity seed, appearance, personal inventory, social state, persona, per-player Knowledge and save/reload through the existing Hoomans persistence coordinator.
3. Commit the bounded runtime adapter/tests and record exact evidence before starting C3.

## C3-A acceptance evidence — shared offline actor service

- Core commit `f1e92b0`: `PsychopatzCore.Conversation.ActorService` is an orchestration boundary over the existing `DialogueRouter`, `DialogueState`, candidate parser and bounded `DialogueTurn`; it owns no grammar, compiler, translation catalog, LLM client or gameplay store.
- The service processes compound turns as multiple speech acts, retains pending questions/requests and bounded topic/event state, supplies actor identity/personality/relationship context to the existing policy, exposes server-gated Knowledge reads, registers server-gated mod capabilities, and delegates EN/TL localization/response planning to the caller.
- Verified: `lua5.3 tests/psychopatz_actor_conversation_service_smoke.lua` `0`; semantic turn and pattern smoke `0`; social and actor acceptance smoke `0`; Core Conversation Kahlua scan `0 errors`; changed-file Lua parse `0`.

## C2 acceptance evidence — migration, provider and dossier continuity

- Hoomans commit `46c80d9c`: existing CoreProvider projections carry Core persona/Knowledge through Hoomans body lifecycle, and `CoreKnowledge.BuildDossierSnapshot` renders already-authorized Core facts into the existing dossier shape without becoming a second ModData writer.
- Together with Core `223808f`, Hoomans `41a49775` and Hoomans `beb65430`, this preserves stable seed/appearance/inventory/social/provider lease, versioned backstory selections, confirmed/suspected evidence, per-player isolation and save/reload compatibility. Focused migration/provider/dossier tests pass; no native PZ or Workshop action is claimed.

## C3-B acceptance evidence — Hoomans shared-service boundary

- Core commit `ba7285b`: `ActorService.New` accepts an existing production router and exposes `ParseTurn`, `Preview`, `ProcessIR`, `Process`, and bounded `ObserveResult` wrappers. The standalone Core-only constructor and `Submit` path remain intact.
- Hoomans commit `9d670469`: `PNC_SemanticActorConversationService` projects existing Hoomans actor identity/persona/social/Knowledge references into one runtime Core service per session. `RouterLifecycle` attaches it to the existing router; `SubmitSingle` routes compound parsing, preview and IR processing through the service while Hoomans retains cognition, fallback, response, action/effect, translation and UI ownership. Session close clears the service with the router.
- Verified: Core `lua5.3 tests/psychopatz_actor_conversation_service_smoke.lua` exit `0`; Hoomans adapter Lua smoke and existing input smokes `3/3`; real worker shared-service plus C1/live-parity regressions `9 tests, 0`; changed Lua parse and Core/Hoomans Kahlua scans `0 errors`. Actual worker service snapshots showed actor `mara`, conversation `harness-conversation`, bounded turn state, no LLM calls and no transport/tool effects.

## C4 acceptance evidence — DynamicTrading Talk adapters

- Core commit `1b69628` makes the existing Radio OS contact-detail action selector cycle through all provider actions, so Talk is selectable while the existing trade action remains the default.
- DynamicTrading commit `2f313649` adds `DTCommon.TalkService`, with server-authorized actor/session binding, request deduplication, bounded payloads and player isolation. `DTAbstract` advertises authenticated radio Talk; `DTHoomans` advertises authenticated nearby physical Talk. Neither path grants remote trading, item teleportation, inventory access or companion actions; stock, budgets, prices, quote validation and transactions remain in their existing DT owners.
- Verified: `python3 tests/run_tests.py` in DynamicTrading — `18/18`; focused Talk/provider run — `5/5`; changed DynamicTrading Lua parse — exit `0`; targeted DynamicTrading Kahlua scans — `0 errors`; Core `lua5.3 tests/radio_os/psychopatz_radio_os_window_smoke.lua` — exit `0`. The adapter requires only Core and DTCommon; ProjectHoomans and an LLM are optional.

## C5 acceptance evidence — provider hot-swap and persistence

- Core commit `ddcccba` adds expected-revision guards to every provider lease mutation, explicit authorized cross-owner handoff support, bounded semantic-state restoration and event-history restoration. Core restore and provider lease smokes pass.
- Hoomans commit `03aadf64` refuses duplicate materialization before invoking the live-body factory. The existing Core projection remains the only identity/persona/social/Knowledge/inventory source; the body lifecycle remains Hoomans-owned.
- DynamicTrading commit `938721fa` rejects actor rebinding, stale or malformed provider projections, stale Talk sessions after a provider revision change, and failed physical projections that would otherwise strand a materialized lease. The new `dt_provider_hotswap_persistence_smoke` verifies DTAbstract → DTHoomans → DTAbstract with one actor/trader identity, stable lease ID, body cleanup, stock/budget preservation, two-player Knowledge isolation, bounded pending dialogue restore and JSON save/reload.
- Verified: Core restore/provider/acceptance smokes exit `0`; Hoomans provider/persistence-focused harness `6/6`; DynamicTrading hotswap smoke and full regression `19/19`; changed Lua parse and targeted Kahlua scans `0 errors`. No native PZ SP/MP or runtime mod unloading is claimed.

## C6 acceptance evidence — Semantic Lab and adopter matrix

- ProjectHoomans commit `d8d2011e` adds `test_portable_c6_matrix`: the real Lua worker visibly returned EN residence uncertainty, causal uncertainty, greeting and reciprocal wellbeing responses; TL greeting and reciprocal wellbeing translations resolved without fallback; Conversation Inspector records came from `real_lua_worker`; restart retained the same actor conversation identity; Core-only and DynamicTrading production Lua acceptance ran in the same matrix.
- Existing Semantic Lab F4/C6 acceptance remains active: CodeBuilder previews/generation, generated EN/TL assets, production registry reload, Flow editor validation, Simulation, Inspector, two-player Knowledge isolation, bounded footprint and no-LLM/no-effect contextual acceptance are covered by the suite. The worker doctor reports Python/Tk/display/Lua/Core path and READY/PING/CAPABILITIES success.
- Verified commands: `python3 -m unittest discover -s tools/semantic_harness/tests -q` — `285 tests, 0, exit 0`; `python3 -m unittest tools.semantic_harness.tests.test_portable_c6_matrix -v` — `2/2, exit 0`; `python3 tests/run_tests.py` in DynamicTrading — `19/19, exit 0`; Core acceptance/provider/restore smokes — exit `0`; targeted changed-file Kahlua scans — `0 errors`.
- Visible GUI acceptance completed on 2026-10-21 through the signed-in X11 desktop using the existing Semantic Lab. The production Lua worker visibly displayed the EN residence/causal/greeting/reciprocal transcript and TL greeting/reciprocal transcript above; the Conversation Inspector visibly displayed QUESTION intents, `RESIDENCE` contextual reference resolution, and the greeting agenda transition. Studio visibly displayed the `semantic_definitions` dataset, reusable production block palette, EN/TL authored response fields and generated-source preview. The preview was non-writing and reported its expected incomplete-composition diagnostics; generated Lua/translation asset success remains covered by the 285-test Semantic Lab suite and C6 matrix. OCU doctor/list-apps confirmed the X11 session, and desktop capture/coordinate actions were used only to operate this existing GUI. This closes the prior visual-evidence limitation.

## Overall completion contract

All C1–C6 source + real worker matrix (Core-only, Hoomans, DTAbstract, DTHoomans, both), two-player privacy, server lease/hot-swap and save/reload, EN/TL, optional PBrainZ authorization, 0/1/10 and synthetic scaling tests must pass. Native Project Zomboid SP/MP/live game checks and Workshop publication remain solely user-owned. The executable `/goal` prompt is provided only in chat.
