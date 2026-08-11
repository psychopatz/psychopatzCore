# Grid regions and zones

PsychopatzCore exposes geometry only; it has no settlement, facility, or NPC
semantics.

`PsychopatzCore.GridRegion` stores integer tiles as normalized horizontal
scanline spans:

```lua
{
    levels = {
        [0] = { rows = {
            [11550] = { 8060, 8068 },
            [11551] = { 8060, 8063, 8067, 8068 },
        } },
    },
}
```

Each row is a flat sequence of inclusive `x1, x2` pairs. `normalize` rejects
non-integer and inverted pairs, sorts ranges, merges overlaps and adjacent
ranges, and removes empty rows and levels. The canonical operations are
`containsPoint`, `containsXY`, `containsRegion`, `intersects`, `union`,
`intersection`, `subtract`, `countTiles`, `bounds`, `spanCount`,
`componentCount`, and `isConnected`. Connectivity is cardinal and implemented
as overlapping spans on adjacent rows rather than a per-tile flood fill.

`PsychopatzCore.Zones` wraps regions in generic records with stable IDs,
ownership metadata, cached bounds/tile counts, and optimistic revisions. Its
runtime-only spatial index maps 10x10 world buckets to candidate IDs. Geometry
registration and mutation update bucket membership immediately; there is no
periodic rebuild. `export` omits the runtime buckets and `import` rebuilds them.

The pure smoke suite is `tests/psychopatz_grid_region_smoke.lua`.

## World-region authoring UI

Client mods can open the reusable editor with
`PsychopatzCore.UI.GridRegionSelector.Open(options)`. The editor keeps all
mouse movement and preview geometry local, highlights normalized spans rather
than individual stored tile records, and calls `onConfirm(region, stats)` once.
It supports rectangular drag, Replace/Add/Erase composition for irregular
regions, undo/reset, point selection, optional guide geometry, tile caps, and a
domain-supplied validation callback. It has no knowledge of bases or
facilities.

Important options are `title`, `instruction`, `selectionKind` (`region` or
`point`), `initialRegion`, `guideRegion`, `guideRenderZ`, `maxTiles`,
`validate`, `onConfirm`, `onCancel`, and `ownerWindow`. The callback receives a
canonical GridRegion; the consuming mod remains responsible for networking and
server authority. `PsychopatzCore.GridRegionEditor` also exposes pure
`rectangle`, `point`, `apply`, `translate`, and `stats` helpers for other tools.
