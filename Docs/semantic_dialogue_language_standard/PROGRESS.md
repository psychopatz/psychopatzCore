# Progress — ConvoEngine / Semantic Harness

**Status:** USER_ACCEPTANCE — all developer-side S11 and S11R8 objectives are complete and accepted; ready for user-owned native Project Zomboid SP/MP acceptance.
**Branch:** existing `main` in all three repositories.
**Active phase:** USER_ACCEPTANCE (S11A-S11E + S11R8 ACCEPTED / CLOSED; R7 historical/superseded closure claim).

## Final developer-side checkpoint

~~~text
psychopatzCore   phase_commit: self (base 4aefefbbb643442f2e7811e722aab921f0ee6266)
ProjectHoomans   dadfa01b88f957dbdeac68ce0b688130d3b175d7
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=34  sha256=731b8c509b74bde3c57948b83252ddc0b6b4293405c3d1333ad835c2d688c462
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans has 34 unrelated concurrent NPC-authoring/editor/StartingCompanion residual paths preserved byte-for-byte without reset, stash, or absorption.

## S11R8 closure summary

- **R8A (Native task-state projection parity):** Replaced worker-only `Runtime.taskStates` with the shared bounded `taskProjection` contract (`PNC_SemanticTaskProjection.lua`) produced natively in `PNC_ConversationComposer_Context.lua` and `Input_ContextProjection.lua`, updated in `Input_Tasks.lua` and `Input_TaskDispatch.lua`, consumed by `Suggestions_Capabilities_Rows.lua`, and matched by the headless worker. Added `task_native_projection_parity` to `audit.task.parameterized` owned by `test_native_task_projection_parity_lifecycle_and_duplicate_suppression` (`tests/pnc_native_task_projection_parity_smoke.lua`).
- **R8B (Acceptance isolation + deterministic GUI/accounting):** Moved `test_psdl_semantic_domain_decomposition.test_real_source_variant_and_new_subdomain_are_local` into an isolated temporary root, moved Core `tkinter` startup tests (`test_gui_startup`) into `tk_xvfb_gui` so `core_python` runs headlessly with zero skips, and added accounting/ownership regressions in `test_compact_test_runners.py`.
- **R8C (Exact-vector final closure):** Verified `core_python` `jobs=1` and `jobs=4` (`307/307` PASS, `0` skips), two consecutive canonical 9-suite `--jobs 4` runs (`9/9` PASS, `convoScopeOk=true`), `reconcile.py --check` (`clean=true`, `desired=410`), caller-zero (`Flow_Identity`/`Flow_Needs`/`Flow_Greeting`), and `git diff --check`.
