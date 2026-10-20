# Real Semantic Lab — Portable Conversation Acceptance

**Primary verification: existing Hoomans Semantic Lab and real Core+Hoomans Lua worker**, extended with optional Core-only and DT adapter dependency configurations. No second harness app, JSON-only substitute, isolated parser count, or Codex-launched native PZ. Use existing GUI Studio/Simulation/Inspector, CodeBuilder graph→InteractionSpec→approved generated real Lua/EN/TL assets, worker restarts and actual final NPC text.

## Reproduce screenshot BEFORE editing

An actual worker scenario uses exactly:
```text
PLAYER: where do you live
NPC: I don't have a confirmed home to tell you about.
PLAYER: why is it so?
NPC: I'm not sure what you mean.
PLAYER: hello
NPC: Hello. Good to see you.
NPC: How have you been?
PLAYER: im fine, how about you
NPC: I'm not sure what you mean.
```
Trace each turn's Core candidates/IR, Hoomans flow, pending node/agenda, last factual response, pronoun antecedent, actual render and transport. Current Hoomans greeting flow `PNC_SemanticDialogueFlow_Greeting.lua` has `await_thanks` accepting THANK only; wellbeing flow `PNC_SemanticDialogueFlow_Wellbeing.lua` already handles certain INFORM/QUESTION replies. Fix portable *contextual intent binding* and compound turns in existing core route/registered flows rather than just adding exact four sentences. The original residence response is a legitimate truthful unknown; do not invent a reason why housing is unknown.

## Behavioral contract

At minimum verify paraphrase and negative collision sets for:
- `I'm fine / doing okay / I'm alright` plus `how about you / what about yourself` (combined one turn and separately).
- `why is that / why is it so / how come` after unknown residence, after a *known* grounded factual statement, after interruption and with no antecedent. Unknown cause -> explicit truthful uncertainty **with reference to the topic**, not generic `I don't know what you mean`.
- Intro/greeting → NPC-initiated pending question → player answer → reciprocal question → topic interrupt/resume → conclusion; verify no stale `await_thanks` agenda.
- Genuine inventory questions vs compliments, imperative STAY vs mere discussion, trade-talk vs trade commit, quest authorization, EN/TL, safe no-news/no-health unknown responses.
- Server real disclosure and Dossier with actor A/player 1 vs player 2, confirmed vs suspected, privacy/approval/personality and PBrainZ optional consistent fail-closed.
- Same abstract merchant talks on authenticated radio then nearby after valid body lease transition, remembering bounded facts/relationship, but RADIO never grants unearned inventory/trade fulfillment.
- Core-only actor and DT-only abstract trader when Hoomans is absent. One response plan and same Core actor identity across combinations, no separate DT grammar or Hoomans-only parser requirement.

## Test matrix and evidence

| Mode | Minimum actual Lua worker acceptance |
| --- | --- |
| Core only | Actor Create→Save→Reload, seed-fixed identity/backstory, personal Knowledge, generic 4-turn conversation EN/TL |
| Core + Hoomans | Existing local dialogue, authored Hoomans skills, semantic flows/facts and Dossier unchanged, screenshot defects repaired |
| Core + DTCommon + DTAbstract without Hoomans | Radio contact Talk via Core, authentic traderID actorID, portable dialogue, stocks and money unchanged |
| Core + Hoomans + DT merchant | Physical Talk uses same actor and Core conversation while Hoomans runtime provides body/health and DTCommon owns trade |
| Both providers | Abstract→materialized→abstract plus save/restart, session/lease revision, no duplicated identity, body, stock, effects or knowledge |
| MP 2 player characters | Each player's private facts stay scoped, stale request rejection, confirmed vs suspected and PBrainZ filtering |

The inspector should show **utterance → candidates → split speech acts → pending question binding/antecedent → actor fact source and player disclosure → response template/locale and final rendered text → authorized side effects → per-player dossier and provider lease**. Capture actual generated artifact paths, no-preview-writes, correct manifest, deterministic hashes, X11 GUI screenshot/interaction when available, performance and same-serializer 0/1/10/100/1000 footprint. Re-run relevant full Core, Hoomans and DT Lua/Python regression, doctor, Kahlua and locale tests with exact SHAs/exit codes. Historic Hoomans `279/279` Python and `853/853` Lua are reports, not fresh evidence for this new cross-mod goal.

**Completion:** all C1–C6 developer-owned behaviors and matrix succeed without fabricating native game access. Then `READY FOR USER LIVE TEST`. Only user performs real PZ SP/MP and Workshop tasks.
