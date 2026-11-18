# Progress — ConvoEngine / Semantic Harness

**Status:** USER_ACCEPTANCE — S11 COMPLETE_DEVELOPER_SIDE / ACCEPTED (`S11E` ACCEPTED, `S11R8` ACCEPTED / CLOSED including `R8D`, `S11R9` ACCEPTED / CLOSED).
**Branch:** existing `main` in all three repositories.
**Active phase:** S11 closed developer-side; ready for user acceptance and subsequent content rewrite.
**Content rewrite gate:** `BULK_DIALOGUE_REWRITE_ALLOWED=true`.

## Closed R8D + R9A-R9D summary

- **R8D (ACCEPTED):** Isolated `test_promotion_writes_only_canonical_source_then_regenerates` in `ProjectHoomans` (`77994e19dccc5a4d94579b480fd24f3db8e68979`) across temporary `core_repository`, `hoomans_repository`, and `dynamic_trading_repository` roots; added participant worktree side-effect guard (`_snapshot_repositories`, `_diff_repository_snapshots`) in `acceptance.py` with unit coverage in `test_acceptance_runner.py`.
- **R9A (ACCEPTED):** Enriched `completeness_analyzer.py` (`analyze_portable_plan`) and `SemanticLabAuthoringService.analyze_convo_completeness()` with canonical source provenance, compiler-derived family semantic graph nodes/edges (`GREEN`/`BLUE`/`PURPLE`/`YELLOW`/`ORANGE`/`RED`), witness/cycle/SCC paths, state/action outcome matrices, closure health, missing ownership, suggested closure classes, and bounded affected-family closure refresh (`family_ids`).
- **R9B (ACCEPTED):** Added first-class `Dialogue Completeness` tab (`completeness_workbench.py`) inside `ConvoEngineAuthoringPane` with batch health/filtering, compiler-derived family graph, diagnostic detail, and canonical-source navigation.
- **R9C (ACCEPTED):** Added `S11 Semantic Controls` tab inside `ConvoEngineAuthoringPane` driven by compiler-owned `FieldDescriptor`s (`statePolicy`, `inputPolicy`, `repeatPolicy`, `postconditions`, `closure`, `roles`, `participantSet`, `topics`, `events`, `activities`, `memories`, `domains`), plus previewable/effect-free structural scaffolding (`completeness_scaffold.py`) applied through `ConvoTransaction`.
- **R9D (ACCEPTED):** Added `test_dialogue_completeness_workbench.py` (3/3) and `test_dialogue_completeness_workbench_tk.py` (1/1 Xvfb), proved Workbench parity with `analyze_convo_completeness(strict_manifest=True)` (`520` families, `0` errors, `1` warning, `520` SCCs), and passed two consecutive canonical 9-suite `--jobs 4` runs (`9/9` PASS, `2125/2154`, `convoScopeOk=True`) with identical participant status hashes before/after and clean post-acceptance `reconcile.py --check`.

## Hard rules

- One compiler-owned completeness graph/report; no GUI-only analyzer.
- GUI navigation/scaffolding targets canonical compact source through `ConvoTransaction`, never generated Lua.
- Preserve unrelated dirty work in `ProjectHoomans` exactly.
- No push, Workshop publication, or native Project Zomboid launch without explicit authorization.
