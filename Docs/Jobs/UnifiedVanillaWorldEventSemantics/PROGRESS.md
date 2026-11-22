# Progress — Unified Vanilla World Event Semantics

**Status:** PLANNED FROM LIVE AUDIT; DEVELOPER WORK REQUIRED.
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Participants:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
**Branch policy:** existing `main` only; no new branches.
**Planning heads:** Core `fecc800b05d0874e94a8600833880a77cd967e8d`; Hoomans `7847ccfb833425a2553bd9602aebaf958f76d7ed`; DynamicTrading `feee4da8fe4cab1ff4dcc1066ef1d4548b5728bb`.
**Current phase:** V0 — exhaustive installed-build vanilla-event topology and coverage manifest.
**Next Chunk:** Build the deterministic V0 coverage inventory/manifest from the current installed Project Zomboid runtime and reconcile it against existing Core/Hoomans/DT event, location, knowledge and persistence seams before editing runtime behavior.

## Verified planning facts

- Core already has the reusable bounded scoped-event authority and WorldKnowledge; do not replace them.
- DynamicTrading already reads Core scoped events and therefore does not need ProjectHoomans as an event dependency.
- ProjectHoomans already has a bounded 10-second environment cadence and useful vanilla hooks; do not create another OnTick/per-NPC watcher.
- Current dialogue corpus has only 13 flow graphs and only one constrained branch offer; deeper variety is mandatory but must remain bounded/semantic.
- Initial global scope is restricted to vanilla electricity and water cutoff.
- Helicopter must be modeled as a regional/local bounded episode with location-aware outdoor/indoor knowledge.
- `OnAmbientSound(name,x,y)` provides authoritative position for vanilla ambient meta events.
- Installed randomized-world families include 45 building, 33 dead-survivor, 26 vehicle, 42 zone and 2 ranch classes. All must be accounted for in the V0 coverage manifest, including explicit evidence-backed gaps.
- Ambulance crash and analogous spawned world stories are location-grounded discovery facts, not global news.

## Parent acceptance

Developer completion requires V0–V8. A subset of vanilla events, one dialogue theme, or one consumer integration is not parent completion. V9 is user-owned native SP/MP acceptance after all developer-side work is complete.
