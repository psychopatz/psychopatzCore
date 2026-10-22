# Acceptance — World Knowledge, Gossip and Semantic Lab

## Required evidence classes

Schema/unit tests alone are insufficient. Acceptance must combine:
- Core-only Lua tests for fact/knowledge persistence and boundedness;
- Hoomans source-owner adapter tests;
- DynamicTrading adopter/provider tests;
- existing Semantic Lab production Lua worker scenarios;
- GUI/inspector evidence for provenance and selection;
- EN/TL final rendered dialogue;
- bounded persistence/performance measurements.

## Mandatory grounded scenarios

At minimum cover:

1. Zombie pressure: an existing cached Hoomans threat observation crosses a meaningful band; no new global zombie scan; informed actor can report it while an uninformed actor cannot.
2. Member death by zombie: source event/cause proven by owner, faction member learns through allowed path, unrelated actor does not magically know.
3. Member death by hostile NPC/faction and by player where authoritative attribution exists; never infer a killer when attribution is unavailable.
4. Faction destroyed/collapsed: neighboring or faction-linked actor learns only through configured dissemination.
5. Helicopter in progress/recent, power off, water off and season: values come from audited PZ authority; truthful unknown when adapter cannot resolve.
6. Propagation: Alice experienced fact -> tells Bob -> Bob later says "heard/told" semantics with lower/appropriate certainty; Charlie stays unaware.
7. Save/reload: historical fact and bounded actor reference survive; ephemeral/runtime observations follow their retention contract.
8. DTAbstract trader learns/discusses an allowed fact; same Core actor in DTHoomans retains it; trade transaction is still separately authorized.
9. Offline/PBrainZ parity: both receive the same authorized fact set; PBrainZ cannot surface a ledger fact absent from actor projection.
10. Two-player/channel privacy: player-specific private Knowledge is not leaked through world gossip or radio.

## Semantic Lab requirements

Extend the existing application, not a new harness. The inspector must make visible:
- Fact Ledger: ID, kind, subject/cause/location, producer, time, retention;
- Actor Knowledge: fact ID, acquisition source, source actor/faction, confidence, learnedAt;
- Propagation Trace: sender, recipient, eligibility/rejection, dedupe/cooldown;
- Gossip candidates: known/authorized/relevant/rank reason;
- final response source and localization.

Editable scenarios must be able to create test facts/knowledge without bypassing the same production contracts used by the worker. Debug fixtures may inject authoritative test evidence explicitly but must label it as scenario-owned, never as proof of a PZ runtime hook.

## Performance/persistence acceptance

Prove:
- no independent getZombieList/population scan introduced;
- no per-tick all-actor/all-fact comparison;
- fact ledger bounded under sustained synthetic event generation;
- actor reference list bounded/deduped;
- expired ephemeral facts and runtime caches do not bloat saves;
- no localized dialogue prose/transcript persisted as canonical world truth;
- large synthetic actor/fact run has bounded work and reports measured timings/footprint.

## Handoff

After every developer-owned gate passes, report READY FOR USER LIVE TEST and provide exact native SP/MP scenarios the user should run. Do not mark native rows passed without user evidence, and do not publish/install Workshop content.
