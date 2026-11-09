local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Registry = Actors.Archetypes

local registered, registerReason = Registry:Register({
    id = "projecthoomans.doctor",
    aliases = { "Doctor" },
    label = "Doctor",
    sourceMod = "ProjectHoomans",
    tags = { "civilian", "medical" },
    visualProfile = "colonist",
    skillBias = { FirstAid = { min = 5, max = 8 } },
    appearance = {
        mode = "authored",
        male = { { "Base.Hat_SurgicalCap" } },
    },
    inventory = {
        bagChoices = { "Base.Bag_DoctorBag" },
        items = {
            {
                key = "doctor_bandage",
                type = "Base.Bandage",
                stack = 4,
                preferredContainer = "bag",
            },
        },
    },
    extensions = {
        ["projecthoomans.archetype"] = {
            allowedJobs = { MedicalCare = true },
        },
    },
})
truthy(registered, registerReason)

local definition = Registry:Get("Doctor")
truthy(definition, "alias resolves to authored archetype")
equal(definition.id, "projecthoomans.doctor", "canonical archetype ID")
equal(definition.inventory.items[1].fullType, "Base.Bandage",
    "item full type normalized")
equal(definition.inventory.items[1].quantity, 4,
    "item quantity normalized")
equal(definition.skillBias.FirstAid.min, 5, "skill bias preserved")
equal(definition.extensions["projecthoomans.archetype"].allowedJobs.MedicalCare,
    true, "adopter extension preserved")

local duplicate, duplicateReason = Registry:Register({
    id = "projecthoomans.doctor",
    aliases = { "Doctor" },
    label = "Doctor",
    sourceMod = "ProjectHoomans",
    tags = { "civilian", "medical" },
    visualProfile = "colonist",
    skillBias = { FirstAid = { min = 5, max = 8 } },
    appearance = {
        mode = "authored",
        male = { { "Base.Hat_SurgicalCap" } },
    },
    inventory = {
        bagChoices = { "Base.Bag_DoctorBag" },
        items = {
            {
                key = "doctor_bandage",
                type = "Base.Bandage",
                stack = 4,
                preferredContainer = "bag",
            },
        },
    },
    extensions = {
        ["projecthoomans.archetype"] = {
            allowedJobs = { MedicalCare = true },
        },
    },
})
truthy(duplicate, duplicateReason)
equal(duplicateReason, "already_registered",
    "identical registration is idempotent")

local conflict, conflictReason = Registry:Register({
    id = "projecthoomans.doctor",
    label = "Conflicting Doctor",
    sourceMod = "OtherMod",
})
equal(conflict, false, "conflicting registration rejected")
equal(conflictReason, "archetype_id_conflict",
    "conflicting registration reason")

print("psychopatz_actor_archetype_registry_smoke: PASS")
