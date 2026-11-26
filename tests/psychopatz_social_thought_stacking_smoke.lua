local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.layerRoot("common_shared")
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function near(actual, expected, eps, label)
    if math.abs((tonumber(actual) or 0) - expected) > (eps or 0.001) then
        error((label or "near") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social

-- 1. stackedEffectMultiplier diminishes repeated consolidated memory deltas; stackLimit caps stacks
local state = Social.NewState({ personality = { forgiveness = 0.0, sociability = 0.0 } })
local target = "player:acc1:char_stack"

local function recordPraise(idx, extra)
    local ev = {
        targetKey = target,
        eventID = "ev:stack:" .. tostring(idx),
        type = "social.stacked_praise",
        retentionClass = Social.RETENTION_SHORT,
        consolidationFamily = "praise",
        salience = 120,
        approvalDelta = 8,
        respectDelta = 4,
        familiarityDelta = 2,
        stackLimit = 3,
        stackedEffectMultiplier = 0.5,
        createdAt = 10 + idx,
        worldAgeHours = 10 + idx,
        authority = "server",
        authorized = true,
    }
    if type(extra) == "table" then
        for k, v in pairs(extra) do ev[k] = v end
    end
    local updated, err = Social.RecordAuthorizedEvent(state, ev)
    truthy(updated, "RecordAuthorizedEvent failed: " .. tostring(err))
    state = updated
end

-- Stack 1: full 8 approval
recordPraise(1)
local rel = Social.Get(state, target)
near(rel.approval, 8.0, 0.001, "stack 1 applies full approval")
equal(rel.memories[1].count, 1, "stack 1 count=1")

-- Stack 2: 8 * 0.5^1 = 4 -> total 12
recordPraise(2)
rel = Social.Get(state, target)
near(rel.approval, 12.0, 0.001, "stack 2 applies 0.5x diminished delta")
equal(rel.memories[1].count, 2, "stack 2 count=2")

-- Stack 3: 8 * 0.5^2 = 2 -> total 14
recordPraise(3)
rel = Social.Get(state, target)
near(rel.approval, 14.0, 0.001, "stack 3 applies 0.25x diminished delta")
equal(rel.memories[1].count, 3, "stack 3 count=3")

-- Stack 4: capped at stackLimit=3 -> 0 extra delta, count remains 3
recordPraise(4)
rel = Social.Get(state, target)
near(rel.approval, 14.0, 0.001, "stack 4 hits stackLimit=3 and adds 0 delta")
equal(rel.memories[1].count, 3, "stack 4 preserves count=3 cap")

-- 2. nullifyingTraits skips mutation & memory insertion while still deduping eventID
local nullifiedState = Social.NewState({
    personality = { traits = { "Cynical" } },
})
local nullTarget = "player:acc1:char_null"
local afterNull, nullErr = Social.RecordAuthorizedEvent(nullifiedState, {
    targetKey = nullTarget,
    eventID = "ev:null:1",
    type = "social.stacked_praise",
    retentionClass = Social.RETENTION_SHORT,
    approvalDelta = 10,
    nullifyingTraits = { "Callous", "cynical" },
    createdAt = 50,
    worldAgeHours = 50,
    authority = "server",
    authorized = true,
})
truthy(afterNull, "nullified event returns state cleanly: " .. tostring(nullErr))
equal(Social.Get(afterNull, nullTarget), nil,
    "nullifyingTraits prevents relationship/memory creation")
local _, dupErr = Social.RecordAuthorizedEvent(afterNull, {
    targetKey = nullTarget,
    eventID = "ev:null:1",
    type = "social.stacked_praise",
    retentionClass = Social.RETENTION_SHORT,
    approvalDelta = 10,
    createdAt = 51,
    worldAgeHours = 51,
    authority = "server",
    authorized = true,
})
equal(dupErr, "duplicate_event", "nullified event still records dedupe eventID")

-- Also test event.actorTraits pathway
local afterActorTrait, actorErr = Social.RecordAuthorizedEvent(Social.NewState({}), {
    targetKey = nullTarget,
    eventID = "ev:null:actor:1",
    type = "social.stacked_praise",
    retentionClass = Social.RETENTION_SHORT,
    approvalDelta = 10,
    nullifyingTraits = { "Callous" },
    actorTraits = { Callous = true },
    createdAt = 60,
    worldAgeHours = 60,
    authority = "server",
    authorized = true,
})
truthy(afterActorTrait, "actorTraits nullification returns state: " .. tostring(actorErr))
equal(Social.Get(afterActorTrait, nullTarget), nil,
    "event.actorTraits triggers nullification")

print("PASS psychopatz_social_thought_stacking_smoke")
