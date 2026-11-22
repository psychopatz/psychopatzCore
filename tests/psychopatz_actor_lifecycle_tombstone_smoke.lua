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

local function falsy(value, label)
    if value then error(label or "expected falsy") end
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
}

local serverFlag = true
local clientFlag = false
isServer = function() return serverFlag end
isClient = function() return clientFlag end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Lifecycle = Actors.Lifecycle
local Identity = Actors.Identity
local PlayerIdentity = Actors.PlayerIdentity
local Persistence = Actors.Persistence
equal(Actors.Migration, nil, "retired Actors.Migration absent")
local RuntimeStore = Actors.RuntimeStore
local Social = Actors.Social
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

PlayerIdentity.Reset()

local reg = Actors.NewRegistry()

-- 1. Create live NPC actor with rich state + aliases + social graph
local social = Social.NewState({
    relationships = {
        ["actor:friend:1"] = {
            approval = 45,
            respect = 30,
            familiarity = 60,
            memories = {
                { id = "mem:1", type = "saved_life", retentionClass = "ANCHOR", salience = 220 },
            },
        },
    },
})
local alice = assert(reg:Create({
    actorId = "actor:l1:alice",
    ownerMod = "ProjectHoomans",
    identitySeed = "l1-alice",
    identity = { displayName = "Alice Mercer" },
    source = { npcID = "hoomans_alice_01" },
    extensions = {
        [Identity.EXTENSION] = {
            aliases = { "legacy:alice" },
            providerID = "ProjectHoomans",
            presenceState = "materialized",
        },
    },
    providerLease = {
        provider = "ProjectHoomans",
        owner = "pnc:runtime",
        state = "materialized",
        bodyID = "zombie:alice:1",
    },
    social = social,
    world = { position = { x = 1200, y = 2400, z = 0 } },
}))

equal(alice.lifecycleRevision, 1, "new actor starts with lifecycleRevision == 1")
local liveProj = assert(reg:ProjectIdentity(alice.actorId))
equal(liveProj.status, "LIVE", "live actor identity projection status")
equal(liveProj.lifecycleRevision, 1, "live projection lifecycleRevision")
equal(liveProj.displayName, "Alice Mercer", "live projection displayName")
equal(liveProj.hasTombstone, false, "live projection hasTombstone")

-- 2. Stale revision & materialized lease & client rejection
local staleLife, staleLifeErr = reg:Retire(alice.actorId, {
    authority = "server",
    expectedLifecycleRevision = 99,
})
equal(staleLife, nil, "stale expectedLifecycleRevision rejected")
equal(staleLifeErr, "lifecycle_revision_conflict", "stale lifecycle revision reason")

local staleActor, staleActorErr = reg:Retire(alice.actorId, {
    authority = "server",
    expectedActorRevision = 999,
})
equal(staleActor, nil, "stale expectedActorRevision rejected")
equal(staleActorErr, "revision_conflict", "stale actor revision reason")

local activeBodyRes, activeBodyErr = reg:Retire(alice.actorId, {
    authority = "server",
    requireReleasedLease = true,
})
equal(activeBodyRes, nil, "requireReleasedLease blocks active materialized body")
equal(activeBodyErr, "body_lease_active", "active body reason")

local clientOptRes, clientOptErr = reg:Retire(alice.actorId, { authority = "client" })
equal(clientOptRes, nil, "explicit client authority option rejected")
equal(clientOptErr, "server_authority_required", "explicit client authority error")

serverFlag = false
clientFlag = true
local pureClientRes, pureClientErr = reg:Retire(alice.actorId, { authority = "server" })
equal(pureClientRes, nil, "pure client runtime rejected even with server flag")
equal(pureClientErr, "server_authority_required", "pure client rejection reason")
serverFlag = true
clientFlag = false

-- 3. Retire live NPC -> full live state released, compact tombstone created
local ts, retireErr = reg:Retire(alice.actorId, {
    authority = "server",
    retiredAt = 480.5,
    graceHours = 168,
    reason = "death",
    role = "medic",
})
truthy(ts, retireErr)
equal(reg:Has(alice.actorId), false, "live record deleted after Retire")
equal(reg:HasReference("legacy:alice"), false, "live identity index cleared after Retire")
equal(reg:Count(), 0, "live actor count drops to 0")
equal(reg:TombstoneCount(), 1, "tombstone count becomes 1")

local tsJson = assert(Json.Encode(ts))
truthy(#tsJson <= 300, "tombstone JSON stays compact (" .. #tsJson .. " B <= 300)")
equal(ts.ref, alice.actorId, "tombstone canonical ref")
equal(ts.kind, "npc", "tombstone kind")
equal(ts.label, "Alice Mercer", "tombstone label")
equal(ts.owner, "ProjectHoomans", "tombstone owner")
equal(ts.rev, 2, "tombstone lifecycleRevision increments to 2")
equal(ts.graceUntil, 480.5 + 168, "tombstone graceUntil computed")
equal(ts.personalInventory, nil, "tombstone retains no inventory")
equal(ts.social, nil, "tombstone retains no outgoing social")
equal(ts.knowledge, nil, "tombstone retains no knowledge")
equal(ts.appearance, nil, "tombstone retains no appearance")

-- Tombstone alias and npc:/actor: prefix resolution
local retiredProj = assert(reg:ProjectIdentity("npc:" .. alice.actorId))
equal(retiredProj.status, "RETIRED", "npc: prefixed lookup resolves retired projection")
equal(retiredProj.displayName, "Alice Mercer", "retired projection preserves label")
equal(retiredProj.lifecycleRevision, 2, "retired projection carries tombstone rev")
equal(retiredProj.hasTombstone, true, "retired projection reports tombstone")
local aliasProj = assert(reg:ProjectIdentity("legacy:alice"))
equal(aliasProj.ref, alice.actorId, "legacy alias resolves to retired tombstone")

-- Cannot double-retire unless allowAlreadyRetired, and cannot re-register over tombstone
local dupRetire, dupRetireErr = reg:Retire(alice.actorId, { authority = "server" })
equal(dupRetire, nil, "double retire rejected by default")
equal(dupRetireErr, "already_retired", "double retire reason")
local idemRetire, idemStatus = reg:Retire(alice.actorId, {
    authority = "server",
    allowAlreadyRetired = true,
})
truthy(idemRetire and idemStatus == "already_retired", "allowAlreadyRetired returns tombstone idempotently")

local reregRes, reregErr = reg:Create({
    actorId = alice.actorId,
    identitySeed = "l1-alice-clone",
})
equal(reregRes, nil, "cannot Create/Register over retired tombstone")
equal(reregErr, "actor_retired", "re-register over tombstone rejected reason")
local ensureRes, ensureErr = reg:Ensure({
    actorId = alice.actorId,
    identitySeed = "l1-alice-ensure",
})
equal(ensureRes, nil, "cannot Ensure over retired tombstone")
equal(ensureErr, "actor_retired", "ensure over tombstone rejected reason")

-- Forbidden/unknown tombstone fields fail validation
for _, badField in ipairs({
    "personalInventory", "social", "memories", "relationships",
    "knowledge", "appearance", "world", "providerLease", "stock", "budget",
}) do
    local badTs = {
        ref = "actor:bad",
        kind = "npc",
        retiredAt = 10,
        reason = "death",
        rev = 2,
        graceUntil = 178,
    }
    badTs[badField] = {}
    local validBad, badReason = Lifecycle.ValidateTombstone(badTs)
    falsy(validBad, "forbidden tombstone field rejected: " .. badField)
    equal(badReason, "tombstone_field_forbidden", "forbidden field error: " .. badField)
end

-- 4. Rollback HardDelete leaves NO tombstone
local rollbackActor = assert(reg:Create({
    actorId = "actor:l1:rollback_npc",
    identitySeed = "l1-rb",
}))
local badHd, badHdErr = reg:HardDelete(rollbackActor.actorId, { authority = "server" })
equal(badHd, nil, "HardDelete requires explicit valid reason")
equal(badHdErr, "hard_delete_reason_required", "HardDelete missing reason rejected")

serverFlag = false
clientFlag = true
local clientHd, clientHdErr = reg:HardDelete(rollbackActor.actorId, {
    authority = "server",
    reason = "rollback",
})
equal(clientHd, nil, "pure client HardDelete rejected")
equal(clientHdErr, "server_authority_required", "pure client HardDelete error")
serverFlag = true
clientFlag = false

assert(reg:HardDelete(rollbackActor.actorId, {
    authority = "server",
    reason = "rollback",
}))
equal(reg:Has(rollbackActor.actorId), false, "HardDelete removed live actor")
equal(reg:TombstoneCount(), 1, "HardDelete did NOT create a tombstone")
equal(reg:ProjectIdentity(rollbackActor.actorId).status, "FORGOTTEN",
    "hard-deleted rollback actor resolves as FORGOTTEN")

-- 5. Persistent player-character lifecycle without full NPC actor record
local playerModData = {}
local mockPlayer = {
    modData = playerModData,
    getModData = function() return playerModData end,
    getUsername = function() return "SurvivorL1" end,
    getOnlineID = function() return 7 end,
    isLocalPlayer = function() return false end,
}
local playerKey1 = assert(PlayerIdentity.GetTargetKey(mockPlayer))
local playerUUID1 = assert(PlayerIdentity.GetCharacterUUID(mockPlayer))
local pProjLive = assert(reg:ProjectIdentity(playerKey1))
equal(pProjLive.status, "LIVE", "player character starts LIVE")
equal(pProjLive.kind, "player", "player character kind")
equal(pProjLive.lifecycleRevision, 1, "player character starts at lifecycleRevision 1")

-- Cannot purge a LIVE player identity
local purgeLiveRes, purgeLiveErr = PlayerIdentity.PurgeRetiredIdentity(
    playerUUID1, "SurvivorL1", { authority = "server" }
)
falsy(purgeLiveRes, "cannot purge a LIVE player identity")
equal(purgeLiveErr, "identity_not_retired", "purge live identity error")

-- Retire player character (no entry in reg.records required!)
local pTombstone = assert(reg:Retire(playerKey1, {
    authority = "server",
    label = "SurvivorL1",
    retiredAt = 600,
    graceHours = 48,
    reason = "player_death",
}))
equal(pTombstone.kind, "player", "player tombstone kind")
equal(pTombstone.flags, Lifecycle.FLAG_PLAYER_CHARACTER, "player tombstone flag")
equal(pTombstone.rev, 2, "player tombstone rev")
equal(reg:TombstoneCount(), 2, "player retirement adds tombstone cleanly")

-- Dead player UUID cannot be re-claimed as live character
local stillIssued, issuedReason = PlayerIdentity.IsIssuedIdentity(playerUUID1, "SurvivorL1")
falsy(stillIssued, "retired player UUID cannot pass live IsIssuedIdentity check")
equal(issuedReason, "identity_retired", "retired player UUID check reason")
local stolenAttemptUUID = assert(PlayerIdentity.GetCharacterUUID(mockPlayer))
truthy(stolenAttemptUUID ~= playerUUID1, "player carrying retired UUID receives fresh character UUID")

local pProjRetired = assert(reg:ProjectIdentity(playerKey1))
equal(pProjRetired.status, "RETIRED", "retired player projection status")
equal(pProjRetired.displayName, "SurvivorL1", "retired player projection label")
equal(pProjRetired.lifecycleRevision, 2, "retired player projection lifecycleRevision")

-- 6. Persistence v3 save/reload + v2 migration + Kahlua _G.next=nil check
local originalNext = _G.next
_G.next = nil
local okSave, savedJson, saveErr = pcall(function()
    return reg:Save()
end)
_G.next = originalNext
truthy(okSave and savedJson, saveErr)
local decodedWrapper = assert(Json.Decode(savedJson))
equal(decodedWrapper.schemaVersion, 3, "registry saves as schemaVersion 3")
equal(#decodedWrapper.tombstones, 2, "both tombstones persisted")

local freshReg = Actors.NewRegistry()
local loadOk, loadErr = freshReg:Load(savedJson)
truthy(loadOk, loadErr)
equal(freshReg:Count(), 0, "fresh registry has 0 live actors")
equal(freshReg:TombstoneCount(), 2, "fresh registry restored both tombstones")
equal(freshReg:ProjectIdentity("legacy:alice").status, "RETIRED", "restored tombstone alias works")
equal(freshReg:ProjectIdentity(playerKey1).status, "RETIRED", "restored player tombstone works")

-- v2 legacy registry payload loads cleanly
local v2Reg = Actors.NewRegistry()
local v2Actor = assert(v2Reg:Create({
    actorId = "actor:l1:v2_legacy",
    identitySeed = "l1-v2",
}))
local v2Payload = assert(Json.Decode(assert(v2Reg:Save())))
v2Payload.schemaVersion = 2
v2Payload.tombstones = nil
v2Payload.lifecycleRevision = nil
local v2Json = assert(Json.Encode(v2Payload))
local migratedReg = Actors.NewRegistry()
assert(migratedReg:Load(v2Json))
equal(migratedReg:Get("actor:l1:v2_legacy").lifecycleRevision, 1,
    "v2 legacy actor defaults lifecycleRevision to 1")
local v2Resaved = assert(Json.Decode(assert(migratedReg:Save())))
equal(v2Resaved.schemaVersion, 3, "v2 payload upgrades to schemaVersion 3 on save")

-- Malformed/bloated persisted tombstone fails closed on DecodeRegistry
local corruptPayload = assert(Json.Decode(savedJson))
corruptPayload.tombstones[1].personalInventory = { stolen = true }
local badDecode, badDecodeErr = Persistence.DecodeRegistry(assert(Json.Encode(corruptPayload)))
equal(badDecode, nil, "bloated tombstone in persisted payload fails closed")
equal(badDecodeErr, "tombstone_field_forbidden", "bloated tombstone rejection reason")

-- RuntimeStore round-trip with tombstones
RuntimeStore.Attach(freshReg)
assert(RuntimeStore.Save())
local reloadedStoreReg = Actors.NewRegistry()
RuntimeStore.Attach(reloadedStoreReg)
equal(reloadedStoreReg:TombstoneCount(), 2, "RuntimeStore reload restores tombstones")

-- 7. PurgeTombstone transitions RETIRED -> FORGOTTEN and cleans PlayerIdentity
serverFlag = false
clientFlag = true
local clientPurge, clientPurgeErr = Lifecycle.PurgeTombstone(freshReg, alice.actorId, {
    authority = "server",
})
equal(clientPurge, nil, "client PurgeTombstone rejected")
equal(clientPurgeErr, "server_authority_required", "client purge error")
serverFlag = true
clientFlag = false

assert(Lifecycle.PurgeTombstone(freshReg, alice.actorId, { authority = "server" }))
equal(freshReg:ProjectIdentity(alice.actorId).status, "FORGOTTEN",
    "purged NPC resolves as FORGOTTEN")
equal(freshReg:ProjectIdentity("legacy:alice").status, "FORGOTTEN",
    "purged NPC alias resolves as FORGOTTEN")

assert(Lifecycle.PurgeTombstone(freshReg, playerKey1, { authority = "server" }))
equal(freshReg:ProjectIdentity(playerKey1).status, "FORGOTTEN",
    "purged player resolves as FORGOTTEN")
local afterPurgeIssued, afterPurgeReason = PlayerIdentity.IsIssuedIdentity(
    playerUUID1, "SurvivorL1", { includeRetired = true }
)
falsy(afterPurgeIssued, "purged player identity removed from PlayerIdentity storage")
equal(afterPurgeReason, "not_issued", "purged player identity not_issued")
equal(freshReg:TombstoneCount(), 0, "all tombstones purged cleanly")

print("PASS psychopatz_actor_lifecycle_tombstone_smoke")
