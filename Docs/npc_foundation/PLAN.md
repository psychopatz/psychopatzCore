# Core NPC Foundation — Goal Navigation

Status: approved design, unimplemented. Planning baseline: 2026-10-18.
This is a cross-repository architecture/extraction job. PsychopatzCore is the *target owner* of shared canonical actor state; ProjectHoomans and DynamicTrading are adopters. This is not the current DT trading-MVP or Radio OS goal and must not replace either.

## Read order
1. AGENT_RUNBOOK.md — operating and safety policy
2. ARCHITECTURE.md — target ownership, schema and invariants
3. ROADMAP.md — ordered phases and acceptance
4. PROGRESS.md — actual baseline and ONE Next Chunk
5. PHASE_0_EXTRACTION_AUDIT.md — current bounded work
6. GOAL_PROMPT.md — compact autonomous bootstrap

## Product acceptance
A single Core-generated merchant has a stable identity, name, face, voice, clothing, personal items and their exact portable state, directional relationships, world position and journey. DTAbstract can run it without ProjectHoomans. DTHoomans can project the SAME merchant into its live NPC simulation without rerolling, resetting or duplicating anything; return to abstract retains changes. One DTCommon stock/budget/transaction ledger is shared across modes. Known actors show bounded map markers/hover portraits; nearby actors can open Talk; travel between eligible settlements can trigger earned restocks. SP and MP server authorization are preserved.

100% *canonical data parity* is required for common fields, not identical live combat, animation or needs behavior while abstract. Module install/uninstall switching requires save/restart/load safety; live frontend selection is allowed only when both are loaded.

## Repositories
- Core (canonical goal): https://github.com/psychopatz/psychopatzCore
- Hoomans (legacy producer/body owner): https://github.com/psychopatz/ProjectHoomans
- Trading (merchant and optional frontends): https://github.com/psychopatz/DynamicTrading

Do not infer clean local worktrees from remote HEADs. Cross-repo edits must follow actual checked-out dependency state.
