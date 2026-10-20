# Portable NPC Conversation — CURRENT Progress

**Updated:** 2026-10-21. **Documentation-only phase opening. No implementation changes or runtime tests performed in this commit.**

**PARENT:** C1–C6 IN PROGRESS — NOT READY FOR USER LIVE TEST for cross-mod conversation. **EXACTLY ONE CURRENT EXECUTION CHUNK: C1 — reproduce screenshot in actual Semantic Lab, identify and correct the reusable pending-answer/compound/referent routing seam, establish portable Core contract and negative regressions.** After C1 acceptance, immediately continue C2–C6 in the same parent assignment.

## Source audit baseline, confirmed GitHub main before this docs commit

- Core `2179ee19307a993e186e6da661ad4212e984e0b4`: `PsychopatzActors`, `PsychopatzActorFactory/Registry/Persistence/Provider`, `PsychopatzSocial`, `PsychopatzSemanticParser.ParseCandidates`, `PsychopatzSemanticDialogueRouter`, `PsychopatzSemanticDialogueState` exist. Core-only generic personal conversation/Knowledge is **not yet established** by source audit.
- Hoomans `be0bf4c4680b988c1890295fa496995c36f2d358`: Semantic Lab compiler/authoring/worker and B/H/F/V developer work are reported accepted (latest refactor ledger reports Python 279/279, Lua 853/853), Hoomans backstory stable IDs and PNC Knowledge exist. `PNC_SemanticDialogueFlow_Greeting.lua` has `await_thanks.accepts = THANK only`; wellbeing flow separately handles INFORM+QUESTION. `PNC_SemanticCatalog_QuestionPatterns_ContextQuestions.lua` recognizes residence questions. Screenshot last trace shows `classification=unrecognized_language` after `im fine, how about you`; quoted failure text must be reproduced in worker before root-cause claim. Hoomans current transcript had unknown residence, failed `why is it so?`, and failed reciprocal wellbeing.
- DT `950b4f887e6f3cb3e311c659b852cbf3ec6f3883`: `DTAbstract_CoreProvider` covers actor projection/lease; Radio OS `DTAbstract_RadioOS.lua` has trade action only, no shared personal Talk capability found; `DTCommon_CoreActorPolicy` binds trader to Core actor and applies relationship pricing. Hoomans absent compatibility requires actual test.
- No local checkout process, full test run, GUI interaction, native game or Workshop activity was executed in this docs-only turn. Actual local main and working changes must be inspected before Codex writes.

## C1 next bounded chunk — measurable deliverables

1. Check all three actual local main/upstream/worktree status, Core–H–DT dependency pairing and watched mod media. Read README, ARCHITECTURE, MIGRATION_AND_HOTSWAP, HARNESS_ACCEPTANCE, AGENT_RUNBOOK, ROADMAP, adoption docs, **PROGRESS LAST**. Never create a branch.
2. In existing Semantic Lab Simulation run screenshot turns exactly and adjacent paraphrases. Trace production Lua Core ParseCandidates and Hoomans Flow_Greeting/Flow_Wellbeing, pending agenda, previous actual NPC proposition, flow interruption, final rendered response and tool effects. Preserve screenshot observation vs assumptions.
3. Design and implement the smallest **portable Core** pending-question/answer binding and compound-turn / discourse reference seam using existing parser/IR/state/router and Hoomans registered flow adapters. Correct the misleading generic fallback without inventing factual causes. Avoid sentence-only phrase patches, replacing the parser or moving all Hoomans content now.
4. Run meaningful real worker negative collision + multi-turn EN/TL tests, verify old greetings, inventory, STAY and command authority remain intact. Add Core-only regression for new contracts wherever possible; write exact source/dependency SHAs, commands, return codes, observed outputs and remaining C2 obligations.
5. Commit approved source/tests/docs on existing main in affected repositories only after safe status checks. Continue C2→C6 automatically; do not stop at one good exchange. If unsafe concurrent local changes, describe precise issue and complete other safely separable work before BLOCKED.

## Overall completion contract

All C1–C6 source + real worker matrix (Core-only, Hoomans, DTAbstract, DTHoomans, both), two-player privacy, server lease/hot-swap and save/reload, EN/TL, optional PBrainZ authorization, 0/1/10 and synthetic scaling tests must pass. Native Project Zomboid SP/MP/live game checks and Workshop publication remain solely user-owned. The executable `/goal` prompt is provided only in chat.
