# PsychopatzCore inventory display state

PsychopatzCore owns the read-only display projection shared by inventory UIs,
storage views, NPC ledgers, and future trading or merchant systems.

The canonical persistence record remains the compact positional array:

```text
[typeId, quantity, flags, codecId, state, unitWeight, stackDiscriminator]
```

Use the projection API when a consumer needs item details without creating a
native `InventoryItem`:

```lua
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

local state, known = Inventory.projectItemState(record)
local networkState, networkKnown = Inventory.projectItemState(record, {
    network = true,
})
local compact, compactKnown = Inventory.projectCompactState(compactItem)
local native, nativeKnown = Inventory.projectNativeState(item, {
    fullFluid = true,
})
```

`projectItemState` and `projectCompactState` are side-effect free. Native full
fluid capture is opt-in because enumerating the fluid catalog is more costly
than reading amount/capacity/primary-fluid summary values.

Display projections are deliberately bounded. They carry known gameplay state,
up to eight fluid components, finite numeric values, and no arbitrary `modData`.
Pass `network = true` to `projectItemState` when crossing a network boundary;
this avoids a second copy/projection pass. `DisplayState.ProjectNetworkState`
is available when the source is already a display-state table.
Food aging checkpoints remain persistence/runtime state and are not exposed in
the normal display projection. Durability maxima come from item metadata when
the compact record only stores current condition.

The same projection is available through
`PsychopatzCore.Inventory.NetworkCodec.projectRecord` for systems that already
operate at the network codec boundary.

The client tooltip host is adapter-driven:

```lua
local Host = require
    "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipHost"

Host.Install(window, {
    adapter = {
        lists = function(owner) return { owner.itemList } end,
        hoveredIndex = function(list) return list:hoveredRowIndex() end,
        rowAt = function(list, index)
            return list.items[index].item
        end,
    },
})
```

Consumers own row construction, metadata providers, permissions, and transfer
semantics. Core owns state interpretation, tooltip caching, placement, and
non-interactive rendering.
