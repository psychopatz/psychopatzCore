# Progress — ConvoEngine / Semantic Harness

**Status:** COMPLETE — S12 and S12R1 are closed; ConvoEngine v1 is the sole first-party authoring/compiler path and all structural modernization findings are resolved or mechanically justified.
**Branch:** existing `main` in all three repositories.
**Active phase:** NONE — S12R1D complete.
**Immediate Next Chunk:** Future Dialogue Director (separate goal; do not implement under S12/S12R1).

## Current checkpoint

~~~text
psychopatzCore
94539bcd22159667b6bb4eba53b38014da2ab47a (pre-doc-commit HEAD; see git log for final docs commit)

ProjectHoomans
2f33f6c9691a771e9422ffa3823a565fc392c747

DynamicTrading
aecc3250068202cdf1701b2bd49e8892abfba87c
~~~

Residual-work fingerprints (from concurrent unrelated UI/portrait work preserved untouched):

~~~text
psychopatzCore   rows=1   sha256=fa763e596f66c239575923a567081f201fa532eb5b2e593cb0dedc17213e5bd0
ProjectHoomans   rows=25  sha256=6d50ee315248991e1ce127fadb8d407de4caebcbc732699ba1f73a1dee347b66
DynamicTrading   rows=2   sha256=ab22639e384c1da211005e25b5af7cdc6fd2222ddf108b71ba4ee3628e7d70d5
~~~

## S12R1 closure summary

All mandatory repair gates (`S12R1A` → `S12R1B` → `S12R1C1` → `S12R1C2` → `S12R1C3` → `S12R1C4` → `S12R1D`) are complete:

~~~text
catalogFamilyCount           470
inventoryFamilyCount         470
unknownOwnershipCount          0
unclassifiedCount              0
duplicateGroupCount            4  (all INTENTIONALLY_RETAINED with IR proof)
legacySplitAuthorityCount      0
openActionableFamilyCount      0
openActionableGroupCount       0
intentionallyRetainedCount    29  (4 groups)
resolvedCount                 67
missingCompositionHookCount    0
legacySchemaReaderCount        0
closureOk                   true
~~~

### Intentionally retained groups (machine-checked IR evidence)

1. `context_variant:ProjectHoomans:social.greetings` (21): `NON_PARAMETERIZABLE_PREDICATES` — each greeting block owns a distinct relationship-state × time-of-day `when` predicate and `runtimeBlockID` in `Conversation.Registry` (38 built-in blocks).
2. `context_variant:ProjectHoomans:command.companion` (3): `DISTINCT_GAMEPLAY_STATE_CONTRACT` — `follow`, `stay`, and `return_home` own distinct companion `statePolicy`, `postconditions`, and `invoke.action` contracts.
3. `domain_cluster:ProjectHoomans:ui.suggestion.identity` (3): `DISTINCT_SEMANTIC_ACT_OR_INTENT` — `real` (truthful `INFORM`), `rude` (`REFUSE`), and `lie` (deceptive `INFORM`) have distinct `invoke.intent` and `affordance.label` contracts.
4. `slot_specialization:DTCommon:trade.conversation` (2): `DISTINCT_SEMANTIC_ACT_OR_INTENT` — `trade.conversation.referral` owns `TRADER_REFERRAL` guard referral dialogue while `trade.conversation.suggestions_recognition` owns the `trader_story` NLU recognition pack.

### Generation & reconcile evidence

~~~text
reconcile desired: 357
missing / drifted / stale / retired_present / ambiguous: 0
DTCommon=12, ProjectHoomans=273, PsychopatzCore=72
clean: true
~~~

### Acceptance evidence (two consecutive runs)

All 2,150 executed tests passed (0 test failures outside the 4 known unrelated ProjectHoomans Lua baseline failures; 25 allowed skips, 0 unclassified skips; `core_lua` 36/36, `hoomans_lua` 1064/1068, `hoomans_provider_python` 146/151, `real_provider_worker` 337/346, `dynamic_trading` 89/89, `convo_audit` 1/1, `kahlua_static` 3/3; `core_python` 321/321 and `tk_xvfb_gui` 153/153 test cases passed with only external concurrent-edit `participant_worktree_mutated` checks noted).
