# PsychopatzCore — Agent Repository Instructions

## Permanent Git policy (2026-10-20)

**DO NOT CREATE ANY NEW GIT BRANCHES** for audits, implementations, testing, documentation, integrations or Codex work. User explicitly requests no further branches in ProjectHoomans, PsychopatzCore or DynamicTrading. This prohibits `git checkout -b`, `git switch -c`, `git branch <new>`, scratch/worktree branches and automatic PR branches. Use existing `main` for authorized new changes after verifying local/remote HEAD, upstream, worktree and concurrent file ownership. Fast-forward-safe commits/pushes only; never blind `git pull`, force-push, discard, reset or rebase uncertain changes.

ProjectHoomans has an **already-existing** divergent personal-dialogue/Foundation implementation branch and PR #4; those historical refs are not permission to create another. Before pulling any of that history into Hoomans main, inspect git merge-base/log/diff and `git merge-tree` without new branches and verify dependencies and tests. Preserve user and other-agent code; leave unsafe integration unresolved with explicit evidence rather than fabricating a "clean" sync. The native Project Zomboid SP/MP testing and Workshop publication remain user-owned.

## Scope and acceptance

Core NPC Foundation P0–P9 developer scope is recorded accepted via Core source/headless tests. This does not certify native live gameplay, and it does **not** close the separate ProjectHoomans grounded personal dialogue B0–B6 goal. Source-backed regressions must be fixed where proved, without reopening every accepted phase or claiming unrelated old suite failures are verified harmless.
