# ConvoEngine Handoff

```yaml
status: "IN_PROGRESS"
phase: "S10 — Semantic Lab end-to-end reliability and maintainability"
chunk: "S10C — feature-owned real GUI acceptance and Feature Acceptance Registry"
participant_vector: "psychopatz-core=<updating-on-S10B-commit>;project-hoomans=5f8b5000e7bfbb26050ff77d63bbdd733e4c3dbe;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
evidence: "S10A_COMPLETE; S10B_COMPLETE; PNC_198_MODULES_FAIL_0; ACCEPTANCE_9_SUITES_VERIFIED; S10C_ACTIVE"
baseline: "retains S0-S9R + S10A + S10B"
```

## Current state

S10A and S10B are complete and committed locally (`ProjectHoomans` at `5f8b5000e7bfbb26050ff77d63bbdd733e4c3dbe`, `DynamicTrading` at `9c8cb3dead56d66e32fccb901b9abd3dd6c2f393`, `PsychopatzCore` closing S10B on `main`). All 8 ConvoEngine/Python/Worker/Tk/DT/Audit/Kahlua acceptance suites passed `FAIL=0`, and `hoomans_lua` reported `1024/1028` with `convoSemanticFailed=0` (`convoScopeOk=True`). S10C now begins immediately.

## Preserved unrelated parallel work

- `psychopatzCore`: `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Inventory/PsychopatzItemTypeLedgerWindow.lua`, `Contents/mods/PsychopatzCore/common/media/translation/{EN,TL}/Conversation/UI.json`, and `tools/semantic_harness/ui/layout_state_controller.py`.
- `ProjectHoomans`: `docs/Jobs/*`, `PNC_ClientComposition.lua`, `PNC_CommandHub*`, `PNC_TranslationBootstrap.lua`, `PNC_NPCAuthoring*`, and `common/media/translation/{EN,TL}/CommandHub/CommandHub.json`.
- `DynamicTrading`: `.architecture-refactor/output/architecture-audit.md` and `tools/providers/dt/__pycache__/`.

## Immediate next responsibility — S10C

1. Author `tools/semantic_harness/testing/feature_registry.json` and `tools/semantic_harness/testing/feature_registry.py` mapping every supported public GUI/CLI/agent action and validating AST/import symbol ownership and Tk GUI test coverage.
2. Add `ProjectHoomans/tools/providers/pnc/tests/test_s10c_gui_journeys.py` exercising the missing real Tk/Xvfb GUI workflows (provider selection reconfiguration, simulation preview/send/language/reset/load/save, quality sweep plan/run/cancel/replay, studio authoring in hermetic temp repos + preview + S6M8 audit, diagnostics/regressions/activity log clear, and expected worker failure + restart recovery).
3. Add `tools/semantic_harness/tests/test_feature_registry.py`, verify affected suites, reconcile docs, commit S10C locally, and continue immediately into S10D.
