# S12R1 — Structural Dataset Modernization Closure Repair

**Status:** NORMATIVE ACTIVE REPAIR
**Date:** 2026-11-19
**Parent goal:** `S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md`
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
**Participants:** ProjectHoomans, DynamicTrading/DTCommon
**Authoring standard:** `DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md`

## Why S12 was reopened

The post-S12 implementation audit verified that the agent produced real and useful
foundation work, but the completion claim exceeded the implemented scope.

Retain as accepted foundation:

- all maintained canonical conversation sources/packages use ConvoEngine v1;
- `command.camp` is the sole CAMP conversation authority;
- the split-action authority audit is green;
- Semantic Lab health-scope clarification is implemented;
- the machine-readable modernization inventory exists and covers all maintained
  families;
- broad roles/slots/topic/event/activity/memory/domain metadata enrichment is
  useful and must not be reverted merely to redo the work;
- CodeBuilder reconcile, integrity and deterministic generation are clean;
- two fresh full acceptance runs from the exact final audited vector passed 9/9
  suites with `convoScopeOk=true`.

S12 is nevertheless incomplete because:

1. the modernization inventory still reports actionable structural work after
   S12C-E;
2. S12C-E mostly appended metadata rather than collapsing/merging/parameterizing
   the families the inventory itself says should change;
3. the final closure gate only proves every family received a classification;
   it does not prove actionable classifications were resolved;
4. behavior/beat composition-readiness recommendations remain open;
5. old project-owned PSDL/legacy schema readers and PSDL-named compiler/inspection
   modules remain active first-class dependencies despite the unreleased
   direct-migration/no-shim policy;
6. final continuity documentation contradicts itself.

This repair does **not** reopen the accepted S11 foundation or the useful S12
schema/source migration, CAMP cleanup, metadata additions, inventory mechanism,
or green runtime tests.

## Audited checkpoint

~~~text
psychopatzCore
bfb10f0a60ac611fc7902bfa46df45179eeba605

ProjectHoomans
ebbf113d5acbaf505f2c157d9c0a24454ba212b7

DynamicTrading
2b0c3cb5b2371aff1a5837361f44916fda59d081
~~~

All three worktrees were clean at audit close:

~~~text
rows=0
sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

Fresh audit acceptance from this exact vector, twice:

~~~text
9/9 suites
2145/2174 cases
4 known unrelated ProjectHoomans Lua baseline failures
25 allowed skips
0 unclassified skips
convoScopeOk=true
~~~

Fresh generation evidence:

~~~text
family files: 587
deterministic generated files: 408
integrity violations: 0
split-authority violations: 0
determinism diffs: 0

reconcile desired: 411
missing: 0
drifted: 0
stale: 0
retired_present: 0
ambiguous: 0
~~~

## Current structural backlog discovered by the accepted inventory

At audit time the live inventory reported:

~~~text
catalogFamilyCount        587
inventoryFamilyCount      587
unknownOwnershipCount       0
unclassifiedCount           0
duplicateGroupCount         30
splitAuthorityCount          0

STATIC_LITERAL            287
CONTEXT_VARIANT           140
REALIZATION_ONLY          126
REDUNDANT_SPECIALIZATION   44
SLOT_PARAMETERIZABLE       33
ARCHETYPE_MEMBER           30
DOMAIN_ACTION               8
BEAT_COMPONENT              3
~~~

The most important repair invariant is:

> An actionable inventory recommendation is not completion evidence. It is work
> to resolve, or a claim to justify.

S12 may close only when every actionable finding is in one of two states:

~~~text
RESOLVED
  the source structure was actually modernized and the finding disappeared

INTENTIONALLY_RETAINED
  the distinction is semantically necessary and a machine-checkable justification
  proves why collapse/parameterization/realization merge would be incorrect
~~~

Anything else remains:

~~~text
OPEN
~~~

and blocks S12 closure.

## S12R1A — Make the inventory a closure authority

Upgrade the existing modernization inventory; do not create a second manual
semantic registry.

The inventory must continue deriving the family/group facts from canonical
source/compiler evidence, but it also needs a bounded resolution model for each
actionable finding.

At minimum distinguish:

~~~text
OPEN
RESOLVED
INTENTIONALLY_RETAINED
~~~

For `INTENTIONALLY_RETAINED` require machine-checkable evidence, not prose-only
waivers. The justification must identify the semantic distinction that makes
the families legitimately different, for example:

- different gameplay/state transition contract;
- different semantic act/intent/subject;
- incompatible role/cardinality contract;
- incompatible predicate/state admission semantics;
- intentionally separate domain authority;
- a realization merge would lose semantically meaningful selection constraints.

Do not allow a blanket owner/domain waiver.

Do not let `STATIC_LITERAL` be an unconditional catch-all that makes
`unclassifiedCount==0` meaningless. Add confidence/reason evidence sufficient
to distinguish genuinely static content from “classifier did not recognize a
modernization pattern.”

Add a **closure mode** or equivalent audit summary that fails while actionable
records/groups are `OPEN`.

Required final summary dimensions include at least:

~~~text
openActionableFamilyCount
openActionableGroupCount
intentionallyRetainedCount
resolvedCount
legacySplitAuthorityCount
missingCompositionHookCount
legacySchemaReaderCount
~~~

S12F must consume this closure authority.

### S12R1A gate

- every maintained family still has derived classification;
- every actionable family/group has a resolution state;
- no silent fallback can satisfy closure;
- intentional retention requires concrete machine-checkable semantic evidence;
- tests prove an unresolved duplicate/specialization causes closure failure;
- tests prove a justified intentional distinction can remain without hiding an
  unrelated open group;
- no hand-maintained second semantic registry.

## S12R1B — Retire pre-release legacy schema/compiler compatibility

Current first-party canonical source migration is accepted and must be preserved.

Now finish the unreleased direct-migration policy.

Audit exact callers for active project-owned legacy surfaces including:

~~~text
LEGACY_PSDL_SCHEMA
PSDL_SCHEMA
SUPPORTED_SOURCE_SCHEMAS
allow_legacy_schema
allowLegacySchema

psdl_compact.py
psdl_compiler.py
psdl_inspect.py
psdl_authoring_audit.py
convo_engine_psdl_inventory.py

compiler.psdl_inspect
PSDL-named CLI/help/API/test identities
psychopatz.psdl.v2
psychopatz.psdl.package.v2
psychopatz.semantic.dialogue-language.v1
~~~

The target is not to delete generic semantic capability. It is to make
ConvoEngine v1 the sole first-party authoring/compiler path.

Where a currently PSDL-named module is the actual ConvoEngine implementation,
rename it directly to a descriptive ConvoEngine name and update every caller in
the same phase.

Examples, subject to exact current evidence:

~~~text
psdl_compiler.py
→ convo_engine_compiler.py

psdl_compact.py
→ convo_engine_compact.py

psdl_inspect.py
→ convo_engine_inspect.py

psdl_authoring_audit.py
→ convo_engine_authoring_audit.py

convo_engine_psdl_inventory.py
→ a descriptive legacy-name / migration audit name only if that audit still
  has a justified steady-state purpose
~~~

No forwarding wrapper.
No import alias module.
No dual-schema fallback.
No deprecated compatibility shim.

If a migration-only operation has no remaining first-party source/caller after
S12 schema convergence, delete the operation and its migration-only tests rather
than keeping a permanent old-schema reader “just in case.”

Preserve negative regression tests that prove old first-party schemas are
rejected; those tests must not require keeping the old parser as a supported
reader.

### S12R1B gate

- canonical source/package remains ConvoEngine v1;
- old first-party schema input is rejected, not accepted through an opt-in flag;
- no production/default compiler path has `allow_legacy_schema=true`;
- no project-owned legacy schema belongs to the supported source-schema set;
- PSDL-named implementation modules are directly renamed/deleted where they are
  actually ConvoEngine implementation;
- old operation/help/API identities reach caller-zero;
- no shim or alias layer remains;
- full compiler/CodeBuilder/Studio tests green.

## S12R1C — Resolve the structural dataset backlog

Process the existing inventory by coherent semantic groups, not by file count.

Do **not** repeat the metadata-only pass. Existing useful roles/slots/hooks should
be reused.

For every actionable group:

1. inspect the actual semantic differences and all runtime/test callers;
2. decide whether the correct outcome is `RESOLVED` or
   `INTENTIONALLY_RETAINED`;
3. if resolved:
   - collapse redundant contextual families into runtime predicates/slots;
   - collapse entity/weapon/gender/etc. specialization into typed slots;
   - move wording/tone-only differences into realization variants;
   - parameterize reusable semantic context;
   - expose real typed topic/event/activity/memory/domain hooks where those
     concepts drive composition;
   - delete superseded source only after parity and caller/reference zero;
4. if intentionally retained:
   - prove the semantic distinction mechanically;
5. run affected analysis/family tests;
6. reconcile generated output;
7. commit coherent adopter batches locally.

Priority backlog from the audit includes, but is not limited to:

~~~text
ProjectHoomans social.greetings time/relationship variants

combat.kill weapon/personality specialization

combat.horde prompt/ack/choice variants

question.backstory.known facet variants

medical.distress call/repeat/update variants

needs offer/proposal/quantity variants

companion-dog gender specialization

flow.greeting opening/followup realization pools

ProjectALife / Bandits / NecroA context variants

combat tactical-spatial realization pools

DTCommon trade.conversation specialization group
~~~

Do not assume the heuristic is always correct. A group may be retained if the
semantic contract truly differs, but the audit must record a concrete reason.

### Behavior / beat composition readiness

The current inventory still recommends `preserve_and_expose_director_hooks_and_roles`
for all behavior/beat families.

Audit each behavior and beat. Where a topic/event/activity/memory/domain
reference is part of its intended discoverability/composition contract, expose
that typed hook rather than leaving empty generic metadata.

Do not invent meaningless hooks simply to make a counter zero. The closure
authority must distinguish:

~~~text
hook required and present
hook not semantically applicable, justified
hook required and missing
~~~

S12 prepares the dataset for a later Dialogue Director; it does not implement
that director.

### Owner order

Use coherent semantic batches and commit changed adopters before Core continuity
updates.

Suggested ordering:

~~~text
S12R1C1  PsychopatzCore actionable groups
S12R1C2  ProjectHoomans actionable groups
S12R1C3  DynamicTrading/DTCommon actionable groups
S12R1C4  behavior/beat composition-readiness sweep
~~~

Continue automatically through all mandatory batches.

## S12R1D — Reproducible closure

S12 is not complete merely because ordinary tests are green.

Final closure requires:

~~~text
openActionableFamilyCount = 0
openActionableGroupCount = 0
legacySplitAuthorityCount = 0
missingCompositionHookCount = 0
legacySchemaReaderCount = 0
unknownOwnershipCount = 0
unclassifiedCount = 0
~~~

Any `INTENTIONALLY_RETAINED` records must have machine-checkable semantic
justification and must appear in the final report.

Also require:

- all current canonical family/package schemas are ConvoEngine v1;
- no project-owned compatibility shim/alias remains;
- one semantic interaction/action has one family conversational authority;
- CodeBuilder reconcile clean;
- integrity/determinism clean;
- affected/family/provider tests green;
- full retained acceptance suites green;
- two consecutive canonical acceptance runs from one exact participant vector;
- exact final participant HEADs recorded;
- exact residual-work fingerprints recorded;
- documentation has one consistent status and exactly one immediate next chunk;
- no native Project Zomboid launch without explicit user authorization.

## Documentation closure

When S12R1D passes, rewrite rather than append stale truth in:

~~~text
ROADMAP.md
PROGRESS.md
HANDOFF.md
S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md
S12R1 structural repair document
~~~

Historical phase details belong in Git history, not duplicated contradictory
“current” sections.

## Stop condition

This is a full-roadmap repair.

Do not stop after S12R1A, R1B, one content group, one repository, or a green
test run.

Continue:

~~~text
S12R1A
→ S12R1B
→ S12R1C1
→ S12R1C2
→ S12R1C3
→ S12R1C4
→ S12R1D
~~~

unless there is a genuine architecture blocker, authorization conflict, or
explicit user-owned native-game acceptance gate.

Do not implement the future autonomous Dialogue Director during this repair.
