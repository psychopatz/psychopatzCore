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

local playerDeathHandlers = {}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    EveryDays = { Add = function() end },
    OnPlayerDeath = {
        Add = function(fn)
            playerDeathHandlers[#playerDeathHandlers + 1] = fn
        end,
    },
}

local isServerFlag, isClientFlag = true, false
isServer = function() return isServerFlag end
isClient = function() return isClientFlag end
getGameTime = function()
    return { getWorldAgeHours = function() return 100 end }
end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local PlayerIdentity = require "PsychopatzCore/Actors/PsychopatzPlayerIdentity"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local Authority = require "PsychopatzCore/Actors/PsychopatzActorSocialAuthority"
local GC = require "PsychopatzCore/Actors/PsychopatzActorGC"
local Lifecycle = require "PsychopatzCore/Actors/PsychopatzActorLifecycle"

local reg = Actors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors
PsychopatzCore.Actors.DefaultRegistry = reg
Actors.DefaultRegistry = reg
PlayerIdentity.Reset()

local function makePlayer(opts)
    local md = opts.modData or {}
    return {
        getUsername = function() return opts.username end,
        getDisplayName = function() return opts.displayName end,
        getOnlineID = function() return opts.onlineID end,
        getPlayerNum = function() return opts.playerNum end,
        getModData = function() return md end,
        isLocalPlayer = function() return opts.localPlayer == true end,
    }
end

-- 1. MP player spawns & reconnects with changed onlineID -> exact same char1 & relationships
local playerA1 = makePlayer({ username = "acctA", displayName = "Alice One", onlineID = 10 })
local char1Key = assert(PlayerIdentity.GetTargetKey(playerA1))
local char1UUID = assert(PlayerIdentity.GetCharacterUUID(playerA1))

local playerA1Reconnect = makePlayer({
    username = "acctA",
    displayName = "Alice One",
    onlineID = 99,
    modData = playerA1:getModData(),
})
equal(PlayerIdentity.GetTargetKey(playerA1Reconnect), char1Key,
    "Reconnect with new onlineID keeps exact same canonical character key")
local validLive, liveInfo = PlayerIdentity.ValidateLiveInteraction(playerA1Reconnect)
truthy(validLive and liveInfo.status == "LIVE" and liveInfo.lifecycleRevision == 1,
    "Live player interaction validated at rev 1")

-- Surviving NPCs: one with STRONG anchor toward char1, one with WEAK trade toward char1
local strongNpc = assert(reg:Create({ actorId = "actor:l6:strong_friend", identitySeed = "l6-sf" }))
local weakNpc = assert(reg:Create({ actorId = "actor:l6:weak_trader", identitySeed = "l6-wt" }))
assert(Authority.RecordAuthorizedEvent(strongNpc.actorId, {
    targetKey = char1Key,
    eventID = "ev:l6:oath",
    type = "social.betrayal_anchor",
    retentionClass = Social.RETENTION_ANCHOR,
    refStrength = Social.REF_STRONG,
    salience = 230,
    approvalDelta = -60,
    createdAt = 20,
    authority = "server",
    authorized = true,
}, { Actors = { DefaultRegistry = reg } }, strongNpc.revision))
assert(Authority.RecordAuthorizedEvent(weakNpc.actorId, {
    targetKey = char1Key,
    eventID = "ev:l6:chat",
    type = "commercial_trade",
    retentionClass = Social.RETENTION_LONG,
    refStrength = Social.REF_WEAK,
    approvalDelta = 2,
    createdAt = 20,
    authority = "server",
    authorized = true,
}, { Actors = { DefaultRegistry = reg } }, weakNpc.revision))

-- 2. Authoritative death retires char1; client mutation & stale expectedRevision fail closed
local cliRetire, cliErr = PlayerIdentity.RetirePlayerCharacter(playerA1Reconnect, {
    authority = "client",
})
equal(cliRetire, nil)
equal(cliErr, "server_authority_required", "Client retirement rejected")

local staleRetire, staleErr = PlayerIdentity.RetirePlayerCharacter(playerA1Reconnect, {
    authority = "server",
    expectedLifecycleRevision = 99,
})
equal(staleRetire, nil)
equal(staleErr, "lifecycle_revision_conflict", "Stale expectedLifecycleRevision rejected")

local deadTs, retireErr = PlayerIdentity.RetirePlayerCharacter(playerA1Reconnect, {
    authority = "server",
    reason = "player_death",
    retiredAt = 100,
    graceHours = 24,
})
truthy(deadTs, "Authoritative RetirePlayerCharacter succeeded: " .. tostring(retireErr))
equal(deadTs.kind, "player")
equal(deadTs.rev, 2)

local liveAfterDeath, liveAfterErr = PlayerIdentity.ValidateLiveInteraction(playerA1Reconnect)
equal(liveAfterDeath, false)
equal(liveAfterErr, "actor_retired", "Dead player rejected for live interactions")

local staleRevValid, staleRevErr = PlayerIdentity.ValidateLiveInteraction(char1Key, {
    expectedLifecycleRevision = 1,
})
equal(staleRevValid, false)
equal(staleRevErr, "actor_retired", "Dead player fails live validation cleanly")

-- Firing Events.OnPlayerDeath on already-dead player is idempotent
truthy(#playerDeathHandlers >= 1, "OnPlayerDeath hook registered")
playerDeathHandlers[1](playerA1Reconnect)
equal(reg:GetTombstone(char1Key).rev, 2, "Idempotent second death does not fork or bump rev")

-- 3. Same account respawns char2 -> distinct key, ZERO relationship transfer, spoofed dead UUID rejected
local playerA2 = makePlayer({ username = "acctA", displayName = "Alice Two", onlineID = 105 })
local char2Key = assert(PlayerIdentity.GetTargetKey(playerA2))
local char2UUID = assert(PlayerIdentity.GetCharacterUUID(playerA2))
truthy(char2Key ~= char1Key and char2UUID ~= char1UUID,
    "New character on same account gets fresh UUID and canonical key")

local strongNpcState = assert(reg:Get(strongNpc.actorId))
local relChar2, relChar2Err = Social.Get(strongNpcState.social, char2Key)
equal(relChar2, nil, "No automatic relationship transfer from dead char1 to new char2")
equal(relChar2Err, "relationship_not_found")
local relChar1 = assert(Social.Get(strongNpcState.social, char1Key))
equal(relChar1.approval, -60, "Survivor historical consequences toward dead char1 survive")

-- Attempting to verify spoofed/dead char1 provenance fails closed, and calling GetCharacterUUID
-- on a player carrying a retired UUID mints a new UUID instead of reviving dead char1
local spoofedDeadPlayer = makePlayer({
    username = "acctA",
    displayName = "Zombie Spoof",
    onlineID = 106,
    modData = {
        [PlayerIdentity.MODDATA_CORE_UUID] = char1UUID,
        [PlayerIdentity.MODDATA_PNC_UUID] = char1UUID,
        [PlayerIdentity.MODDATA_CORE_ACCOUNT] = "acctA",
        [PlayerIdentity.MODDATA_CORE_SIGNATURE] = playerA1:getModData()[PlayerIdentity.MODDATA_CORE_SIGNATURE],
    },
})
local provDeadOK, provDeadErr = PlayerIdentity.VerifyProvenance(spoofedDeadPlayer, char1UUID, "acctA")
equal(provDeadOK, false)
equal(provDeadErr, "identity_retired", "Retired UUID fails VerifyProvenance")
local recoveredUUID = assert(PlayerIdentity.GetCharacterUUID(spoofedDeadPlayer))
truthy(recoveredUUID ~= char1UUID, "GetCharacterUUID never revives a retired UUID")

-- Cross-account isolation: Account B claiming Account A's live char2 UUID rejected
local accountBSpoof = makePlayer({
    username = "acctB",
    displayName = "Mallory",
    onlineID = 200,
    modData = {
        [PlayerIdentity.MODDATA_CORE_UUID] = char2UUID,
        [PlayerIdentity.MODDATA_CORE_ACCOUNT] = "acctB",
        [PlayerIdentity.MODDATA_CORE_SIGNATURE] = PlayerIdentity.SignProvenance(char2UUID, "acctB"),
    },
})
local crossOK, crossErr = PlayerIdentity.VerifyProvenance(accountBSpoof, char2UUID, "acctB")
equal(crossOK, false)
equal(crossErr, "account_mismatch", "Cross-account UUID claim fails closed")
local crossInteractOK, crossInteractErr = PlayerIdentity.ValidateLiveInteraction(char2Key, {
    expectedAccountKey = "acctB",
})
equal(crossInteractOK, false)
equal(crossInteractErr, "account_mismatch")

-- 4. GC retains char1 while strong anchor exists; after anchor removed & grace elapses, char1 purges
local gc1 = assert(GC.RunFull(reg, { authority = "server", now = 200 }))
equal(gc1.purgedCount, 0)
truthy(reg:GetTombstone(char1Key), "STRONG survivor anchor retains char1 player tombstone")

-- Now clear strongNpc's betrayal memory & significant edge, then run GC again
strongNpc = assert(Authority.RemoveMemory(strongNpc.actorId, "ev:l6:oath",
    { Actors = { DefaultRegistry = reg } }, strongNpcState.revision))
strongNpc = assert(Authority.CommitSocial(strongNpc.actorId, Social.NewState(),
    { Actors = { DefaultRegistry = reg } }, strongNpc.revision))

local gc2 = assert(GC.RunFull(reg, { authority = "server", now = 200 }))
equal(gc2.purgedCount, 1, "char1 player tombstone purged once strong anchor gone & grace elapsed")
equal(reg:GetTombstone(char1Key), nil, "char1 tombstone removed")
local pStatus, _ = Lifecycle.GetLifecycleState(reg, char1Key)
equal(pStatus, "FORGOTTEN", "char1 lifecycle reaches FORGOTTEN after purge")

local weakAfterPurge = assert(reg:Get(weakNpc.actorId))
equal(weakAfterPurge.social.relationships[char1Key], nil,
    "Weak commercial edge to purged player compacted away")

-- 5. SP isolation + _G.next=nil Save/Load roundtrip parity
isServerFlag, isClientFlag = false, false
local spSlot0 = makePlayer({ playerNum = 0, localPlayer = true, displayName = "SP Hero" })
local spKey = assert(PlayerIdentity.GetTargetKey(spSlot0))
truthy(string.find(spKey, "^player:sp_slot_0:char_") ~= nil, "SP uses sp_slot_0 namespace")
assert(PlayerIdentity.RetirePlayerCharacter(spSlot0, { reason = "player_death", retiredAt = 300 }))
truthy(reg:GetTombstone(spKey), "SP death also creates compact player tombstone")

local realNext = _G.next
_G.next = nil
local okSave, savedReg = pcall(function() return reg:Save() end)
local okIdSave, savedIdentities = pcall(function() return PlayerIdentity.Save() end)
_G.next = realNext
truthy(okSave and okIdSave, "Save works under _G.next = nil")

PlayerIdentity.Reset()
PlayerIdentity.Load(savedIdentities)
local reloaded = Actors.NewRegistry()
truthy(reloaded:Load(savedReg))
truthy(reloaded:GetTombstone(spKey), "Reloaded registry preserves SP player tombstone")
local spState, _ = Lifecycle.GetLifecycleState(reloaded, spKey)
equal(spState, "RETIRED", "Reloaded PlayerIdentity + Registry agree on RETIRED status")

print("psychopatz_player_character_lifecycle_mp_smoke: PASS")
