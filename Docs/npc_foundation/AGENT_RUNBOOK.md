# Core NPC Foundation — Agent Runbook

## Parent goal

The Core NPC Foundation is **reopened for presentation/integration recovery** as of 2026-11-03.

Earlier P1–P9 headless evidence remains accepted foundation where not contradicted, but P6/P8/P9 completion claims are superseded by the new source/native audit.

## Read order

1. repository root `AGENTS.md`;
2. `ARCHITECTURE.md`;
3. `ROADMAP.md`;
4. `PLAN.md`;
5. DynamicTrading DTAbstract recovery docs;
6. `PROGRESS.md` last.

Before Hoomans or DynamicTrading edits, read their root `AGENTS.md` and inspect branch/upstream/worktrees.

## Recovery invariants

- Core owns reusable mechanisms, not adopter gameplay policy.
- Core must own one generic production world-map integration.
- Hoomans and DTAbstract register layers/tools; they do not keep parallel generic map hosts.
- Hoomans keeps colony/community/group-specific policy.
- DT keeps trader/settlement/economy policy.
- Server actor state is authoritative.
- Clients consume bounded revisioned presentation projections.
- Production persistence must actually wire registry save/load to runtime lifecycle.
- Provider orchestration changes representation, not actor identity.
- No duplicate body, actor, item, stock, lease, map hook or authority.

## Validation discipline

Do not claim:

- map completion from data-only registry tests;
- client/server correctness from shared Lua tables;
- persistence from direct codec calls only;
- handoff orchestration from manual adapter sequencing;
- UI completion from registration/helpers;
- native acceptance from mocks.

## Execution

Start at the current Next Chunk in `PROGRESS.md`, validate, update progress, and continue automatically through remaining mandatory recovery phases.

## Git

Existing `main` only. No blind pull, force/reset, destructive rebase, automatic stash/discard, or Workshop publication. Preserve unrelated user work.

## Stop condition

Stop only for a genuine blocker or when all developer-side recovery phases are accepted and only the explicit native SP/MP matrix remains.
