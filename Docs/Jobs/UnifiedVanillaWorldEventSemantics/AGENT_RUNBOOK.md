# Agent Runbook — Unified Vanilla World Event Semantics

## Startup

1. Read root `AGENTS.md` in Core, ProjectHoomans and DynamicTrading before changing each repo.
2. Verify `main`, exact HEAD, upstream, staged/unstaged/untracked state and concurrent work independently in all three repos.
3. Read this job's `PROGRESS.md`, then `HANDOFF.md`, then only the active ROADMAP/ARCHITECTURE sections needed for the current phase.
4. Treat the installed Project Zomboid runtime/source as read-only evidence. Never patch the game installation.
5. Preserve unrelated work and file ownership; do not use root/sudo for repository writes.

## Installed-build coverage audit

- Discover the current installed game root from workspace/machine evidence; do not hard-code a permanent installation path into runtime code.
- Development tooling may inspect Lua/JAR/class metadata to build the coverage manifest.
- Runtime code must not reflect over the JAR or enumerate vanilla classes dynamically.
- Re-run coverage discovery when the installed game build changes materially.

## Implementation discipline

- Extend `PsychopatzScopedWorldEvents` and WorldKnowledge rather than creating another ledger.
- Use native hooks first. Reuse an existing coarse shared pump only when vanilla exposes no usable hook.
- Resolve location once at event/discovery ingestion and pass stable references downstream.
- Keep PZ-specific mechanics behind an adapter/capability boundary.
- Do not hand-edit CodeBuilder-generated dialogue/translation artifacts.
- Prefer canonical ConvoEngine semantic families/affordances for dialogue depth.
- Preserve player/NPC parity and numeric-disposition semantics.
- Never convert an unsupported exact story identity into a fabricated fact; use observable semantics or record a coverage gap.

## Tests per phase

Each accepted phase requires focused deterministic tests plus relevant existing suites. V2+ requires save/load tests. V4+ requires scale/boundedness evidence. V7+ requires Semantic Lab/fixture coverage for branch reachability, constraints, provenance and N-actor cases. V8 reruns full cross-repo touched suites and performance checks.

## Git / phase close

At each accepted developer phase:
1. reconcile ROADMAP/PROGRESS/HANDOFF;
2. stage exact phase-owned paths only;
3. commit participant repos first when changed;
4. commit the primary Core repo last with current HANDOFF;
5. verify commit vector and residual dirty fingerprints;
6. continue automatically to the next mandatory phase.

Never push, publish, tag, release or Workshop-upload without explicit user authorization. Never reset/stash/rebase/discard unrelated user work.
