# Psychopatz Inventory Framework

`PsychopatzCore.Inventory` is the shared item identity, item-state, and inventory-store layer for Psychopatz mods. It does not replace the vanilla player inventory. Live inventories remain `ItemContainer`s behind a physical adapter; compact virtual stores are used when vanilla `InventoryItem` behavior is not required.

## Architecture

- `ItemTypeRegistry` owns the world-wide append-only `fullType <-> numeric ID` mapping. A new world sorts all loaded script item full types before assigning IDs. Later loads retain every mapping, including unavailable mod items, and append new types. Only `id -> fullType` is persisted; reverse lookup is rebuilt.
- `ItemCodecRegistry` selects state codecs independently from item identity. Built-ins cover generic items, food, drainables, weapons, clothing, nested containers, and a conservative fallback.
- `ItemRecord` is a dense array: `[typeId, quantity, flags, codecId, stateValues, unitWeight, stackDiscriminator?]`. State values are ordered by flags; the optional final slot is `false` for unique records or a codec-provided stack discriminator. Static script definitions are not repeated.
- `VirtualInventory` batches equivalent records, maintains type counts and weight incrementally, and exposes CRUD, queries, compaction, validation, and reservations.
- `PhysicalInventoryAdapter` presents an `ItemContainer` through the same count/query/add/remove surface without replacing vanilla mechanics.
- `InventoryTransaction` performs authority-gated transfer/deposit/withdraw/consume operations and restores the source if the destination rejects an add.
- `InventorySerializer` stores schema-versioned canonical records. `InventoryNetworkCodec` uses the same records and carries registry/inventory revisions; registry deltas can be synchronized separately.
- `InventoryValidator` checks record, type, batching, weight, index, and reservation invariants. `InventoryRoundTripTester` compares codec-known state after encode/decode/re-encode.

The framework is event-driven. It registers only world-registry initialization and has no tick, second, or minute polling.

## Public API

```lua
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

local nailsId = Inventory.getItemTypeId("Base.Nails")
local fullType = Inventory.getItemFullType(nailsId)

local stock = Inventory.createVirtualInventory({ maxWeight = 200 })
stock:add(nailsItem, 100)
stock:remove("Base.Nails", 20)
local remaining = stock:count("Base.Nails")

local live = Inventory.wrapPhysicalInventory(character:getInventory())
Inventory.transfer(live, stock, "Base.Bandage", 1)

local reservation = Inventory.reserve(stock, "Base.Nails", 10, "construction-job")
Inventory.commitReservation(stock, reservation)
-- or Inventory.releaseReservation(stock, reservation)
```

Custom codecs use a stable numeric ID and a unique name. Higher priority codecs are tested first:

```lua
Inventory.registerCodec({
    id = 1001,
    name = "my_mod_power_cell",
    priority = 200,
    matches = function(item)
        return item:getFullType() == "MyMod.PowerCell"
    end,
    encode = function(item)
        return { flags = 0, state = { item:getCharge() }, unitWeight = item:getActualWeight(), batchable = true }
    end,
    decode = function(item, flags, state)
        item:setCharge(state[1])
        return true
    end,
})
```

Codec IDs are part of persisted records and must never be reassigned after release. Unknown modded items use codec `255`, retain accessible generic state and `modData`, and never batch.

## Registry persistence and networking

The world registry is stored in `ModData["PsychopatzCore.Inventory"].itemTypeRegistry`:

```lua
{
    schemaVersion = 1,
    revision = 847,
    nextId = 848,
    types = { [1] = "Base.Apple", [2] = "Base.Axe" },
}
```

IDs are never recycled. A removed mod leaves its mappings reserved. `NetworkCodec.encodeRegistryDelta(clientRevision)` emits only later entries. Inventory snapshots therefore use numeric type IDs rather than repeated full-type strings.

In debug mode, **Psychopatz Debug Hub > Item Type Ledger** presents the current
Lua environment's generated registry. It shows every numeric ID, full type,
script-catalog availability, registry revision, next ID, unavailable mappings,
and unexpected gaps. `Refresh Script Availability` rechecks the loaded catalog
without changing any numeric mapping. The same data is available through
`ItemTypeRegistry.getDebugSnapshot()` for automated diagnostics.

The virtual persistence envelope is `[virtualSchema, itemRecordSchema, revision, maxWeight, records]`. The network snapshot envelope is `[networkSchema, itemRecordSchema, registryRevision, inventoryRevision, records]`. Reservations, indexes, reverse registry lookup, cached query results, and debug state are intentionally absent.

## NPC flow

ProjectHoomans remains responsible for ownership, equipment slots, AI decisions, and presence transitions. Its new persisted abstract inventory is a versioned envelope containing a PsychopatzCore virtual-inventory payload plus a compact ProjectHoomans metadata sidecar for NPC-only concepts such as item IDs, worn slots, attachment slots, and interaction locks.

```text
live NPC ItemContainer -> PhysicalInventoryAdapter -> ItemRecord -> VirtualInventory
VirtualInventory -> ItemRecord decode -> PhysicalInventoryAdapter -> live NPC ItemContainer
```

ProjectHoomans gameplay methods remain its domain-facing facade, while persisted item identity/state is owned by PsychopatzCore. The obsolete template-plus-delta serializer is removed; no old development-save migration is provided.

## Future consumers

Base and outpost stockpiles, courier cargo, group inventory, and trading stores should compose `VirtualInventory` with their own ownership and capacity policies. They must reuse the same item registry, records, codecs, transactions, and reservations rather than defining new item formats. A tiered stockpile can set `maxWeight` without changing records, and courier transfers can move the same records atomically between stores.

## Conservative limitations

- Arbitrary Java-backed or cyclic values inside `modData` cannot be represented. The fallback copies bounded Lua scalar/table state and refuses batching.
- Nested container contents require the item to expose `getInventory()` and the destination item to accept decoded children through `AddItem`. Decode fails instead of dropping children when those APIs are absent.
- Project Zomboid subclasses and modded Java overrides must be verified in-engine. The automated smoke tests use API-faithful Lua doubles and do not claim coverage for every engine subclass.
