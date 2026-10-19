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
local generated = Actors.NewRegistry()

local created, reason = generated:Create({
    actorId = "pnc:test:generated",
    identitySeed = "foundation-generated-seed",
    archetypeID = "merchant.test",
})
truthy(created, reason)
equal(created.appearance.contract.mode, "GENERATED_DEFAULT",
    "generated appearance mode")
equal(created.identity.identitySeed, "foundation-generated-seed",
    "generated seed")
truthy(created.identity.survivor.voiceProfile.voice, "generated voice")
truthy(created.appearance.resolved.outfit, "generated outfit")

local authored, authoredReason = generated:Create({
    actorId = "pnc:test:authored",
    identitySeed = "foundation-authored-seed",
    identity = {
        displayName = "Authored Trader",
        survivor = {
            forename = "Authored",
            surname = "Trader",
            voiceProfile = {
                schemaVersion = 1,
                voice = "parity_voice",
                voicePrefix = "parity_voice",
                voiceType = 3,
                voicePitch = 1.25,
                complete = true,
            },
        },
    },
    appearance = {
        policy = {
            schemaVersion = 2,
            mode = "authored",
            outfit = "none",
            slots = {
                Torso_Upper = {
                    mode = "item",
                    type = "Base.Jacket",
                    wornSlot = "Torso_Upper",
                    itemState = { source = "authored" },
                },
            },
        },
        resolved = { outfit = "none", slots = { Torso_Upper = "Base.Jacket" } },
    },
    extensions = { ["test:fixture"] = { preserved = true } },
})
truthy(authored, authoredReason)
equal(authored.appearance.contract.mode, "AUTHORED_POLICY",
    "authored appearance mode")
equal(authored.identity.survivor.voiceProfile.voicePitch, 1.25,
    "authored voice pitch")
equal(authored.appearance.policy.slots.Torso_Upper.itemState.source,
    "authored", "authored item state")

local saved, saveReason = generated:Save()
truthy(saved, saveReason)
local fresh = Actors.NewRegistry()
truthy(fresh:Load(saved), "load generated registry")
local reloaded = fresh:Get("pnc:test:generated")
truthy(reloaded, "get reloaded actor")
equal(reloaded.identity.displayName, created.identity.displayName,
    "stable generated name")
equal(reloaded.identity.survivor.voiceProfile.voicePitch,
    created.identity.survivor.voiceProfile.voicePitch, "stable generated voice")
equal(reloaded.appearance.resolved.outfit, created.appearance.resolved.outfit,
    "stable generated appearance")

local duplicate, duplicateReason = fresh:Register(created)
equal(duplicate, nil, "duplicate registration rejected")
equal(duplicateReason, "duplicate_actor_id", "duplicate reason")

local authoredSaved = generated:Save()
local authoredFresh = Actors.NewRegistry()
truthy(authoredFresh:Load(authoredSaved), "load authored registry")
local authoredReloaded = authoredFresh:Get("pnc:test:authored")
equal(authoredReloaded.appearance.policy.slots.Torso_Upper.type,
    "Base.Jacket", "authored policy survives reload")
equal(authoredReloaded.identity.survivor.voiceProfile.voiceType, 3,
    "authored voice survives reload")
equal(authoredReloaded.extensions["test:fixture"].preserved, true,
    "namespaced extension survives reload")

local invalid, invalidReason = fresh:Create({ actorId = " " })
equal(invalid, nil, "invalid actor rejected")
equal(invalidReason, "actor_id_required", "invalid actor reason")

equal(package.loaded["PNC/Core/Identity/PNC_Identity_Factory"], nil,
    "Core actor does not load Hoomans identity")
equal(package.loaded["DTCommon/DTCommon_TraderService"], nil,
    "Core actor does not load DynamicTrading")

print("psychopatz_npc_actor_smoke: PASS")
