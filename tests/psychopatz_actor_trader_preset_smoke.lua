local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Inventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Presentation = require "PsychopatzCore/Actors/PsychopatzActorPresentation"

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
    return value
end

local function hasItem(payload, fullType)
    local ledger = truthy(Inventory.Decode(payload))
    for _, item in ipairs(ledger:List()) do
        if item.fullType == fullType then return true end
    end
    return false
end

local registry = Actors.NewRegistry()
local actor, reason = registry:Create({
    actorId = "dt:preset:core",
    identitySeed = "dt-preset-core",
    identity = {
        displayName = "Mara Voss",
        survivor = {
            forename = "Mara",
            surname = "Voss",
            gender = "female",
        },
    },
    appearance = {
        policy = {
            schemaVersion = 2,
            mode = "authored",
            outfit = { mode = "none" },
            slots = {
                Torso_Upper = {
                    mode = "item",
                    type = "Base.Shirt_FormalWhite",
                    wornSlot = "Torso_Upper",
                },
                Legs = {
                    mode = "item",
                    type = "Base.Trousers_Suit",
                    wornSlot = "Legs",
                },
            },
        },
    },
    starterItems = {
        {
            fullType = "Base.Shirt_FormalWhite",
            quantity = 1,
            wornSlot = "Torso_Upper",
        },
        {
            fullType = "Base.Trousers_Suit",
            quantity = 1,
            wornSlot = "Legs",
        },
        {
            fullType = "Base.Bag_DuffelBag",
            quantity = 1,
            wornSlot = "Back",
        },
        {
            fullType = "Base.DoubleBarrelShotgun",
            quantity = 1,
            equippedSlot = "primary",
        },
    },
    extensions = {
        ["dynamictrading.traderPreset"] = {
            presetID = "dt.trader.caravan",
            role = "trader",
        },
    },
})

truthy(actor, reason)
truthy(actor.appearance.resolved.outfitItemSpecs,
    "Core expands authored preset clothing into concrete item specs")
truthy(actor.personalInventory, "Core persists preset inventory")
truthy(hasItem(actor.personalInventory, "Base.Bag_DuffelBag"),
    "Core actor inventory keeps the trader duffle bag")
truthy(hasItem(actor.personalInventory, "Base.DoubleBarrelShotgun"),
    "Core actor inventory keeps the explicit weapon")

local portrait = truthy(Presentation.BuildPortrait(actor))
truthy(portrait.appearance.outfitItemSpecs,
    "Core portrait exposes preset clothing")

print("psychopatz_actor_trader_preset_smoke: PASS")
