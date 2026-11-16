# ConvoEngine Handoff

```yaml
status: "IN_PROGRESS"
checkpoint_mode: "committed_phase_handoff"
phase: "S10R — Semantic Harness acceptance integrity and reproducible closure"
chunk: "S10R2 — complete Feature Acceptance Registry public-surface discovery"
participant_vector: "psychopatz-core=<updating-on-S10R1-commit>;project-hoomans=fb4c43ce23ee0106f52dab931f12f817ddb9f991;dynamic-trading=9c8cb3dead56d66e32fccb901b9abd3dd6c2f393"
evidence: "S0-S9R_RETAINED; S10A_ACCEPTED; S10R1_COMPLETE_40_PLUS_2; S10R2_ACTIVE"
updated_at: "2026-11-16"
```

## Current truth

The previous S10D `USER_ACCEPTANCE` handoff is superseded.

S10A remains accepted: the exact PNC worker starts/restarts, `MAX_POOLS = 256` remains intact, the identity label/speech contract is enforced, canonical/generated names are bound into initiating speech, and focused real-worker/Tk acceptance is green.

Fresh audit reruns:

    S10A provider + label/speech                 8/8 PASS
    S10C real Tk/Xvfb journeys                  4/4 PASS
    S10D provider lifecycle                     3/3 PASS
    Feature Registry + acceptance-runner unit   8/8 PASS
    pnc_s10a_flow_preflight_smoke.lua                PASS

The developer-complete claim is reopened because the broader acceptance system is not yet trustworthy.

Normative repair design:

`Docs/semantic_dialogue_language_standard/S10_ACCEPTANCE_INTEGRITY_REPAIR.md`

Read `PROGRESS.md` last after the durable design/runbook files.

## Verified repair blockers

### 1. Deleted test responsibilities are not proven obsolete

ProjectHoomans commit `5f8b5000` deleted 12 provider test modules (~68 test methods). The Core dataset/workflow/adapter/interaction/variation APIs they exercised still exist and some remain public CLI/service surfaces.

Do not blindly restore historical tests. Build a responsibility ledger and either:

- migrate equivalent current-architecture acceptance; or
- retire the covered surface, remove callers/public exposure, and prove caller-zero.

### 2. Public CLI acceptance ownership is incomplete

Feature Registry discovery currently misses supported top-level argparse actions including:

    --list-datasets
    --search-datasets
    --show-dataset
    --validate-dataset
    --workflow-preview
    --workflow-generate
    --adapt-dataset
    --inspect-interaction-history

Fresh runtime evidence:

- `--list-datasets` advertises sources with `exists=false`;
- `--show-dataset common_dialogue` fails on missing `responses/common/social.json`;
- `--workflow-preview common_dialogue --workflow-blocks language.speech_act,dialogue_responses.response_pool` returns `ok=false` and exits 2.

Every remaining supported public action must work and have acceptance ownership, or be explicitly retired/deprecated and removed from the supported surface.

### 3. Canonical acceptance is not green

The canonical `--acceptance` workflow reports mandatory `hoomans_lua` FAIL.

The exact previous S10D Hoomans participant commit `9778522f` reruns at:

    1024/1029 PASS
    5 FAIL

Only `pnc_population_director_smoke.lua` is currently recognized as the reviewed known unrelated baseline. Other failures remain unexpected.

`convoScopeOk=true` is diagnostic only and cannot override a failed mandatory suite.

### 4. Prior S10D checkpoint was invalid

The superseded handoff used:

    psychopatz-core=<updating-on-S10D-commit>

and its Hoomans result did not reproduce from the exact recorded participant commit.

S10R final closure must use exact participant commits, exact phase identity and residual-work fingerprints. Dirty parallel work may be preserved but may not silently contribute to a committed acceptance result.

### 5. Lifecycle matrix is not manifest-complete

`test_s10d_provider_lifecycle.py` discovers presets but executes hard-coded current names. Replace that current-set assumption with manifest/preset-derived lifecycle ownership for every supported non-alias worker-bearing selection.

## Immediate responsibility — S10R1

1. Inventory the responsibilities of the 12 deleted provider test modules.
2. Map those responsibilities to current Core/Hoomans public/service callers.
3. For each responsibility, migrate current acceptance or formally retire the surface with caller-zero/public-removal proof.
4. Repair the stale dataset/workflow source discovery for any retained public operation.
5. Add focused tests proving retained public dataset/workflow/adapter/interaction surfaces work through current canonical sources.
6. Do not change S10A identity behavior unless a new failing regression proves it necessary.

After S10R1, continue automatically through S10R2-S10R4.

## Required continuation

    S10R1
      -> deleted/stale acceptance ownership
    S10R2
      -> complete Feature Acceptance Registry public-surface discovery
    S10R3
      -> genuinely green/reproducible nine-suite acceptance
    S10R4
      -> manifest-derived lifecycle matrix + final committed closure

Do not stop after one repaired CLI command, one restored test, or one green focused suite.

## Residual work safety

The participant vector above is a dirty snapshot, not a clean phase checkpoint.

The residual fingerprints are SHA-256 hashes of the current `git status --porcelain=v1 -uall` residual sets; for Core the active S10R-owned documentation paths are excluded so the fingerprint represents unrelated residual work.

Preserve all unrelated/concurrent changes. Re-inspect current Git state at startup because ProjectHoomans was receiving concurrent commits during this documentation repair.

Do not reset, stash, discard, broad-stage, amend, rebase, force-update, push, publish Workshop content, or launch native Project Zomboid.

At an accepted S10R phase boundary: stage exact phase-owned paths only, commit changed adopter repositories first, reconcile Core continuity docs, commit Core last, verify participant vector/residual fingerprints, then continue.
