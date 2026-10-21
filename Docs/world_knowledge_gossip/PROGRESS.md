# Progress — Grounded World Knowledge & Gossip

Updated: 2026-10-22
Status: IN PROGRESS / PLANNED; no implementation from this documentation commit.

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
