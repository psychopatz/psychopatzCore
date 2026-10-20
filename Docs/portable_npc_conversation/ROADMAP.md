# C1–C6 Roadmap — Portable NPC Identity and Contextual Conversation

**PARENT STATUS: IN PROGRESS.** New cross-repository product goal; preserve prior Core P1–P9 and Hoomans V1–V5 developer work. Exactly ONE active implementation chunk C1. Automatically continue through C2–C6 without marking the parent complete after a single successful phase.

| Phase | Status | Required result |
| --- | --- | --- |
| **C1 — actual worker conversation audit and correction baseline** | **CURRENT / NOT IMPLEMENTED** | Reproduce screenshot, trace pending greeting/health flow and causal reference, characterize compound speech acts/negative collisions, produce first reusable Core routing contract and regression; no hardcoded exact phrases |
| C2 — Core portable persona and Knowledge authority | PLANNED | Versioned Core seed/backstory/Knowledge contracts, idempotent Hoomans migration, 2-player privacy/dossier; Core-only independent save/reload |
| C3 — shared offline conversational competence | PLANNED | Core dialogue service over existing parser/router/state; compound turns, pending acts, causal/referent resolution, appropriate uncertainty, localized response keys; same tests without Hoomans |
| C4 — Hoomans/DT integration | PLANNED | Hoomans registers contextual gameplay providers; DTAbstract authenticated radio Talk and DTHoomans physical Talk share Core conversation API; trade/quest authority remains respective owner |
| C5 — safe provider hot-swap and persistence | PLANNED | Actor/body/lease/trader ID invariant, bounded session carryover, mod configuration over restart, no duplication, stale action, privacy leak or unwanted reroll |
| C6 — full Semantic Lab matrix and handoff | PLANNED | Actual GUI/real Lua worker Core-only/Hoomans/DTAbstract/DTHoomans/combined, EN/TL, per-player privacy, synthetic footprint and full regressions; READY FOR USER LIVE TEST only after all pass |

Keep Core portable and lightweight; no additional standalone compiler/Knowledge store/translation layer. The existing Semantic Lab remains the principal authoring/test surface. No agent native-game or Workshop tasks; no new branches; no checked-in `GOAL_PROMPT.md`. Current ONE execution chunk is in `PROGRESS.md`.
