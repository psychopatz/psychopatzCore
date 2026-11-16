# ConvoEngine Handoff

```yaml
status: "USER_ACCEPTANCE"
phase: "S10 — Semantic Lab end-to-end reliability and maintainability (developer-side complete)"
chunk: "S10D complete — ready for native Project Zomboid user acceptance"
participant_vector: "psychopatz-core=<updating-on-S10D-commit>;project-hoomans=9778522ffe1976f71d0d1c2efa1f5fb6d741070e;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
evidence: "S10A_COMPLETE; S10B_COMPLETE; S10C_COMPLETE; S10D_COMPLETE; S10_9SUITE_ACCEPTANCE_VERIFIED; S9R_CLOSURE_4_OF_4"
baseline: "retains S0-S9R + S10A + S10B + S10C + S10D"
```

## Current state

All developer-implementable S10A-S10D requirements and retained S0-S9R regression gates are complete and verified on `main`:

- **S10A**: manifest-selected PNC worker starts/restarts cleanly with `MAX_POOLS = 256`, preflight diagnostics, canonical/generated identity speech variant realization, and zero implicit label-to-speech fallback.
- **S10B**: unified 9-suite `--acceptance` runner with explicit runtime skip classification (only reviewed `real_local_save_unavailable` skips allowed) and `xvfb-run` Tk orchestration.
- **S10C**: machine-readable Feature Acceptance Registry (`feature_registry.json`), AST + real-Tk control enforcement (`test_feature_registry`), and 4/4 real Tk/Xvfb GUI journeys (`test_s10c_gui_journeys`).
- **S10D**: provider start/capabilities/input/restart/reconfigure/shutdown lifecycle matrix (`test_s10d_provider_lifecycle` 3/3 PASS across `pnc`, `dtabstract`, `pnc-with-dthoomans`, and standalone Core worker) and updated `AGENT_RUNBOOK.md`.

Only user-owned native Project Zomboid gameplay, UI/visual feel, and live dialogue pacing validation remain before live workshop release.

## Preserved unrelated parallel work

- `psychopatzCore`: `Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/UI/Inventory/PsychopatzItemTypeLedgerWindow.lua`, `Contents/mods/PsychopatzCore/common/media/translation/{EN,TL}/Conversation/UI.json`, and `tools/semantic_harness/ui/layout_state_controller.py`.
- `ProjectHoomans`: `docs/Jobs/*`, `PNC_ClientComposition.lua`, `PNC_CommandHub*`, `PNC_TranslationBootstrap.lua`, and `common/media/translation/{EN,TL}/CommandHub/CommandHub.json`.
- `DynamicTrading`: `.architecture-refactor/output/architecture-audit.md`, `Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/{Manifest,Registry}.lua`, `Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua`, and `tools/providers/dt/__pycache__/`.
