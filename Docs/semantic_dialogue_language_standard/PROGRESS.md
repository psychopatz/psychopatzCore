# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — S12 structural modernization is retained, but final closure is reopened under S12R2 because retention proof, PSDL/API retirement, generated-state commit integrity, and continuity evidence are not yet sufficient.
**Branch:** existing `main` in all three repositories.
**Active phase:** S12R2 — Final Closure Integrity Repair.
**Immediate Next Chunk:** S12R2A — make `INTENTIONALLY_RETAINED` verification member-complete and resolve/re-prove the identity and social-greeting groups.
**Dataset rewrite gate:** broad S12R1 structural modernization is accepted/frozen; only evidence-driven R2A corrections to still-unproven retained groups are allowed.

## Planning audit vector

~~~text
psychopatzCore pre-documentation audit baseline
43a02e3dad695f65d251ff137765d83e8b00d912

ProjectHoomans
4dce40499d62e9f54836a4b4c2df37f4b8b08656

DynamicTrading
aecc3250068202cdf1701b2bd49e8892abfba87c
~~~

The current Core documentation checkpoint is the commit containing this file; derive its exact SHA from Git rather than storing a self-invalidating predicted hash here.

Current worktrees contain concurrent unrelated UI/editor work.

Planning-time status fingerprints:

~~~text
psychopatzCore
rows=8
sha256=acc8d627aa8a52635af59c0aabe217c1314162dd87f3933cd21eb4f1307985d6

ProjectHoomans
rows=6
sha256=775bc6567f904a09a6c699fe0028aeb1e2be7bb0491770ab6b482cf1fdebc36e

DynamicTrading
rows=2
sha256=ab22639e384c1da211005e25b5af7cdc6fd2222ddf108b71ba4ee3628e7d70d5
~~~

Preserve unrelated changes exactly.

Known S12-owned dirty generated files that must not be classified as unrelated:

~~~text
PsychopatzCore/ConvoEngine/FoundationRegistry.lua
DTCommon/ConvoEngine/Manifest.lua
DTCommon/ConvoEngine/Registry.lua
~~~

## Accepted and retained from S12R1

- maintained family count reduced from 587 to 470;
- major redundant Hoomans specialization/context families actually collapsed;
- Core/Hoomans/DT structural modernization is substantially implemented;
- behavior/beat composition hooks are implemented;
- ConvoEngine v1 is the sole accepted first-party source schema;
- old implementation modules were directly renamed to `convo_engine_*`;
- no source-schema compatibility reader is accepted;
- split conversational authority remains zero;
- current runtime/provider/GUI behavior is stable.

Fresh audit evidence:

~~~text
inventory families:               470
openActionableFamilyCount:          0
openActionableGroupCount:           0
legacySplitAuthorityCount:          0
missingCompositionHookCount:        0
legacySchemaReaderCount:            0

focused R1 audit tests:
26/26 PASS

canonical acceptance run 1:
9/9 suites
2150/2179 cases
convoScopeOk=true

canonical acceptance run 2:
9/9 suites
2150/2179 cases
convoScopeOk=true
~~~

## Why final closure is reopened

1. `DISTINCT_SEMANTIC_ACT_OR_INTENT` currently approves an N-member retained
   group when only more than one distinct tuple exists. The 3-member
   `ui.suggestion.identity` group has only 2 distinct intent/subject tuples, so
   the whole group is not fully machine-proven.
2. `NON_PARAMETERIZABLE_PREDICATES` currently proves only that predicates differ,
   not why they cannot be represented as bounded runtime context. The 21-member
   social-greeting retention therefore needs stronger evidence or modernization.
3. closure mode exists in direct Python (`closure=True`) but is not exposed as a
   canonical fail-closed CLI/operation gate.
4. active project-owned PSDL-era ConvoEngine API/help/contract identities remain,
   including `render_psdl_*`, `PSDL_*`, PSDL CLI/help/errors, and several
   `psychopatz.psdl.*` internal contract schemas.
5. current reconcile is clean only with S12-owned generated whole-model
   fingerprint changes still uncommitted in Core and DTCommon.
6. closure docs record stale reconcile/vector truth (`desired=357` while current
   audit reports `desired=396`) and disagree on COMPLETE versus REOPENED/ACTIVE.

## Mandatory repair sequence

~~~text
S12R2A  member-complete retention proof
  ↓
S12R2B  PSDL/API retirement + first-class closure command
  ↓
S12R2C  reconcile and commit exact generated model
  ↓
S12R2D  stable-vector two-pass acceptance + final continuity rewrite
~~~

Normative repair:
`S12R2_FINAL_CLOSURE_INTEGRITY_REPAIR.md`

Do not start the future Dialogue Director until S12R2D is accepted.
