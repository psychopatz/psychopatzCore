# Harness Acceptance — Portable Actor Lifecycle & Social Garbage Collection

## A. Core lifecycle

Prove LIVE -> RETIRED/tombstone, full live-state release, minimal tombstone, save/reload, lifecycle revision conflict, client rejection, rollback hard-delete without tombstone, and player-character retirement without requiring a full NPC actor record.

## B. Reference providers

Prove strong pinning, weak-only nonpermanent behavior, malformed/unbounded provider fail-closed behavior, provider removal allowing collection, no persistent refcount dependency, and ExplainRetention output.

## C. Mark/sweep

Test purge after grace, strong memory/bond/contract pins, last-root release, interrupted sweep safety, cursor resume, and deterministic startup reconciliation.

## D. Social memory migration

Create many relationships/memories and prove one actor-level bank, hard total budget, SHORT/LONG/ANCHOR quotas, no persistent SCENE, consolidation, baseline promotion, no per-edge memory arrays, deterministic save/load.

## E. Historical relationships

Test friend retained, stranger pruned, grievance against perpetrator retained, victim tombstone later purgeable, dead actor outgoing graph reclaimed, and no zero/default dead edges.

## F. Hoomans

Prove Health.Kill consequences precede Core retirement, full PNC record retires, DeathMarker/corpse/reanimation remains correct, marker pins only while needed, ordinary unowned death is not permanent cemetery data, real bond/quest/faction pins work, and semantic evidence remains bounded.

## G. Player/MP

Test SP/MP death, reconnect same living character, new character after death, significant NPC memory of old player, no automatic personal transfer, client retire/purge rejection, and stale interaction invalidation.

## H. DynamicTrading

With PNC disabled test trader retirement where supported, commercial role removal without fake death, rollback without tombstone, migration supersession without fake death, meaningful trader history, real debt/contract root only if present, and DTHoomans continuity.

## I. Semantic/interaction performance

Measure click -> hot snapshot -> lifecycle resolution -> candidate filtering -> bounded evidence query. Assert no world GC/full actor scan/full raw memory scan.

## J. Scale

Run 1,000+ actors, sparse contacts, 700+ retirements, weak/anchor history, player deaths, save/reload and multiple GC generations.

Require bounded memory per actor, reclaimed outgoing state, tombstones proportional to meaningful strong history, no dangling strong refs, no population-squared allocation, budgeted non-frame GC and measured before/after footprint.

## K. Final regression

Run relevant Core/Hoomans/DT full suites, semantic harness, Social Policy CodeBuilder reconcile/determinism, persistence/MP fixtures, and Kahlua/static checks.

Harness success is not native PZ acceptance.
