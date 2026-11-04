local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Persistence = require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local Presentation = require "PsychopatzCore/Actors/PsychopatzActorPresentation"

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
    return value
end

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function forbiddenStarter(fullType)
    return fullType == "Base.Tshirt"
        or fullType == "Base.Trousers"
        or fullType == "Base.Shoes"
end

local registry = Actors.NewRegistry()
local actor, reason = registry:Create({
    actorId = "appearance-contract:test:actor",
    identitySeed = "appearance-contract-seed",
    world = {
        location = { kind = "world", x = 10, y = 20, z = 0 },
    },
})
truthy(actor, reason)

for _, starter in ipairs(ActorInventory.DefaultStarters()) do
    if forbiddenStarter(starter.fullType) then
        error("default starter still uses an invalid runtime item: "
            .. tostring(starter.fullType))
    end
end

local portrait = truthy(Presentation.BuildPortrait(actor))
for _, fullType in pairs(portrait.equipment.worn or {}) do
    if forbiddenStarter(fullType) then
        error("portrait equipment still uses an invalid runtime item: "
            .. tostring(fullType))
    end
end
if forbiddenStarter(portrait.appearance.outfit) then
    error("generated appearance still uses an abstract outfit label: "
        .. tostring(portrait.appearance.outfit))
end
truthy(portrait.appearance.outfitItemSpecs,
    "generated appearance must carry concrete outfit item specs")
truthy(portrait.appearance.skinTexture,
    "generated appearance must carry a valid body texture")
truthy(portrait.appearance.hairModel,
    "generated appearance must carry a valid human hair model")
truthy(portrait.appearance.skinColor.r,
    "generated appearance must carry a numeric skin color")
truthy(portrait.appearance.hairColor.r,
    "generated appearance must carry a numeric hair color")

local originalNext = next
_G.next = nil
local ok, saved, saveReason = pcall(function()
    return registry:Save()
end)
_G.next = originalNext
if not ok then error("registry save raised with Kahlua-safe table iteration: "
    .. tostring(saved)) end
truthy(saved, saveReason)

local legacyLedger = truthy(ActorInventory.CreateForActor(
    actor.actorId,
    actor.identity.identitySeed,
    {
        starterItems = {
            {
                fullType = "Base.Tshirt",
                quantity = 1,
                wornSlot = "Torso_Upper",
            },
        },
    }
))
local legacy = {
    schema = actor.schema,
    schemaVersion = actor.schemaVersion,
    actorId = actor.actorId .. ":legacy",
    ownerMod = actor.ownerMod,
    revision = actor.revision,
    identity = actor.identity,
    appearance = actor.appearance,
    personalInventory = legacyLedger:ToPayload("FULL"),
}
local migrated = truthy(Persistence.DecodeActor(legacy))
local migratedItems = truthy(ActorInventory.Decode(
    migrated.personalInventory)):List()
for _, item in ipairs(migratedItems) do
    if forbiddenStarter(item.fullType) then
        error("legacy inventory was not migrated to a valid runtime item")
    end
end

print("psychopatz_actor_persistence_appearance_contract_smoke: PASS")
