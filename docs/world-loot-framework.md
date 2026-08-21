# World Loot framework

`PsychopatzCore.WorldLoot` is a reusable, server-authoritative bridge between
loaded world loot and the Core inventory transaction framework. It contains no
companion, colony, task, or Project Hoomans rules.

## Public API

- `RegisterSourceAdapter(adapter)` extends discovery with a source type and
  policy key.
- `FindSources(options)` performs one bounded circular square traversal for all
  enabled adapters, deduplicates candidates, orders them by squared distance,
  applies a hard candidate cap, and returns opaque descriptors.
- `ResolveSource`, `GetSourceLocation`, and `IsSourceValid` revalidate an opaque
  runtime source token.
- `ListItems` returns lightweight item descriptors and retains exact native
  identity only inside the runtime session.
- `ReserveItem` and `ReleaseReservation` protect an exact item token for a
  caller-owned workflow.
- `Transfer` adapts the source and destination to
  `PsychopatzInventoryTransaction`; destination failure restores the original
  source item.
- `RemoveItem` is the lower-level deletion API for callers that intentionally do
  not need a destination transaction.
- `ReleaseSession` expires all source/item/reservation tokens for a run.
- `GetDiagnostics` exposes bounded counters, gauges, and search/inspection/
  transfer timing observations.

## Built-in adapters

The container and corpse adapters wrap the native `ItemContainer` with the
existing physical inventory adapter and enable server add/remove replication.
The corpse adapter recognizes loaded `IsoDeadBody` objects and keeps their
inventory lifecycle within the same transaction path.

The floor adapter groups all world inventory objects on one square as one
source. Its store removes the actual world object with the square/world
lifecycle API and recreates it on transaction rollback. It is deliberately not
treated as an ordinary container.

## Tokens, limits, and persistence

Tokens use runtime session/source/item/reservation namespaces. Public
descriptors copy scalar values only; raw squares, objects, containers, corpses,
and InventoryItems never cross the API boundary or enter ModData. At most 64
Core sessions are retained. Radius, candidate, and per-source item enumeration
are capped, and a cap produces a `truncated` result instead of an unbounded
scan.

There is no global loot index and no tick hook. Unused WorldLoot performs zero
world scans. Callers explicitly discover once, then resolve only their current
physical destination.
