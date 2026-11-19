# Agent Runbook — Portable Actor Lifecycle & Social Garbage Collection

## Execution mode

This is a multi-repository unattended developer goal. Complete L0-L9 unless blocked by a genuine authority/safety/tooling conflict.

Core owns the parent docs and reusable mechanism. Hoomans and DynamicTrading are mandatory adopters.

## Startup

At every resume:

1. read root AGENTS.md in each participant;
2. verify branch/HEAD/upstream/worktree/concurrent edits;
3. read Core PROGRESS.md and HANDOFF.md;
4. read only the active roadmap gate and relevant architecture;
5. use compact repository discovery/Codebase Memory where available;
6. verify important claims against exact current source/tests.

Planning checkpoint hashes are evidence, never reset targets.

## Reuse

Evolve:

- Core ActorRegistry/ActorIdentity/PlayerIdentity/Persistence/Provider;
- Portable Social State retention/consolidation;
- existing CodeBuilder Social Policy;
- Hoomans Health.Kill/corpse/DeathMarkers/SocialEvents;
- DynamicTrading canonical trader actor/provider contracts.

Never create ActorRegistry2, SocialMemory2, a second tombstone store, or adopter-owned generic GC.

## Retirement versus hard delete

Classify every removal caller.

Hard delete is only for rollback/uncommitted/superseded state where no history should survive.

Lifecycle Retire is for meaningful death/permanent departure.

Do not mechanically replace every Remove with Retire.

## Persistence/migration

Measure before schema edits.

Every persisted field requires owner, bound, insertion/removal rule, migration, and footprint evidence.

Per-relationship -> per-actor memory migration is versioned, deterministic and one-way for new saves. Do not retain both layouts permanently.

Never mutate source saves during tests.

## GC safety

- server authority only;
- no persistent refcount authority;
- no GC from interaction/UI callbacks;
- bounded fail-closed provider root collection;
- purge only after mark + grace + weak-ref compaction;
- consequences before live-state destruction;
- restart/retry-safe sweep.

## Git safety

Current Core and Hoomans worktrees contain unrelated active work.

Stage exact phase paths only. Never git add -A as cleanup. Never reset/stash/discard uncertain changes, create branches, amend/rebase/force, or push automatically.

At multi-repo phase close, participant commits first and Core HANDOFF/parent commit last.

## Validation ladder

Use focused Core lifecycle/reference tests, social migration/retention tests, CodeBuilder determinism, Hoomans death/corpse tests, DT removal/provider tests, semantic interaction tests, MP fixtures, storage/scale/GC soak, full relevant regressions and Kahlua/static verification.

Native PZ is user-owned acceptance unless explicitly reassigned.
