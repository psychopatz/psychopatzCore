# PsychopatzCore

Shared Project Zomboid Build 42 library for Psychopatz mods.

The shared library provides:

- owner-authorized special commands
- the Psychopatz admin control window and night-vision helper
- a registerable debug hub used by Dynamic Trading and Psychopatz NPC Core
- namespaced in-game settings and window-state persistence
- reusable directional event markers and their common icon assets
- base-game-compatible long-distance teleport handoff
- server-authoritative multiplayer item giving and taking
- idempotent, server-authoritative corpse-item injection

Mods can add a launcher with `PsychopatzCore.DebugHub.RegisterTool(definition)`.

## Shared responsive UI

Client mods can build consistent, resolution-aware windows on the Core UI layer:

```lua
require "PsychopatzCore/UI/PsychopatzUI"

local UI = PsychopatzCore.UI
local bounds = UI.Layout.ResolveWindow({
    width = 900,
    height = 620,
    minWidth = 520,
    minHeight = 360,
    anchor = "top_right",
})
```

Use `PsychopatzWindow` as the base class and implement `onResponsiveLayout()` to
place children whenever the window or game resolution changes. Shared helpers are
split by responsibility:

- `UI.Theme`: colors, typography choices, and spacing tokens
- `UI.Layout`: scale, safe window bounds, flow wrapping, splits, and clipping
- `UI.CreateButton`, `UI.CreateList`, and `UI.CreatePanel`: themed controls
- `PsychopatzWindow`: resizable, screen-safe shared window base

`PsychopatzWindow` persists position and size by default. Set
`persistGeometry = false` to opt out, or provide `geometryAdapter` with
`load`, `save`, and optional `clear` callbacks to use another persistence
strategy. `persistenceNamespace` and `persistenceKey` control the saved key.

Window specifications accept `center`, `top`, `bottom`, `left`, `right`,
`top_left`, `top_right`, `bottom_left`, and `bottom_right` anchors (spaces and
hyphens are accepted too). `UI.Layout.PlaceAtAnchor` applies the same anchors
to existing UI elements.

`UI.CreateList` accepts `drawItemContent` in addition to `doDrawItem`. The base
row renderer runs first, then the content callback can layer badges, icons, or
other reusable row decorations without replacing the row layout.

Controls should be created once in `createChildren()` and repositioned in
`onResponsiveLayout()`:

```lua
function MyWindow:onResponsiveLayout()
    local content = self:getContentRect({ top = 56, bottom = 48 })
    local columns = PsychopatzCore.UI.Layout.Split(content, {
        firstRatio = 0.4,
        breakpoint = 760,
    })
    PsychopatzCore.UI.Layout.SetBounds(self.leftList,
        columns.first.x, columns.first.y,
        columns.first.width, columns.first.height)
end
```

## Shared settings and markers

Open a namespaced settings store with
`PsychopatzCore.Settings.Open(namespace, options)`. Stores preserve booleans,
numbers, strings, and window geometry in a per-mod text file. Register a common
settings screen through `PsychopatzCore.InGameSettings.Register(definition)`.

Event markers are available as `PsychopatzCore.EventMarkers`. Existing
`EventMarker` and `EventMarkerHandler` globals remain as compatibility aliases.

## World and inventory services

After a mod has authorized a teleport on the server, call:

```lua
local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"
Teleport.ToCoordinates(player, x, y, z)
```

In multiplayer, Core sends the approved destination only to that player and the
client uses the base-game teleport command, allowing PZ to stream distant map
chunks and perform its normal network bookkeeping.

Server-side item transfers use native container sync packets:

```lua
local Items = require "PsychopatzCore/Inventory/PsychopatzItemTransfer"
Items.GiveToPlayer(player, "Base.Axe", 1, { condition = 8 })
Items.TakeFromPlayer(player, clientItemIDs, { expectedFullType = "Base.Axe" })
```

Treat client item IDs as claims, never as trusted item objects. `TakeFromPlayer`
resolves every ID against the authoritative player inventory, rejects duplicates,
validates the complete selection, and only then removes and synchronizes items.

Corpse construction uses a separate service because live-container add packets
must not be mixed with `IsoDeadBody` conversion:

```lua
local CorpseItems =
    require "PsychopatzCore/Inventory/PsychopatzCorpseItems"

CorpseItems.InjectIntoCorpse(corpse, {
    {
        fullType = "Base.IDcard",
        key = "my-mod:identity:" .. npcId,
        customName = "ID Card: " .. npcName,
        modData = { MyNPCId = npcId },
    },
})
CorpseItems.Transmit(corpse)
```

Stable keys make repeated lifecycle/finalization passes idempotent. Mutation is
rejected on multiplayer clients. During corpse construction, inject everything
and call `Transmit` once after the final corpse exists. To mutate an already
replicated corpse, use `Insert(..., { syncItem = true })`; Core then sends the
native per-item container packet from the server.

`PsychopatzCore.UI.PortraitPanel` also accepts
`spec.preferDescriptor = true`. Consumers that represent a survivor with an
IsoZombie carrier can combine that with `animSetName = false`, full-body zoom,
and the `idle` state to get a normal upright human portrait. Existing consumers
that want to render a live character retain the original default behavior.
