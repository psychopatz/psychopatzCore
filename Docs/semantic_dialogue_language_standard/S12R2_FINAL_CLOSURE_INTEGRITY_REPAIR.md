# S12R2 — Final Closure Integrity Repair

**Status:** NORMATIVE ACTIVE REPAIR
**Date:** 2026-11-19
**Parent goal:** `S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md`
**Retained implementation record:** `S12R1_STRUCTURAL_DATASET_MODERNIZATION_CLOSURE_REPAIR.md`
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Participants:** ProjectHoomans, DynamicTrading/DTCommon
**Authoring standard:** `DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md`

## Purpose

S12R2 is a narrow final-closure repair.

Do **not** reopen the accepted S12R1 structural modernization. The post-R1 audit
verified that the expensive dataset work is real:

- the maintained catalog was reduced from 587 to 470 families;
- large weapon/tone/context/state specialization clusters were actually
  collapsed into reusable families;
- Hoomans integration/context variants were consolidated;
- behavior/beat composition hooks were added;
- current inventory reports no open actionable family/group and no missing
  behavior/beat hook;
- current full semantic acceptance remains functionally green.

S12R2 exists because the *proof of closure* is still weaker than the
implementation it is trying to certify.

The remaining blockers are:

1. group-level retention verification can approve a partially indistinct group;
2. the `NON_PARAMETERIZABLE_PREDICATES` verifier proves predicate difference,
   not actual non-parameterizability;
3. closure mode is not exposed as the canonical operator-facing inventory gate;
4. active first-party ConvoEngine APIs/help/internal contract names still carry
   project-owned PSDL-era identities despite the pre-release direct-migration
   rule;
5. final generated whole-model fingerprints are correct only in the dirty
   worktree, not in the committed participant vector;
6. final continuity documents and recorded reconcile/vector evidence are stale
   or contradictory.

Do not implement the future Dialogue Director until S12R2 is accepted.

## Audited checkpoint

At S12R2 planning time:

~~~text
psychopatzCore
43a02e3dad695f65d251ff137765d83e8b00d912

ProjectHoomans
4dce40499d62e9f54836a4b4c2df37f4b8b08656

DynamicTrading
aecc3250068202cdf1701b2bd49e8892abfba87c
~~~

The worktrees contain concurrent unrelated UI/editor work. Preserve it exactly.

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

Known S12-owned dirty generated paths that are **not** unrelated portrait/editor
work:

~~~text
psychopatzCore:
Contents/mods/PsychopatzCore/common/media/lua/shared/
PsychopatzCore/ConvoEngine/FoundationRegistry.lua

DynamicTrading:
Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Manifest.lua
Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Registry.lua
~~~

They contain the desired current whole-model fingerprint:

~~~text
bfcc2d3b251785f9ef35f347cf93754103b33c119fd45de0090b64a53a280fb7
~~~

while the committed versions still contain older fingerprints.

Do not discard those changes as unrelated dirt.

## Fresh audit evidence

Current live modernization inventory:

~~~text
catalogFamilyCount           470
inventoryFamilyCount         470
unknownOwnershipCount          0
unclassifiedCount              0
duplicateGroupCount            4
legacySplitAuthorityCount      0
openActionableFamilyCount      0
openActionableGroupCount       0
intentionallyRetainedCount    29
intentionallyRetainedGroupCount 4
resolvedCount                 67
missingCompositionHookCount    0
legacySchemaReaderCount        0
closureOk                   true
~~~

Current reconcile:

~~~text
desired            396
PsychopatzCore      72
ProjectHoomans     312
DTCommon            12

missing              0
drifted              0
stale                0
retired_present      0
ambiguous            0
clean              true
~~~

Fresh focused R1 audit tests:

~~~text
26 / 26 PASS
~~~

Fresh canonical acceptance, twice:

~~~text
9 / 9 suites
2150 / 2179 cases
4 known unrelated ProjectHoomans Lua baseline failures
25 allowed skips
0 unclassified skips
convoScopeOk=true
~~~

The functional system is therefore stable. S12R2 is about truthful closure,
not another broad content rewrite.

# S12R2A — Make retention proof member-complete

## Problem

Current `DISTINCT_SEMANTIC_ACT_OR_INTENT` verification accepts a group whenever:

~~~text
number of distinct act/intent/subject tuples > 1
~~~

That is insufficient for groups with more than two members.

Current example:

~~~text
ui.suggestion.identity.real
  intent=INFORM
  subject=IDENTITY

ui.suggestion.identity.lie
  intent=INFORM
  subject=IDENTITY

ui.suggestion.identity.rude
  intent=REFUSE
  subject=IDENTITY
~~~

The current verifier reports:

~~~text
distinctActs=2
~~~

and nevertheless approves all three members as `INTENTIONALLY_RETAINED`.

That proves only that the group contains *some* semantic difference. It does not
prove that each member must remain separate.

The human retention reason additionally claims truthful versus deceptive
identity semantics, but that distinction is not represented in the semantic
fields currently verified.

## Required repair

Retention verification must prove every retained member/equivalence class.

For each evidence code, define a mechanically checkable criterion that is
sufficient for an N-member group.

At minimum:

- `DISTINCT_SEMANTIC_ACT_OR_INTENT` must not approve a 3-member group when only
  two semantic tuples exist unless the members sharing a tuple have another
  verified semantic distinction;
- `NON_PARAMETERIZABLE_PREDICATES` must prove why the predicate difference
  cannot safely become bounded runtime context, rather than merely proving
  predicate strings/IR differ;
- `DISTINCT_GAMEPLAY_STATE_CONTRACT` must prove the retained members own
  meaningfully incompatible state/action/result contracts;
- `SELECTION_SEMANTICS_LOSS` must prove the actual selection contract that would
  be lost by a collapse;
- blanket reason text remains insufficient.

For identity:

- if truthful versus deceptive identity is a real semantic distinction, encode
  it in canonical ConvoEngine semantics and verify it;
- otherwise collapse/parameterize the overlapping `real`/`lie` semantics as
  appropriate;
- do not encode the distinction only in a retention reason or UI label.

For social greetings:

- audit whether relationship-state × time-of-day can be represented by one
  reusable semantic greeting family plus bounded runtime predicate/context
  selection and realization;
- if it can, modernize it;
- if it cannot under the current semantic/runtime contract, encode and verify
  the concrete incompatibility;
- `distinctPredicates > 1` alone is not proof of non-parameterizability.

Add regression tests including:

~~~text
3 retained members
2 distinct semantic tuples
=> retention must fail unless the third distinction is independently verified
~~~

and a predicate group where predicates differ but are demonstrably
parameterizable.

### S12R2A gate

- every `INTENTIONALLY_RETAINED` member has sufficient machine-checkable proof;
- partial-group distinctness cannot green an entire group;
- identity group is resolved or correctly modeled;
- social-greeting retention is resolved or actually proven non-parameterizable;
- no new broad dataset rewrite is introduced.

# S12R2B — Finish PSDL/API retirement and expose closure as a first-class gate

## Preserve

The actual first-party source-schema gate is already correct:

~~~text
SUPPORTED_SOURCE_SCHEMAS = {
  psychopatz.convo-engine.v1
}
~~~

Legacy source input remains rejected. Do not reintroduce a compatibility reader.

The implementation files already renamed to `convo_engine_*` are also retained.

## Remaining active identity cleanup

Audit exact current callers/exports/help text for project-owned PSDL-era
ConvoEngine identities, including:

~~~text
PSDL_COMPILED_SCHEMA
PSDL_KINDS
PSDL_DOCUMENT_FIELDS
PSDL_RECORD_FIELDS

render_psdl_runtime_plan
render_psdl_director_plan
render_psdl_semantic_pack_plan
render_psdl_ui_plan
render_psdl_realization_plan
render_psdl_flow_plan
render_psdl_response_pool_plan

expand_compact_psdl_document

psychopatz.psdl.portable-plan.v1
psychopatz.psdl.provenance.v1
psychopatz.psdl.target.v1
psychopatz.psdl.semantic-trace.v1

"Canonical PSDL record ID"
"Progressive-disclosure PSDL record inspection"
"Unknown PSDL record ID"
other active ConvoEngine CLI/help/error strings
~~~

These are not automatically all defects merely because the token `psdl`
appears. Negative tests/audits may intentionally mention retired names.

The rule is:

> if the identifier is a current first-party ConvoEngine contract/API/help
> identity, rename it directly to ConvoEngine terminology and update callers;
> if it exists only to detect/reject historical input, keep it explicitly as
> negative audit/test data.

No forwarding wrapper.
No alias export.
No deprecated compatibility symbol.

Do not bump to v2 merely to rename a pre-release project-owned contract.

## Migration-only operations

Audit `migrate-bucket` and any other migration-only path.

If no maintained first-party source requires that operation and no explicit
external/public compatibility boundary exists, retire it and its positive
migration-only workflow tests after caller-zero.

Negative tests that prove old source is rejected may remain.

## First-class closure command

The canonical operator-facing modernization command must be able to run closure
mode directly.

Implement one clear path such as:

~~~text
modernization-inventory --closure
~~~

or an equivalent `convo.modernization_closure` operation.

It must:

- invoke `build_modernization_inventory(..., closure=True)`;
- expose the closure summary;
- return failure/nonzero status when `closureOk=false`;
- be used by final S12 acceptance;
- not require a developer to import Python manually.

Update operation descriptions/help from “S12B classification inventory” to the
current steady-state ConvoEngine modernization/closure role where appropriate.

### S12R2B gate

- no current first-party ConvoEngine public/internal contract is needlessly
  PSDL-branded;
- no alias/wrapper layer preserves renamed API names;
- negative historical literals remain only where useful;
- migration-only positive reader workflows are deleted if caller-zero;
- one canonical CLI/operation closure gate fails closed.

# S12R2C — Reconcile and commit the exact generated model

The current dirty generated whole-model fingerprints are S12-owned.

Do not reset or discard them.

First re-derive generation from current canonical source and verify the exact
desired fingerprint/count.

Current audit-time desired state is:

~~~text
modelFingerprint =
bfcc2d3b251785f9ef35f347cf93754103b33c119fd45de0090b64a53a280fb7

desired=396
Core=72
Hoomans=312
DTCommon=12
~~~

These numbers are audit evidence, not hardcoded future expectations. Re-derive
them after R2A/R2B because legitimate changes may alter them.

Then:

1. reconcile/apply only through CodeBuilder generation;
2. verify no missing/drifted/stale/retired/ambiguous outputs;
3. stage only S12R2-owned generated paths;
4. preserve all unrelated portrait/editor/radio work;
5. commit adopter generated changes first;
6. commit Core generated/tool changes after adopters;
7. record exact participant HEADs and exact residual-work fingerprints.

A clean reconcile against a dirty worktree is not enough. A clean checkout of
the committed participant vector must reproduce the same desired ConvoEngine
model.

### S12R2C gate

- all required ConvoEngine generated outputs are committed;
- committed whole-model fingerprints match current source;
- clean-checkout-equivalent reconcile is clean;
- no required generated artifact is hidden in residual unrelated dirt;
- unrelated concurrent work is preserved exactly.

# S12R2D — Final reproducible closure and continuity rewrite

Run final closure only after R2A-C pass.

Required:

~~~text
closureOk = true

openActionableFamilyCount = 0
openActionableGroupCount = 0
legacySplitAuthorityCount = 0
missingCompositionHookCount = 0
legacySchemaReaderCount = 0
unknownOwnershipCount = 0
unclassifiedCount = 0
~~~

All retained groups must pass the stronger member-complete verifier.

Also require:

- focused Core/R2 tests green;
- provider/adopter tests green;
- real Tk/Xvfb acceptance green;
- integrity/determinism clean;
- reconcile clean from the committed participant vector;
- two consecutive canonical nine-suite acceptance runs;
- no semantic participant mutation;
- if unrelated concurrent work changes during acceptance, rerun from a stable
  exact participant/residual vector before claiming closure;
- exact participant HEADs and residual fingerprints recorded after all final
  commits.

Then rewrite all current status surfaces to one truth:

~~~text
ROADMAP.md
PROGRESS.md
HANDOFF.md
S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md
S12R1_STRUCTURAL_DATASET_MODERNIZATION_CLOSURE_REPAIR.md
S12R2_FINAL_CLOSURE_INTEGRITY_REPAIR.md
~~~

At that point:

- S12 parent may become COMPLETE;
- S12R1 becomes HISTORICAL / IMPLEMENTED;
- S12R2 becomes COMPLETE / ACCEPTED;
- exactly one next responsibility may point to a future Dialogue Director goal.

Do not mark the Dialogue Director as active within this repair.

# Mandatory execution order

~~~text
S12R2A
retention-proof correctness

→ S12R2B
PSDL/API retirement + first-class closure command

→ S12R2C
reconcile/commit exact generated model

→ S12R2D
stable-vector acceptance + final documentation closure
~~~

Continue automatically through all phases.

Do not stop after one green inventory report, one naming pass, one generated
commit, or one acceptance run.

# Git and safety rules

- verify current HEAD/status before every repository edit;
- preserve unrelated dirty work exactly;
- never reset, stash, discard, or absorb concurrent changes;
- stage exact phase-owned paths only;
- cross-repo accepted commits: adopters first, Core last;
- local commits are required at accepted phase boundaries;
- do not push;
- do not publish Workshop content;
- do not launch native Project Zomboid without explicit authorization.
