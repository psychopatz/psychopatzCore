# ConvoEngine Handoff

~~~yaml
status: CLEAN_CHECKPOINT
checkpoint_mode: committed_handoff
phase_commit: self
phase: S13F — ConvoEngine Single-Artifact Behavior/Beat Projections & Director Readiness Freeze (COMPLETE)
parent_phase: S13 — ConvoEngine Layout Normalization and Director Architecture Freeze
next_chunk: ProjectHoomans Phase U5b — Micro-Beat Dialogue Director & RDR2 Street Interaction
planned_next_goal: Docs/semantic_dialogue_language_standard/CONVERSATION_DIRECTOR_ARCHITECTURE.md
layout_standard: Docs/semantic_dialogue_language_standard/CONVOENGINE_PHYSICAL_LAYOUT_AND_LOCALIZATION.md
director_architecture: Docs/semantic_dialogue_language_standard/CONVERSATION_DIRECTOR_ARCHITECTURE.md
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
updated_at: 2026-11-22T05:06:00+08:00
~~~

## Accepted participant vector

~~~text
psychopatzCore   self (S13D–S13F closure commit on main; S12R2 at ce86135)
ProjectHoomans   S13D–S13F reconciled cleanly (commits with Phase U5)
DynamicTrading   d4034fac5f547e00253dc3b9db5fd4554e37b535
~~~

## What became true this session

- Completed **S13D–S13F** single-artifact Behavior/Beat projection collapse and Director readiness freeze across `psychopatzCore`, `ProjectHoomans`, and `DynamicTrading`:
  - Emitted compact derived `Index/Director.lua` (`convo_engine_director_index.py`) with sparse inverted lookup buckets (`byStimulus`, `byDomain`, `byTopic`, `byActivity`, `byEventType`, `byRequiredFact`, `byKind`) and zero semantic body duplication.
  - Derived `Registry.BEHAVIORS`, `Registry.BEATS`, and `Registry.DIRECTOR_INDEX` in `conversation_registry.py` from canonical `Behavior/*` and `Beat/*` plans only; deleted all 13 duplicate `Behaviors/Director/*` and `Beats/Director/*` files via `reconcile.py --apply`.
  - Added fail-closed `convo_engine_director_audit.py` (`convo_engine_cli.py director-readiness`, wired into `convo.audit`): `duplicateBehaviorProjectionBodies=0`, `duplicateBeatProjectionBodies=0`, `obsoleteDirectorProjectionCallers=0`, `directorIndexBodyDuplicationCount=0`, `missingDirectorReadinessCapabilityCount=0`, `activeCurrentPsdlIdentityCount=0`, two-pass determinism clean (446 files, `diffs=0`).

## Exact next resume action

`ConvoEngine` S13 (S13A–S13F) is **COMPLETE**. Proceed directly with ProjectHoomans Phase **U5b** (Façade-inspired Micro-Beat Dialogue Director & RDR2 Street Interaction) atop `CONVERSATION_DIRECTOR_ARCHITECTURE.md` and `PNC/ConvoEngine/Index/Director.lua`. Do not push or launch native Project Zomboid without explicit authorization.
