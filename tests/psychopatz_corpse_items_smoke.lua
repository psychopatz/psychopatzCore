local SHARED_ROOT =
    "Contents/mods/PsychopatzCore/42.16/media/lua/shared/"

package.path = SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual")
            .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local values = {}
local addCalls = 0
local packetCalls = 0
local transmitCalls = 0
local clientOnly = false
local server = true
local container = {}

function container:getItems()
    return makeList(values)
end

function container:AddItem(item)
    addCalls = addCalls + 1
    values[#values + 1] = item
    item.container = self
    return item
end

local function makeItem(fullType)
    local modData = {}
    return {
        container = nil,
        getFullType = function() return fullType end,
        getContainer = function(self) return self.container end,
        getModData = function() return modData end,
        setName = function(self, value) self.name = value end,
        setCondition = function(self, value) self.condition = value end,
    }
end

isClient = function() return clientOnly end
isServer = function() return server end
sendAddItemToContainer = function()
    packetCalls = packetCalls + 1
end
instanceItem = function(fullType)
    return makeItem(fullType)
end

local CorpseItems =
    require "PsychopatzCore/Inventory/PsychopatzCorpseItems"

local spec = {
    fullType = "Base.IDcard",
    key = "test:identity:npc_1",
    customName = "ID Card: Test NPC",
    condition = 7,
    modData = {
        OwnerID = "npc_1",
        IsIdentityCard = true,
    },
}

local first, firstCreated = CorpseItems.Inject(container, spec)
local second, secondCreated = CorpseItems.Inject(container, spec)

assert(first, "first corpse item was not injected")
assertEqual(first, second, "idempotent injection result")
assertEqual(firstCreated, true, "first injection created item")
assertEqual(secondCreated, false, "second injection reused item")
assertEqual(#values, 1, "deduplicated container size")
assertEqual(addCalls, 1, "single container mutation")
assertEqual(packetCalls, 0, "no unsafe per-item corpse packet")
assertEqual(first.name, "ID Card: Test NPC", "custom item name")
assertEqual(first.condition, 7, "item condition")
assertEqual(first:getModData().OwnerID, "npc_1", "custom metadata")
assertEqual(
    first:getModData()[CorpseItems.INJECTION_KEY_FIELD],
    spec.key,
    "stable injection key"
)

local addedLoot = CorpseItems.Insert(container, {
    fullType = "Base.Bandage",
}, {
    syncItem = true,
})
assert(addedLoot, "existing-corpse loot was not inserted")
assertEqual(#values, 2, "existing-corpse insertion")
assertEqual(packetCalls, 1, "existing-corpse native add packet")

local corpse = {
    getContainer = function() return container end,
    transmitCompleteItemToClients = function()
        transmitCalls = transmitCalls + 1
    end,
}
local transmitted = CorpseItems.Transmit(corpse)
assertEqual(transmitted, true, "authority corpse transmit")
assertEqual(transmitCalls, 1, "single complete-corpse transmit")

clientOnly = true
server = false
local rejected, _, reason = CorpseItems.Inject(container, {
    fullType = "Base.Bandage",
    key = "test:client-rejected",
})
assertEqual(rejected, nil, "client mutation rejection")
assertEqual(reason, "not_authority", "client rejection reason")
assertEqual(#values, 2, "client did not mutate corpse")

print("psychopatz_corpse_items_smoke: ok")
