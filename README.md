# PsychopatzCore

Reusable inventory architecture and API: [docs/inventory-framework.md](docs/inventory-framework.md).

Shared Project Zomboid Build 42 library for Psychopatz mods.

The opt-in, generic performance profiler is documented in
[`docs/profiler.md`](docs/profiler.md). It defaults to OFF and loads no metric
backend, callbacks, histories, GUI, networking, or snapshot activity in normal
gameplay.

Reusable responsive-window and scrolling-control rules are documented in
[`docs/responsive-window-ui.md`](docs/responsive-window-ui.md).

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

## Shared radio actions

Client mods can add a player-facing action to the vanilla in-game radio window
without each patching `ISRadioWindow`:

```lua
require "PsychopatzCore/UI/Radio/PsychopatzRadioActions"

PsychopatzCore.RadioActions.Register({
    id = "my-mod.example",
    label = "Example Service",
    signalLabel = "Example Service",
    placement = PsychopatzCore.RadioActions.PLACEMENT_SIGNAL,
    order = 100,
    isAvailable = function(player, radioWindow) return true end,
    isEnabled = function(player, radioWindow) return true end,
    onClick = function(player, radioWindow) openMyWindow() end,
})
```

`PLACEMENT_SIGNAL` asks Core's native Build 42 radio host to append a distinct,
full-width action inside the collapsible Signal module. Each registration
remains a separate button; the vanilla module and radio window derive their
expanded height from the stack. `signalLabel` can provide a label specifically
for that stack, and placed actions do not fall back into the top-level radio
header when their host is unavailable.

Actions without a placement use the core's compact radio service button. With
one available action it uses that action's label directly; with several actions
it opens a `Radio Services` menu. The older `hostButton` field remains available
for integrations that intentionally own a compatible button; pair it with
`hostRequired = true` when it must not fall back. `isAvailable`
controls whether an item is shown, while `isEnabled`
controls whether it can be launched. Actions are only shown for two-way radios
and are disabled while the device is off or out of power. Use stable namespaced
IDs and `Unregister(id)` only when a registration genuinely needs to be removed.

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
- `UI.CreateButton`, `UI.CreateList`, `UI.CreateCategorizedList`, and
  `UI.CreatePanel`: themed controls
- `UI.CreateKeyValueList` / `UI.AddKeyValue`: reusable two-column detail lists
- `UI.CreateTextEntry`: consistent text-entry construction and input options
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

Always use `UI.Layout.SetBounds` for instantiated scrolling controls. It also
synchronizes native `vscroll`/`hscroll` geometry; direct resize calls can leave
Project Zomboid's cached stencil boundary in the old position and hide rows.

`UI.CreateCategorizedList` builds a scrolling list from arbitrary item records.
Provide `getCategoryPath(item)` to return a slash-delimited string or an array
of category labels. Each category is rendered as a toggleable header, and
`collapseAll()` / `expandAll()` plus `onItemSelected` and `onItemActivated`
are available on the returned list. This is the shared pattern for debug
catalogs and inventory-like item browsers.

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

The same service is the standard native-item boundary for all Psychopatz mods:

- `ResolvePlayerContainer` and `GiveToPlayerContainer` safely target the main
  inventory or a carried backpack by authoritative item ID.
- `CaptureState` and `ApplyState` preserve portable condition, drainable,
  favorite, custom-name, ammunition, fluid, and scalar modData fields.
- `DropToSquare` materializes that item-state contract in the world.

Compact inventory decoding centralizes Build 42 item creation in
`PsychopatzItemRecord`. It tries an injected factory, then
`InventoryItemFactory`, then the global `instanceItem` compatibility API. This
keeps virtual-to-physical materialization consistent across server contexts
where `InventoryItemFactory.CreateItem` exists but returns `nil`.

DynamicTrading's server helpers are compatibility wrappers around this service;
new mods should call the Core API directly.

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
