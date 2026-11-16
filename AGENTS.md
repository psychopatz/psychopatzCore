# PsychopatzCore — Agent Repository Instructions

## Durable-policy rule

Keep this file limited to repository-wide rules that remain useful across unrelated goals.

- Do not place active goals, phases, Next Chunks, progress, completed-phase history, migration status, or superseded instructions in `AGENTS.md`.
- Put goal-specific state in the appropriate `Docs/` roadmap, progress, runbook, and architecture documents.
- Delete obsolete instructions instead of keeping historical goal text in this always-loaded file. Git history is the archive.
- Keep executable `/goal` prompts in ChatGPT unless the user explicitly asks for a checked-in prompt.

## Git safety

- Do not create new Git branches for PsychopatzCore work. The same standing rule applies when coordinating ProjectHoomans and DynamicTrading.
- Use existing `main` only after checking local and remote state, dirty work, worktrees, and concurrent edits.
- Preserve unrelated work. Do not blind-pull, force-push, destructively reset/rebase, auto-stash/discard, or overwrite uncertain changes.
- Remote GitHub state does not prove a local worktree is clean.
- If integration safety is unclear, report the concrete conflict instead of creating another branch or discarding work.

## Ownership boundary

- PsychopatzCore owns reusable mechanisms and portable contracts.
- Product-specific gameplay rules remain with the adopting repository unless an explicit shared contract moves that responsibility.
- Reuse established public seams rather than duplicating adopter-owned state in Core.

## Semantic CodeBuilder generated artifacts

- Treat canonical semantic source/manifests and `tools/semantic_harness/codebuilder/generation_recipe.json` (`reconcile.py --check` / `--apply`) as authority. Generated Lua/translation artifacts are downstream output, not hand-edit targets.
- For semantic generation drift or cleanup, use the canonical recipe-driven check/apply workflow. Do not manually delete or patch suspected generated leftovers, and do not infer staleness from hash-suffixed filenames.
- Safe cleanup must be owner-scoped and closed-set: remove only artifacts/keys proven CodeBuilder-owned, preserve authored or mixed-package content, and treat unexpected leftovers as a generator-lifecycle defect to fix at the source.

## Runtime and publication

- A Git commit or push is not Steam Workshop publication.
- Do not publish Workshop content or drive native Project Zomboid unless the user explicitly authorizes it.
- When live SP/MP testing belongs to the user, finish all developer-side implementation and validation before handoff.
