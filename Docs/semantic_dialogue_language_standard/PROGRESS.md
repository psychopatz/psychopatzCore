# Progress — ConvoEngine / Semantic Harness

**Status:** IN_PROGRESS — R8D remains accepted, but the post-R9 usability audit reopened authoring readiness under S11R9R1.
**Branch:** existing main in all three repositories.
**Active phase:** S11R9R1 — Workbench usability, full-family authoring-health coverage, and legacy retirement.
**Immediate Next Chunk:** R9R1A — synchronize editor/Workbench selection and extend canonical authoring-health inventory from 520 dialogue families to all 588 maintained dialogue/behavior/beat/realization families.
**Content rewrite gate:** BULK_DIALOGUE_REWRITE_ALLOWED=false.

## Current planning checkpoint

~~~text
psychopatzCore   planning_doc_commit: self (base 097ae97a425b6cecd88a7bdac5c36077e57510e0)
ProjectHoomans   77994e19dccc5a4d94579b480fd24f3db8e68979
DynamicTrading   0fcf35196452db0675788167df205aec09748caa
~~~

Residual snapshot, raw git status porcelain SHA-256:

~~~text
psychopatzCore   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
ProjectHoomans   rows=34  sha256=731b8c509b74bde3c57948b83252ddc0b6b4293405c3d1333ad835c2d688c462
DynamicTrading   rows=0   sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
~~~

ProjectHoomans has 34 unrelated concurrent NPC-authoring/editor/StartingCompanion residuals at this snapshot. Re-verify live status before every cross-repo phase and preserve divergence as concurrent work.

Current repair authority:

S11_POST_R9_WORKBENCH_USABILITY_REPAIR.md

## Retained accepted evidence

- R8D acceptance isolation and participant side-effect guard are accepted.
- Two canonical 9-suite runs were reproducibly green and effect-free at the R9 checkpoint.
- The canonical Dialogue Completeness Analyzer remains the one semantic graph authority.
- R9A report enrichment is retained.
- S11 Semantic Controls and structural scaffold services are retained.
- Existing R9 unit and Tk/Xvfb tests remain useful baseline evidence.

## Why R9 is reopened

The current Workbench is wired to the canonical analyzer but does not yet meet the authoring-readiness goal for the planned bulk rewrite.

Verified gaps:

- canonical catalog: 588 maintained families = 520 dialogue + 30 behavior + 3 beat + 35 realization;
- current health report: 520 dialogue only; 68 maintained non-dialogue families are absent;
- main editor and Workbench selection can disagree;
- GREEN/ORANGE/etc. are only text prefixes, not actual row styling;
- default view is all/alphabetical rather than needs-attention/severity first;
- Open affected field does not focus the exact editor control;
- Run family tests is not wired into ConvoEngineAuthoringPane;
- scaffolding remains available for healthy families;
- graph view is compiler-first rather than human-first;
- legacyDatasetsPresent is incorrectly true for active canonical/pattern/WordNet sources while list_dialogue_content returns 0 records;
- obsolete legacy surfaces/toggles remain and require parity/caller-zero retirement.

The current strict dialogue report still has one real warning:

~~~text
command.camp
stale_poststate_risk
~~~

This warning should be immediately visible in the redesigned default Workbench view.

## Mandatory sequence

~~~text
R9R1A  correctness + all-588-family authoring health
  ↓
R9R1B  problem-first visual UX and real color coding
  ↓
R9R1C  exact navigation, tests, contextual repair workflow
  ↓
R9R1D  legacy/redundant surface retirement
  ↓
R9R1E  unit + real Tk usability acceptance
  ↓
BULK_DIALOGUE_REWRITE_ALLOWED=true
~~~

## Hard rules

- Do not begin the broad dialogue/beat/behavior/realization rewrite during R9R1.
- Keep one compiler-owned authoring-health model; no Tk-only semantic analyzer.
- Real semantic colors must be supplemental to text/icon health labels.
- Healthy families must not expose arbitrary active repair controls.
- Delete retired project-owned UI after parity + caller-zero; do not preserve wrappers/shims.
- Preserve useful current functions even when their current container has a legacy label; move/rename before deleting the old container.
- Preserve unrelated dirty work exactly.
- No push, Workshop publication, or native Project Zomboid launch without explicit authorization.
