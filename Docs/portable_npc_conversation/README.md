# Portable NPC Conversation and Cross-Mod Identity — C1–C6

**AUTHORITATIVE NEW CROSS-REPOSITORY GOAL (2026-10-21). Status: IN PROGRESS / NO implementation from this planning commit.** Owner: **PsychopatzCore**. Adopters: ProjectHoomans and DynamicTrading (DTCommon, DTAbstract and optional DTHoomans). This is a user-approved new objective after the ProjectHoomans V1–V5 developer implementation, NOT a reopening or recoding of that accepted foundation.

## Product goal

NPC actors with one stable identity, persona, personal-history facts, directional relationships, player-scoped Knowledge and bounded offline conversation can be spoken to in **Core-only, Hoomans, DTAbstract radio and optional DTHoomans physical contexts**. The same character must keep those facts and relevant pending dialogue across supported abstract/physical provider transitions and save/reload. Handle reciprocal/compound speech acts and context-bound follow-ups without an LLM; truthful uncertainty rather than fabricated causes. Optional PBrainZ must obey the same server-authoritative fact/disclosure boundaries.

**Visible defects driving this goal:** real Semantic Lab screenshot: `where do you live` returned truthful unknown residence; `why is it so?` fell to `I'm not sure what you mean`; greeting replied `How have you been?`, but `im fine, how about you` fell to unrecognized/default. Hoomans greeting `await_thanks` currently accepts THANK only, while wellbeing flow has a separate bounded answer contract. C1 must reproduce with the REAL worker and identify routing / pending-speech-act / compound-turn causality rather than hardcode phrases.

## Canonical docs

- `ARCHITECTURE.md`: field owners and boundaries, Core service design, seed/delta policy, channel and capability security
- `MIGRATION_AND_HOTSWAP.md`: no-loss Hoomans Knowledge/backstory migration, provider lease and save/restart paths, authority
- `HARNESS_ACCEPTANCE.md`: real Semantic Lab Core-only, Hoomans, DTAbstract, DTHoomans and combination test matrix
- `ROADMAP.md`: ordered C1–C6 roadmap and acceptance gates
- `AGENT_RUNBOOK.md`: execution instructions, single-chunk cadence, Git/no-publication policy
- `PROGRESS.md`: **read LAST**; exactly one current execution chunk and verified baseline
- ProjectHoomans adopter contract: `docs/Jobs/ContextualDialogueQuestFramework/CORE_CONVERSATION_ADOPTION.md`; DynamicTrading: `Docs/npc_foundation/PORTABLE_CONVERSATION_ADAPTER.md`.

**Read order:** root `AGENTS.md` in EACH repository → Core `README.md`, `ARCHITECTURE.md`, `MIGRATION_AND_HOTSWAP.md`, `HARNESS_ACCEPTANCE.md`, `AGENT_RUNBOOK.md`, `ROADMAP.md` → relevant adopter contracts → **`PROGRESS.md` LAST**.

**No checked-in goal prompt:** `/goal` is delivered in ChatGPT, NEVER committed to `GOAL_PROMPT.md` or duplicated in any repository.

## Previous source state, not completion of this goal

Audit snapshot: Core main `2179ee19307a993e186e6da661ad4212e984e0b4`; Hoomans main `be0bf4c4680b988c1890295fa496995c36f2d358`; DT main `950b4f887e6f3cb3e311c659b852cbf3ec6f3883`. Core NPC Foundation P1–P9 is reported developer accepted; Hoomans V1–V5 and later harness package modularization are reported developer complete. **No Core portable personal-dialogue shared service or DTAbstract personal-talk path was verified in this audit.** Earlier Lua/Python pass numbers are historical reports, not new runs. Native PZ SP/MP/live save behavior remains solely user-owned.
