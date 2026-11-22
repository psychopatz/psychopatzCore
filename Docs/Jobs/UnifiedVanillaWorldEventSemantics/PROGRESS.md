# Progress — Unified Vanilla World Event Semantics

**Status:** V0 COMPLETE; PROCEEDING TO V1 (Core normalized event observation and location contract).
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Participants:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
**Branch policy:** existing `main` only; no new branches.
**Planning heads:** Core `fecc800b05d0874e94a8600833880a77cd967e8d`; Hoomans `7847ccfb833425a2553bd9602aebaf958f76d7ed`; DynamicTrading `feee4da8fe4cab1ff4dcc1066ef1d4548b5728bb`.
**Current phase:** V1 — Core normalized event observation and location contract.
**Next Chunk:** Implement `PsychopatzWorldEventLocation.lua` and `PsychopatzVanillaEventObserver.lua` in Core with single location resolution, global-scope restriction, dedupe, and tests.

## Completed phases
- **V0 (Accepted):** Generated deterministic `VANILLA_EVENT_COVERAGE.json` (`203` entries: `14` live events, `3` state transitions, `86` discovery events, `72` generic semantic category entries, `26` intentionally ephemeral, `2` unsupported unregistered classes with Java evidence, `0` unclassified) via `tools/vanilla_event_coverage/generate_manifest.py`, verified with `tests/test_vanilla_event_coverage_manifest.py`.

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
