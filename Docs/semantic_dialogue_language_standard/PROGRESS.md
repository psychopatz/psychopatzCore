# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — post-R8 audit revoked USER_ACCEPTANCE. R8A is retained; R8D must repair acceptance side effects, then R9 must finish the originally planned Dialogue Completeness GUI before broad dialogue/beat rewriting.
**Branch:** existing `main` in all three repositories.
**Active phase:** S11R8D → S11R9.
**Immediate Next Chunk:** R8D only — make `real_provider_worker` and canonical acceptance effect-free against all live participant repos; then continue automatically through R9A-R9D.
**Content rewrite gate:** `BULK_DIALOGUE_REWRITE_ALLOWED=false`.

## Current planning checkpoint

~~~text
psychopatzCore   planning_doc_commit: self (base 9227ba6a97f0acbef8c6bf33067acb9582067442)
ProjectHoomans   dadfa01b88f957dbdeac68ce0b688130d3b175d7
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot (`git status --porcelain=v1 -uall` raw-byte SHA-256):

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=34  sha256=731b8c509b74bde3c57948b83252ddc0b6b4293405c3d1333ad835c2d688c462
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans has 34 unrelated concurrent NPC-authoring/editor/StartingCompanion residuals at this snapshot. Re-verify live status before each cross-repo phase; preserve divergence as concurrent work and never reset/stash/discard it.

Current repair authority:

`S11_POST_R8_AUTHORING_READINESS_REPAIR.md`

## Retained accepted work

Do not rebuild without targeted regression evidence:

- R8A native/worker `taskProjection` parity and `task_native_projection_parity`;
- original R8B Core source-isolation race repair;
- Core Python jobs=1/jobs=4 deterministic accounting;
- current Tk/Xvfb suite ownership;
- S11 canonical Identity / Needs / Greeting / companion-command migrations;
- quest/recruitment/proposal/event/disband/settlement/ambient regressions;
- canonical CodeBuilder source/recipe discipline;
- Dialogue Completeness Analyzer backend and constrained-family manifest.

## Post-R8 blockers

### R8D — acceptance is not effect-free

Two consecutive canonical runs are 9/9, but `real_provider_worker` mutates live DynamicTrading `Manifest.lua` and `Registry.lua`. The exact offending test is the pragmatic interaction beat promotion/regeneration test using temporary Core source with live adopter output roots.

R8D must make generation-bearing tests hermetic, add a participant status side-effect guard, rerun two 9/9 canonical passes from one exact vector, and run reconcile **after** acceptance.

### R9 — Dialogue Completeness Workbench is missing

The canonical analyzer exists and currently analyzes 520 families, but there are zero GUI callers. The primary Conversations pane does not expose the compiler completeness graph/report or first-class S11 state/repeat/closure controls.

The original S11 design required the same analyzer result to feed Semantic Lab and explicitly required the same graph/report to be exposed before broad content migration.

## Mandatory sequence

~~~text
R8D  acceptance side-effect isolation + exact-vector closure
  ↓
R9A  canonical authoring-report enrichment
  ↓
R9B  primary Dialogue Completeness Workbench
  ↓
R9C  complete semantic authoring controls + safe structural scaffolding
  ↓
R9D  Tk/Xvfb + canonical-report parity acceptance
  ↓
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

## Hard rules

- No broad dialogue/beat/behavior/realization rewrite before R9D.
- One compiler-owned completeness graph/report; no GUI-only analyzer.
- GUI navigation/scaffolding targets canonical compact source, never generated Lua.
- Structural scaffolding may create missing schema/branch skeletons but must not invent final prose or gameplay semantics.
- No compatibility shims, fallback completeness readers, dual source formats, or acceptance cleanup that hides side effects.
- Preserve unrelated dirty work exactly.
- Changed adopter repos commit first; Core documentation/handoff repo commits last.
- No push, Workshop publication, or native Project Zomboid launch without explicit authorization.
