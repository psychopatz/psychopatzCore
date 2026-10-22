# Progress — Grounded World Knowledge & Gossip

Updated: 2026-10-22
Status: W0-W9 developer implementation/evidence complete; native PZ SP/MP remains reserved for user validation.

## Verified planning baseline

- PsychopatzCore main: 159df9e2f12cb4a3911f50d6c27dcc1d48a861fc.
- ProjectHoomans main audited at 2bcefd74d3c46df0f707467a7e9b8a6ba42cb185.
- DynamicTrading main audited at 938721fa538a13845684acb22a5468fe0a9dc9e5.
- Existing Core portable NPC conversation C1-C6 is developer-accepted and is a dependency, not work to redo.
- Hoomans WorldCensus/SpatialIndex/Perception infrastructure already owns bounded zombie queries/caches.
- Hoomans follower/combat code already detects zombie hordes and PNC_SocialEventHooks can store a compact experienced zombie_horde_encounter memory with coarse count band.
- Hoomans faction incident authority already recognizes member_killed/severe attack/rescue and faction state includes destroyed.
- Hoomans semantics already routes GOSSIP and can render bounded context.npcGossip.statements; optional PBrainZ already consumes that projection.
- DynamicTrading already shares one Core actor/Talk identity across DTAbstract and DTHoomans while DTCommon owns stock/budget/trade.

## Audited gap

There is no verified shared Core WorldFact ledger + actor world-knowledge reference layer connecting those owners. Current gossip can consume provided statements, but the audited code does not establish a complete source-of-truth pipeline that automatically converts faction/world/PZ events into portable actor-known facts.

The audit did not establish authoritative Hoomans adapters for helicopter, power, water and season comparable to the already-found zombie/faction paths. W0 must locate actual current PZ APIs/hooks before implementation; do not invent state owners.

## ONE current Next Chunk — W0 source/authority audit

Perform a current local source audit across all three existing main worktrees and freeze the contract before production mutation.

Required outputs:
- source/owner matrix for WorldCensus/Spatial/Perception zombie count and the exact lightweight debug/density path currently visible to the user;
- faction/member death/destruction and NPC death/cause producer paths;
- authoritative PZ helicopter/power/water/season API/hook paths;
- Core Actor/Knowledge/conversation provider seams and persistence boundaries;
- current npcGossip offline + PBrainZ projection/worker trace;
- DT trader actor/Talk/provider and commerce boundaries;
- proposed stable fact/reference fields classified as copied/derived/runtime/persisted;
- measured current ModData/save baseline relevant to the new bounded storage.

W0 acceptance is source evidence and a real worker before-state, not speculative implementation. After W0 is accepted, proceed immediately to W1 and onward without asking for another goal prompt.

## Stop conditions

Stop only for a genuine safety/authorization conflict, uncertain user/concurrent local edits that make a required write unsafe, or a proven unavailable required technical capability after independent work is exhausted. Native PZ absence is not a blocker for developer phases. Never publish/install to Steam Workshop.

## W0 source evidence (2026-10-22)

Actual worktree state was checked before edits. The planning SHAs are not the current heads: Core is clean at `b289a2e2e3f7a7881c2a94f56195e4202d54657e`, tracking `origin/main`; Hoomans is at local `9d9dc454c6b39c4b0a6c7e6bcb4008a1f3da4fe4`, seven commits ahead of `origin/main` `26cab0dc41864d73dc8db8b386b183c081a373e8`, with pre-existing staged and unstaged PNC edits; DT is at `938721fa538a13845684acb22a5468fe0a9dc9e5`, one commit behind its `origin/main` `bcba858a412e6b9fa16030c4fea5b82217f6d1e8`. No synchronization, branch, reset, stash, Workshop, or native-game action was performed.

The exact current lightweight zombie-density/debug path is the Hoomans nameplate combat debug projection: `PNC_CombatTactics_ThreatAssessment.AssessThreat` reads the cached `PNC_Perception_Frame`/`PNC_SpatialIndex` result, and `PNC_NetworkSnapshots_CombatDebugState_TacticalPayload` exposes `visibleZombieCount`, `nearbyZombieCount`, `pressureCount`, `visiblePressureCount`, `hordeCount`, and `visibleHordeCount`; `PNC_NameplateRenderer_DebugText.appendThreatSummary` renders `THREAT ... horde=visible/total`, with `VIEW zombies=visible/nearby`. This is distinct from Director “Resolved density”, which is a population/group/settlement multiplier, not a zombie count.

The one population-wide engine traversal is `PNC_WorldCensus.Refresh`: its cadence-bounded `getCell():getZombieList()` snapshot feeds `PNC_SpatialIndex.Rebuild`, `PNC_Perception_Frame`, follower hazard candidate pools, and combat threat assessment. Follow hazards use a bounded per-owner candidate cache and emit `ObserveZombieHorde`; combat uses the same spatial/perception cache and a 200ms tactical cache. WKG must consume the resulting bands/transitions and add no census.

Hoomans authority points are now frozen: `FactionIncidentService.AddIncident` commits `member_killed`, severe attack/rescue and escalation; `FactionService_Lifecycle.Destroy` commits faction destruction and `OnNPCDeath` reconciles leader/member departure; `FactionService_TreatyCommands` commits war, peace, truce, alliance and alliance break. `Health.ApplyDamage` carries `attackerKind`/ID and `Health.Kill` is the canonical death transition. Zombie wounds provide `attackerKind="zombie"`; corpse-awareness attribution currently records only authoritative player/NPC killers, so unknown cause must remain unknown until a producer supplies a complete attribution. Infection death currently calls `Health.Kill` without the original damage event and is therefore not safe to label beyond its explicit reason.

PZ API audit used the local decompiler baseline `42.21` (manifest generated 2026-10-05), not an exact 42.20 binary. It confirms candidate engine owners only: `IsoWorld.helicopter:isActive()`, `IsoWorld:isHydroPowerOn()`, `ClimateManager:getSeasonName()`/season ID, and `IsoGridSquare:haveElectricity()` (square-local, not global utility state). No current Hoomans adapter was found for helicopter, global power, water shutoff, or season-as-fact publication. W3 must validate the exact 42.20 Lua binding/authority before using these; no API is guessed in W0.

Core seams are the existing `PsychopatzCore.Actors` identity/provider/persistence services, personal `ActorKnowledge`, and `Conversation.ActorService`; WKG world references must remain separate from the player-scoped personal Knowledge payload. Hoomans currently builds `GOSSIP_RECEIVED` through `CognitionService` and bounded `npcGossip.statements` (maximum four), with optional PBrainZ consuming the same projection. The real production-Lua worker before-state was captured with `test_authoritative_gossip_memory_reaches_response_selection_in_en_and_tl`: authoritative scenario memory produced `semantic.gossip.memory` (`Mara has been looking out for people.`) and no supplied memory produced `semantic.gossip.unknown` (`I haven't heard any news lately.`), with zero LLM calls. This is pre-WKG evidence, not acceptance of grounded knowledge.

DT authority is frozen at `DTCommon`: `traderID`/stock/budget/quotes/sessions/transactions remain commerce-owned; `DTCommon.CoreActorPolicy` resolves the shared Core `actorID`; `DTCommon.TalkService` owns bounded talk sessions and provider-revision checks; DTAbstract and DTHoomans only switch/project the same Core actor. Talk facts must never authorize trade or inventory mutation. DT has no WKG adoption/progress docs at this baseline; the missing adopter contract is a W0 documentation gap.

Coverage evidence: codebase-memory generation `2026-10-07T23:10:40Z` reported no recorded issue for the indexed Hoomans authority paths, but marked the changed/missing semantic paths for direct-source fallback; Core and DT runtime media are deliberately excluded and were read directly. Java coverage generation `2026-10-05T23:31:01Z` reported no recorded issue for the candidate API classes. These are best-effort coverage signals, not completeness proofs.

## W1 Core mechanism (2026-10-22)

Core now owns the reusable, policy-free World Knowledge mechanism under `PsychopatzCore.WorldKnowledge`:

- `PsychopatzWorldFact` provides versioned typed facts, stable IDs, primitive-only payloads, provenance vocabulary, confidence, producer/source fields, retention classes, expiry, and persistence filtering.
- `PsychopatzWorldFactLedger` provides bounded dedupe, expiry, eviction, query and persistence metrics. Ephemeral facts and derived-current state are excluded from the default persisted payload.
- `PsychopatzActorWorldKnowledge` stores bounded per-actor fact references, authorized acquisition metadata, relevance ranking, bounded event-driven sharing, explainability, and compact save/load payloads. It stores references, not localized prose or transcripts.
- `PsychopatzWorldKnowledge` exposes the singleton ledger/actor/reference/provider seam and a portable conversation context with bounded `npcGossip.statements` only when an adopter supplies a renderer.

Focused evidence:

```text
lua tests/psychopatz_world_knowledge_smoke.lua                         PASS
lua tests/psychopatz_core_composition_smoke.lua                         PASS
lua tests/psychopatz_npc_actor_smoke.lua                                PASS
lua tests/psychopatz_actor_conversation_service_smoke.lua               PASS
lua tests/psychopatz_npc_provider_lease_smoke.lua                       PASS
```

`tests/psychopatz_world_knowledge_smoke.lua` covers typed faction death, stable dedupe, Alice-known/Bob-unknown selection, grounded rendering, Alice-to-Bob told provenance, explainability, ephemeral save exclusion, and reload. `pz_verify.py` reports zero Kahlua errors for all four new Core WKG modules. The implementation is intentionally not a Hoomans faction/zombie policy and does not enumerate zombies.

## W1 persistence correction and bounded stress evidence (2026-10-22)

Commit `14d9188` closes the persistence edge discovered during W9 audit: actor references are now filtered against the same `Fact.ShouldPersist` retention policy as the global ledger. Ephemeral and derived-current facts cannot leave orphaned actor references in a save payload. The smoke fixture now verifies both payload filtering and reload filtering.

Measured Core evidence:

```text
lua tests/psychopatz_world_knowledge_smoke.lua
  PASS
lua tests/psychopatz_world_knowledge_stress.lua
  PASS elapsed=0.0335s ledger=256 actors=128 persistedFacts=254 payloadUnits=88165 deduped=19
python3 skills/pz-verify/scripts/pz_verify.py --dir Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/WorldKnowledge --kahlua --no-snippets
  4 files; 0 errors; 0 warnings
```

The stress fixture publishes 1,000 historical events and attempts acquisition for 500 actors under `maxFacts=256`, `maxActors=128`, `maxRefs=16`. It proves bounded eviction, dedupe, compact primitive persistence, no localized prose/transcripts, historical reload, and exclusion of ephemeral/derived facts and references. The timing is Lua-process fixture time, not native Project Zomboid tick time.

## W2-W9 cross-repository closeout (2026-10-22)

The canonical developer phases are complete:

- W0 — authority/source audit and contract freeze: complete. The source/authority matrix, real pre-WKG worker before-state, Build 42.20 API limitations, ModData boundaries, and the current cached zombie diagnostic path are recorded above and in adopter `AUDIT.md` files.
- W1 — Core primitive: complete in `471b732`; persistence correction/stress evidence in `14d9188` and `5035a28`.
- W2 — Hoomans producer/conversation adoption: complete in `dd13852f` and `d3d16a1a`.
- W3/W4 — guarded PZ world-state readers and event-driven propagation: complete in `9b2a875b`; absent water/global authority remains explicit unknown.
- W5/W6 — Semantic Lab production worker, inspection commands, offline EN/TL realization, and optional PBrainZ same-fact projection: complete in `d17da262`.
- W7 — DynamicTrading Core+DT adapter, Talk integration, provider continuity, commerce non-authority and persistence: complete in `77c6f90b`; docs in `a7c1277c`.
- W8 — existing Semantic Lab GUI World Knowledge pane and live-worker GUI evidence: complete in Hoomans `d1c642f0`.
- W9 — persistence/performance/security regression evidence: complete in Core `14d9188`, Hoomans `ba9f32b8`/`c5fb01cc`, and DT `77c6f90b`/`a7c1277c`.

Final focused evidence:

```text
Core: lua tests/psychopatz_world_knowledge_smoke.lua                         PASS
Core: lua tests/psychopatz_world_knowledge_stress.lua                         PASS; latest run ~0.0375s, ledger=256, actors=128, persistedFacts=254, payloadUnits=88158, deduped=19
Core: lua tests/psychopatz_core_composition_smoke.lua                          PASS (existing money/currency warnings only)
Core: lua tests/psychopatz_npc_actor_smoke.lua                                 PASS
Core: lua tests/psychopatz_actor_conversation_service_smoke.lua                PASS
Core: lua tests/psychopatz_npc_provider_lease_smoke.lua                        PASS
Hoomans: python3 tests/run_tests.py pnc_world_knowledge_smoke pbrainz_world_knowledge_smoke --verbose  PASS 2/2
Hoomans: python3 -m unittest ...test_grounded_world_knowledge_gossip ...test_world_knowledge_inspector ...test_automatic_flow_generation.AutomaticFlowGenerationTests.test_authoritative_gossip_memory_reaches_response_selection_in_en_and_tl -v  PASS 4/4
Hoomans: xvfb-run -a python3 -m unittest ...test_world_knowledge_gui -v  PASS
Hoomans: python3 -m tools.semantic_harness.testing.performance --samples 2 --warmup 1 --serial-turns 8  PASS; bounded worker histories, measured non-native latency
DT: python3 tests/run_tests.py dt_world_knowledge_smoke dt_talk_service dt_provider_hotswap_persistence dt_trade_access_security dt_npc_provider_adapter --verbose  PASS 5/5
```

No independent zombie enumeration, per-tick all-actor/all-fact scan, second gossip store, persisted localized statement, transcript or LLM-authored canonical fact was added. Coverage metadata was rechecked after the implementation: Core/DT runtime media are intentionally excluded and were read directly; Hoomans changed worker metadata was read directly; all coverage signals remain best-effort and not completeness proofs.

Native Project Zomboid rows remain explicitly UNTESTED and reserved for the user: single-player and multiplayer live authority, exact Build 42.20 helicopter/power/water/season bindings, real-world zombie pressure crossing, faction/death events in gameplay, Workshop packaging/publish, and native save/reload footprint. No Workshop content was published, republished, installed or launched.
