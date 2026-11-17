# ConvoEngine Handoff

~~~yaml
status: DIRTY_RESUMABLE
checkpoint_mode: committed_handoff
phase_commit: self
phase: S11A — foundation build and freeze before production migration
chunk: S11A6 — memory/modifier lifecycle (S11A5 accepted)
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S11_STATE_AWARE_CONVERSATION_OUTCOME_CLOSURE.md
foundation_order_doc: Docs/semantic_dialogue_language_standard/S11_FOUNDATION_FREEZE_AND_MIGRATION_ORDER.md
updated_at: 2026-11-18T07:58:00Z
~~~

## What became true in S11A5

- Added Core-owned `Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/S11DomainAdapters.lua` (`RegisterDomainAdapter`, `RegisterEffectHandler`, `RegisterQueryHandler`, `RegisterMemoryAdapter`, `DispatchEffect`, `ApplyModifier`, `RecordMemoryResidue`, `ResolveQuery`, `ExecuteAction` delegating to `ActionContract.Execute`).
- Added ProjectHoomans adopter binding `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/PNC_S11DomainAdapters.lua` routing portable relationship, mood, memory, and inventory contracts directly to `PNC.Relationships`, `PNC.Morale`, `PNC.Conversation.Memory`, and `PNC.Inventory` with zero shadow state or compatibility shims.
- Verified `0` Kahlua errors via `pz_verify.py --kahlua` and `2/2 PASS` in `tools.semantic_harness.tests.test_s11_domain_adapters`.

## Immediate Next Chunk

Execute **S11A6** (generic memory/modifier lifecycle: retention, stacking/dedupe, bounded game-time expiry) and continue automatically through S11A8.
