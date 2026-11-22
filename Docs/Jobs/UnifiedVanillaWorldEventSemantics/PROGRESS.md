# Progress — Unified Vanilla World Event Semantics

**Status:** V6 COMPLETE; PROCEEDING TO V7 (ProjectHoomans adoption and deeper branching).
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Participants:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`, `/home/psychopatz/Zomboid/Workshop/DynamicTrading`
**Branch policy:** existing `main` only; no new branches.
**Planning heads:** Core `fecc800b05d0874e94a8600833880a77cd967e8d`; Hoomans `7847ccfb833425a2553bd9602aebaf958f76d7ed`; DynamicTrading `feee4da8fe4cab1ff4dcc1066ef1d4548b5728bb`.
**Current phase:** V7 — ProjectHoomans adoption and deeper branching.
**Next Chunk:** Expand all 8 thematic interactive dialogue families, semantic affordances, hard contextual constraints, numeric disposition/relationship weighting, multi-actor scene interjections/outcomes, and EN/TL realizations in ProjectHoomans (via canonical CodeBuilder JSON sources + reconcile).

## Completed phases
- **V0 (Accepted):** Generated deterministic `VANILLA_EVENT_COVERAGE.json` (`203` entries) via `tools/vanilla_event_coverage/generate_manifest.py`, verified with `tests/test_vanilla_event_coverage_manifest.py`.
- **V1 (Accepted):** Added `PsychopatzWorldEventLocation.lua` and `PsychopatzVanillaEventObserver.lua`, registered `core.vanilla_event_observer`, verified via `tests/psychopatz_vanilla_event_observer_smoke.lua` and `pz-verify`.
- **V2 (Accepted):** Wired ModData persistence (`PsychopatzCore.ScopedWorldEvents`, `OnInitGlobalModData`/`OnSave`, `OnStateLoaded`), expired-on-load pruning, ledger load-time expiry pruning, and cap enforcement (`32`/`64`/`256`), verified via `tests/psychopatz_world_events_persistence_smoke.lua` and `pz-verify`.
- **V3 (Accepted):** Added `PsychopatzPZWorldEventAdapter.lua` utility adapter + Hoomans non-global synthetic scope enforcement + shared utility wiring.
- **V4 (Accepted):** Added regional helicopter episode capture (`<= 5` coarse samples, zero same-bucket writes, reload resume) + Hoomans indoor/outdoor/told/radio epistemic precision.
- **V5 (Accepted):** Implemented `OnAmbientSound` (gunfire variants, scream, `burglar2`, ephemeral wildlife/dog/thunder), `OnWorldSound` (`Alarm` fast guard), `WeatherPeriod` severe storms, `OnThunderEvent`, `OnDeviceText`, `OnNewFire`, and `ObserveSeason` in Core (`PC_ServerComposition` eager server load + fact-before-event publish order), plus Hoomans nearby actor live perception & realizations; verified across Core & Hoomans suites.
- **V6 (Accepted):** Added `PsychopatzVanillaDiscoveryAdapter.lua` (`core.vanilla_discovery_adapter`) for zero-scan chunk/spawn/room story discovery (`RVS*` including `RVSAmbulanceCrash`, `RZS*` via `pickedRzStory`, `RB*`/`RDS*` grounded observable room evidence on `OnSeeNewRoom`, and `Ranch` zones via bounded `MAX_PENDING_SITES = 64` buffer) plus Hoomans `DiscoverNearbyStories` and `discovery.*` realizations; verified via `tests/psychopatz_vanilla_discovery_smoke.lua`, `tests/pnc_vanilla_story_discovery_smoke.lua`, and `pz_verify.py`.

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
