local CORE_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local HOOM_ROOT = "../ProjectHoomans/Contents/mods/ProjectHoomans/common/media/lua/shared/"
local DT_ROOT = "../DynamicTrading/Contents/mods/DTCommon/common/media/lua/shared/"
package.path = CORE_ROOT .. "?.lua;" .. HOOM_ROOT .. "?.lua;" .. DT_ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local modDataStore = {}
ModData = {
    getOrCreate = function(key)
        modDataStore[key] = modDataStore[key] or {}
        return modDataStore[key]
    end,
    get = function(key)
        return modDataStore[key]
    end,
    transmit = function() end,
}

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    EveryDays = { Add = function() end },
}

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local SocialPolicy = require "PsychopatzCore/Actors/PsychopatzSocialPolicy"
local Authority = require "PsychopatzCore/Actors/PsychopatzActorSocialAuthority"
local GC = require "PsychopatzCore/Actors/PsychopatzActorGC"

require "PNC/SocialPolicy/Registry"
require "DTCommon/SocialPolicy/Registry"

-- 1. Verify compiled policy metadata across Core, ProjectHoomans, and DTCommon
local greetingSpec = assert(SocialPolicy.Resolve("social.greeting"))
equal(greetingSpec.refStrength, "WEAK", "Core greeting refStrength")
equal(greetingSpec.references.degradeOnPurge, "DROP", "Core greeting degradeOnPurge")

local assistanceSpec = assert(SocialPolicy.Resolve("social.assistance"))
equal(assistanceSpec.refStrength, "WEAK", "Core assistance refStrength")
equal(assistanceSpec.sourceRefStrength, "WEAK", "Core assistance sourceRefStrength")
equal(assistanceSpec.references.degradeOnPurge, "LABEL_ONLY", "Core assistance degradeOnPurge")

local betrayalSpec = assert(SocialPolicy.Resolve("social.betrayal_anchor"))
equal(betrayalSpec.refStrength, "STRONG", "Core betrayal refStrength")
equal(betrayalSpec.sourceRefStrength, "WEAK", "Core betrayal sourceRefStrength")
equal(betrayalSpec.references.maxStrongRefs, 1, "Core betrayal maxStrongRefs")
equal(betrayalSpec.references.degradeOnPurge, "KEEP_HISTORICAL", "Core betrayal degradeOnPurge")

local woundSpec = assert(SocialPolicy.Resolve("treated_wound"))
equal(woundSpec.refStrength, "WEAK", "Hoomans treated_wound refStrength")

local friendshipSpec = assert(SocialPolicy.Resolve("friendship_established"))
equal(friendshipSpec.refStrength, "STRONG", "Hoomans friendship_established refStrength")
equal(friendshipSpec.sourceRefStrength, "WEAK", "Hoomans friendship sourceRefStrength")

local tradeSpec = assert(SocialPolicy.Resolve("commercial_trade"))
equal(tradeSpec.refStrength, "WEAK", "DT commercial_trade refStrength")
equal(tradeSpec.references.degradeOnPurge, "LABEL_ONLY", "DT commercial_trade degradeOnPurge")

local dtBetraySpec = assert(SocialPolicy.Resolve("trade.betrayal_or_hostile"))
equal(dtBetraySpec.refStrength, "STRONG", "DT betrayal refStrength")
equal(dtBetraySpec.sourceRefStrength, "WEAK", "DT betrayal sourceRefStrength")

-- 2. RecordAuthorizedEvent inherits refStrength and sourceRefStrength from policy + invalid fails closed
local state = Social.NewState()
state = assert(Social.RecordAuthorizedEvent(state, {
    targetKey = "player:acc1:cust1",
    eventID = "ev:pol:trade1",
    type = "commercial_trade",
    sourceMode = "direct",
    createdAt = 10,
    authority = "server",
    authorized = true,
}))
equal(state.memoryBank[1].refStrength, "WEAK", "commercial_trade memory inherits policy refStrength=WEAK")

local badState, badReason = Social.RecordAuthorizedEvent(state, {
    targetKey = "player:acc1:cust1",
    eventID = "ev:pol:bad",
    type = "commercial_trade",
    refStrength = "BOGUS",
    createdAt = 11,
    authority = "server",
    authorized = true,
})
equal(badState, nil, "invalid explicit refStrength rejected")
equal(badReason, "ref_strength_invalid", "invalid refStrength failure reason")

-- 3. GC enforces compiled policy reference strengths
local reg = Actors.NewRegistry()
local deadCustomer = assert(reg:Create({ actorId = "actor:l4:dead_cust", identitySeed = "dc" }))
local deadBetrayer = assert(reg:Create({ actorId = "actor:l4:dead_betrayer", identitySeed = "db" }))
local deadInformant = assert(reg:Create({ actorId = "actor:l4:dead_informant", identitySeed = "di" }))
local observer = assert(reg:Create({ actorId = "actor:l4:observer", identitySeed = "obs" }))

local obsSocial = Social.NewState()
obsSocial = assert(Social.RecordAuthorizedEvent(obsSocial, {
    targetKey = deadCustomer.actorId,
    eventID = "ev:l4:trade",
    type = "commercial_trade",
    createdAt = 50,
    authority = "server",
    authorized = true,
}))
obsSocial = assert(Social.RecordAuthorizedEvent(obsSocial, {
    targetKey = deadBetrayer.actorId,
    eventID = "ev:l4:betray",
    type = "social.betrayal_anchor",
    sourceMode = "hearsay",
    sourceKey = deadInformant.actorId,
    createdAt = 50,
    authority = "server",
    authorized = true,
}))
observer = assert(Authority.CommitSocial(
    observer.actorId,
    obsSocial,
    { Actors = { DefaultRegistry = reg } },
    observer.revision
))

assert(reg:Retire(deadCustomer.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(reg:Retire(deadBetrayer.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))
assert(reg:Retire(deadInformant.actorId, { authority = "server", retiredAt = 50, graceHours = 24 }))

local gcRes = assert(GC.RunFull(reg, { authority = "server", now = 200 }))
equal(gcRes.purgedCount, 2, "deadCustomer (WEAK trade) and deadInformant (WEAK source) purged; deadBetrayer retained")
truthy(reg:GetTombstone(deadBetrayer.actorId), "STRONG betrayal policy retains deadBetrayer")
equal(reg:GetTombstone(deadCustomer.actorId), nil, "WEAK commercial_trade does NOT pin deadCustomer")
equal(reg:GetTombstone(deadInformant.actorId), nil, "WEAK sourceRefStrength does NOT pin deadInformant")

local updatedObserver = assert(reg:Get(observer.actorId))
equal(updatedObserver.social.relationships[deadCustomer.actorId], nil,
    "deadCustomer weak trade edge compacted on purge")
equal(#updatedObserver.social.memoryBank, 1, "only betrayal anchor remains after weak trade purged")
equal(updatedObserver.social.memoryBank[1].id, "ev:l4:betray")
equal(updatedObserver.social.memoryBank[1].sourceKey, nil, "weak informant sourceKey degraded on purge")
equal(updatedObserver.social.memoryBank[1].sourceDegraded, true, "sourceDegraded set on informant purge")

print("psychopatz_social_policy_reference_strength_smoke: PASS")
