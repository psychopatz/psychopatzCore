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
local Social = Actors.Social

-- 1. Create state with top-level and relationship extensions
local state, stateReason = Social.NewState({
    personality = { patience = 0.5 },
    extensions = {
        ["ProjectHoomans"] = { morale = 45, conduct = { infractions = 0 } },
        ["DynamicTrading"] = { commercialReputation = 80 },
    },
    relationships = {
        ["npc:merchant:one"] = {
            approval = 20,
            respect = 10,
            familiarity = 15,
            extensions = {
                ["ProjectHoomans"] = {
                    bond = { class = "friend", stage = "established" },
                    cooldowns = { proposal = 120 },
                },
                ["DynamicTrading"] = {
                    commercialReliability = 95,
                    totalTrades = 12,
                },
            },
        },
    },
})
truthy(state, stateReason)

-- Verify extensions preserved in NewState
local topHoomans = Social.GetExtension(state, nil, "ProjectHoomans")
truthy(topHoomans, "top-level ProjectHoomans extension found")
equal(topHoomans.morale, 45, "morale preserved")
local topDT = Social.GetExtension(state, "", "DynamicTrading")
truthy(topDT, "top-level DynamicTrading extension found")
equal(topDT.commercialReputation, 80, "reputation preserved")

local relHoomans = Social.GetExtension(state, "npc:merchant:one", "ProjectHoomans")
truthy(relHoomans, "relationship ProjectHoomans extension found")
equal(relHoomans.bond.class, "friend", "bond class preserved")
local relDT = Social.GetExtension(state, "npc:merchant:one", "DynamicTrading")
truthy(relDT, "relationship DynamicTrading extension found")
equal(relDT.totalTrades, 12, "trades preserved")

-- 2. Authority requirement for SetExtension
local clientAttempt, clientReason = Social.SetExtension(
    state,
    "npc:merchant:one",
    "DynamicTrading",
    { totalTrades = 13 },
    "client"
)
equal(clientAttempt, nil, "client authority rejected")
equal(clientReason, "server_authority_required", "reason server_authority_required")

-- 3. Valid server SetExtension
local initialRev = state.revision
local updated, updateReason = Social.SetExtension(
    state,
    "npc:merchant:one",
    "DynamicTrading",
    { totalTrades = 13, commercialReliability = 96 },
    "server",
    initialRev
)
truthy(updated, updateReason)
equal(updated.revision, initialRev + 1, "state revision incremented")
local updatedRelDT = Social.GetExtension(updated, "npc:merchant:one", "DynamicTrading")
equal(updatedRelDT.totalTrades, 13, "trades updated to 13")
-- Verify other adopter's extension was NOT clobbered
local untouchedHoomans = Social.GetExtension(updated, "npc:merchant:one", "ProjectHoomans")
equal(untouchedHoomans.bond.class, "friend", "Hoomans extension untouched")

-- 4. RecordAuthorizedEvent does NOT erase extensions
local eventApplied, eventReason = Social.RecordAuthorizedEvent(updated, {
    targetKey = "npc:merchant:one",
    eventID = "event:trade:001",
    approvalDelta = 5,
    respectDelta = 2,
    familiarityDelta = 1,
    authority = "server",
    authorized = true,
})
truthy(eventApplied, eventReason)
local relAfterEvent = Social.Get(eventApplied, "npc:merchant:one")
equal(relAfterEvent.approval, 25, "approval delta applied")
truthy(relAfterEvent.extensions, "extensions table preserved on relationship")
truthy(relAfterEvent.extensions.ProjectHoomans, "Hoomans extension preserved after event")
equal(relAfterEvent.extensions.ProjectHoomans.bond.class, "friend", "Hoomans bond intact")
truthy(relAfterEvent.extensions.DynamicTrading, "DT extension preserved after event")
equal(relAfterEvent.extensions.DynamicTrading.totalTrades, 13, "DT trades intact")

-- 5. Export to payload and validation
local payload, payloadReason = Social.ToPayload(eventApplied)
truthy(payload, payloadReason)
local validated, valReason = Social.Validate(payload)
truthy(validated, valReason)
equal(payload.extensions.ProjectHoomans.morale, 45, "payload top-level extension intact")
equal(payload.relationships["npc:merchant:one"].extensions.ProjectHoomans.bond.class,
    "friend", "payload relationship extension intact")

-- 6. Extension deletion by passing payload = nil
local deleted, delReason = Social.SetExtension(
    eventApplied,
    "npc:merchant:one",
    "DynamicTrading",
    nil,
    "server"
)
truthy(deleted, delReason)
local missingExt = Social.GetExtension(deleted, "npc:merchant:one", "DynamicTrading")
equal(missingExt, nil, "extension removed")
local stillThereHoomans = Social.GetExtension(deleted, "npc:merchant:one", "ProjectHoomans")
truthy(stillThereHoomans, "other extension still present")

print("psychopatz_social_extension_smoke: PASS")
