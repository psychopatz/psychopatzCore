# Progress — ConvoEngine / Semantic Harness

**Status:** DIRTY_RESUMABLE — S12/S12R2 implementation is technically verified, but the final Core swarm integration is still uncommitted. S13 is fully planned but must not begin until that durable closure commit exists.
**Branch:** existing `main` in all three repositories.
**Active phase:** S12 final durable commit boundary.
**Immediate Next Chunk:** review/stage/commit only the already-verified S12-owned Core integration and reconcile its six closure docs; then activate S13A.
**Planned next goal:** `S13_LAYOUT_NORMALIZATION_AND_DIRECTOR_ARCHITECTURE_FREEZE.md`.

## Why S13 exists

A post-S12 filesystem audit found physical split-system representations that
semantic closure did not prohibit:

- full EN/TL/etc realization corpora can still be embedded inside generated
  ConvoEngine Lua;
- canonical source uses multiple localization authoring shapes, including inline
  locale maps, `textSidecars`, `textTarget`, and mixed forms;
- ProjectHoomans currently generates both `Behavior/Scene/*` and
  `Behaviors/Director/Scene/*` from the same canonical behavior source;
- equivalent Beat/Beats Director projection must be audited;
- the future Conversation Director therefore needs a physical-layout contract
  before implementation so it does not institutionalize those duplicate
  projections.

Normative contracts now exist:

~~~text
CONVOENGINE_PHYSICAL_LAYOUT_AND_LOCALIZATION.md
CONVERSATION_DIRECTOR_ARCHITECTURE.md
S13_LAYOUT_NORMALIZATION_AND_DIRECTOR_ARCHITECTURE_FREEZE.md
~~~

Do not start S13 migration until the current S12 Core integration is durably
committed and participant worktrees are clean.

## Final S12 / S12R2 accepted participant vector

~~~text
psychopatzCore   S12R2 final closure commit on main (see HANDOFF.md phase_commit: self)
ProjectHoomans   3aaf15c5fa50fa96b3160d680d46ef38dc7faa11
DynamicTrading   bba5004f9a1bb45a093e3a39e045ff6f6bd2ab5a
~~~

Residual worktrees (all three repositories clean at closure):

~~~text
psychopatzCore   rows=0  sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=0  sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
DynamicTrading   rows=0  sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

## Canonical ConvoEngine v1 steady-state invariants

- Sole first-party schemas: `psychopatz.convo-engine.v1` (family/source), `psychopatz.convo-engine.package.v1` (package descriptor), `psychopatz.convo-engine.target-registry.v1` (`targets/pz_packages.json`), `psychopatz.convo-engine.naming-audit.v1` (naming/legacy audit). No v2 schemas exist.
- PSDL disposition: retired at caller/source zero; PSDL literals exist solely for historical negative-detection (`activeCurrentPsdlIdentityCount: 0`, `historicalNegativeDetectionCount: 263`). Zero compatibility shims, aliases, forwarding wrappers, or dual schema readers remain.
- Retained S12R1 470-family structural dataset modernization (`29` intentionally retained across `4` member-completely verified groups, `67` resolved, `0` open).

## Verified S12R2 closure evidence

- **S12R2A (member-complete retention proof):**
  - `_verify_retention_claim` enforces member-complete distinctness (`== len(member_records)`) for every `VALID_RETENTION_EVIDENCE_CODES` branch and requires a mechanically verified structural blocker (`nonParameterizableBy`: `runtimeBlockID` or `incompatibleAuthorityOrResponse`) for `NON_PARAMETERIZABLE_PREDICATES`.
  - `ui.suggestion.identity.{real,lie,rude}` encode distinct `invoke.speechAct` values (`DISCLOSE_IDENTITY`, `DECEIVE_IDENTITY`, `REFUSE_IDENTITY`) with 3/3 distinct tuples.
  - `social.greetings` (21 members) mechanically verifies `nonParameterizableBy=runtimeBlockID` (`distinctPredicates=21`, `distinctRuntimeBlockIDs=21`).
  - All 4 `INTENTIONALLY_RETAINED` groups (29 families) pass member-complete verification.
- **S12R2B (complete PSDL/API/registry retirement, semantic naming-audit hardening & closure gate):**
  - Retired all remaining active first-party PSDL identities across Core, ProjectHoomans, and DynamicTrading: `targets/pz_packages.json` -> `psychopatz.convo-engine.target-registry.v1` with fail-closed `TARGET_REGISTRY_SCHEMA` enforcement in `generation_ownership.py`; removed `render_convo_runtime_plan`, `migrate_legacy_text_identity`, `prepare_bucket_migration`, `canonical_family_spec_from_record`, `app.psdl_authoring*`, `"psdl"`/`"PSDL"` shard/root kinds, and internal `*_psdl_*` symbols; renamed PSDL-branded test/fixture files and reconciled `TEST_CLASSIFICATION.json`.
  - Replaced blanket path whitelists in `convo_engine_naming_audit.py` (`psychopatz.convo-engine.naming-audit.v1`) with per-line semantic classification (`activeCurrentPsdlIdentityCount == 0` required; `historicalNegativeDetectionCount == 263` tracked separately), wired into `convo_engine_integrity_audit.py`, `convo_engine_modernization_inventory.py`, and `testing/acceptance.py` (`convo_audit`).
  - Exposed fail-closed `modernization-inventory --closure` CLI gate and `convo.modernization_closure` operation (bounded 13-operation `OperationRegistry` preserved).
- **S12R2C (committed & reproducible generated model):**
  - `reconcile --check` clean from committed participant vector: `modelFingerprint=b989f64511baedd83aa44357b7668d20c1ac435200cbf79a297b9a6b5642f23d`, `desired=396` (`PsychopatzCore=72`, `ProjectHoomans=312`, `DTCommon=12`), `missing=0`, `drifted=0`, `stale=0`, `retired_present=0`, `ambiguous=0`, `clean=true`.
- **S12R2D (modernization closure, focused tests & stable-vector two-pass acceptance):**

~~~text
closureOk:                     true
catalogFamilyCount:            470
inventoryFamilyCount:          470
unknownOwnershipCount:           0
unclassifiedCount:               0
duplicateGroupCount:             4
legacySplitAuthorityCount:       0
openActionableFamilyCount:       0
openActionableGroupCount:        0
intentionallyRetainedCount:     29
intentionallyRetainedGroupCount: 4
resolvedCount:                  67
missingCompositionHookCount:     0
legacySchemaReaderCount:         0
activeCurrentPsdlIdentityCount:  0
historicalNegativeDetectionCount: 263

focused Core suites (20 suites): 113/113 PASS

canonical acceptance run 1:
9/9 suites, 2158/2187 cases, failed=4 (known unrelated baselines), skipped=25, allowedSkips=25, unclassifiedSkips=0, convoScopeOk=True

canonical acceptance run 2:
9/9 suites, 2158/2187 cases, failed=4 (known unrelated baselines), skipped=25, allowedSkips=25, unclassifiedSkips=0, convoScopeOk=True
~~~
