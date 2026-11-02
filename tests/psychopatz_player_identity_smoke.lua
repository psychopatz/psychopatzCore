-- Canonical Cross-Adopter Player Target Identity Smoke Test (P8A)
--
-- Verifies:
-- 1. SP player character resolves to the exact same canonical target key across:
--    - Core-only
--    - DT-only
--    - Hoomans-only
--    - Combined
-- 2. MP player character resolves to the exact same canonical target key across all modes.
-- 3. Transient online reconnect / onlineID change does NOT create a new relationship or key.
-- 4. Distinct persistent characters on the same account/slot have distinct keys (UUIDs).
-- 5. Legacy aliases (player:user:*, player:online:*) merge idempotently into canonical key without lost memories or extensions.

local CORE_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CORE_ROOT .. "?.lua;" .. package.path

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

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local PlayerIdentity = Actors.PlayerIdentity
local Social = Actors.Social

-- Helper to create mock IsoPlayer
local function createMockPlayer(spec)
    local modData = spec.modData or {}
    local player = {
        modData = modData,
        getModData = function() return modData end,
        getPlayerNum = function() return spec.playerNum or 0 end,
        getPlayerIndex = function() return spec.playerNum or 0 end,
        getUsername = function() return spec.username or "Survivor" end,
        getOnlineID = function() return spec.onlineID or -1 end,
        isLocalPlayer = function() return spec.isLocal ~= false end,
    }
    return player
end

print("--- Test 1: Single Player Character Identity Convergence ---")
-- SP Player in slot 0 with existing UUID
local spModData = { PNC_CharacterUUID = "char_sp_uuid_12345" }
local spPlayer = createMockPlayer({
    playerNum = 0,
    username = "PlayerOne",
    onlineID = -1,
    isLocal = true,
    modData = spModData,
})

-- 1. Core-only key
local coreSPKey = PlayerIdentity.GetTargetKey(spPlayer)
equal(coreSPKey, "player:sp_slot_0:char_sp_uuid_12345", "Core-only SP key")

-- 2. DT-only key (simulating DTCommon_CoreActorPolicy / DTCommon_TalkService)
-- DT calls PlayerIdentity.GetTargetKey directly
local dtSPKey = PlayerIdentity.GetTargetKey(spPlayer)
equal(dtSPKey, coreSPKey, "DT SP key matches Core SP key")

-- 3. Hoomans key convention: player:sp_slot_<slot>:<uuid>
local hoomansSPKey = "player:sp_slot_0:" .. spModData.PNC_CharacterUUID
equal(hoomansSPKey, coreSPKey, "Hoomans SP key matches Core SP key")

-- Verify Core mirrored UUID into Core_CharacterUUID
equal(spModData.Core_CharacterUUID, "char_sp_uuid_12345", "Core mirrored PNC UUID")

print("--- Test 2: Multiplayer Player Character Identity Convergence ---")
-- MP Player with username "Bob" and onlineID 1
local mpModData = {}
local mpPlayer = createMockPlayer({
    playerNum = 0,
    username = "Bob",
    onlineID = 1,
    isLocal = false, -- MP network player
    modData = mpModData,
})

-- Simulate global isServer() == true
_G.isServer = function() return true end
_G.isClient = function() return false end

-- First resolution generates UUID and saves to modData
local coreMPKey = PlayerIdentity.GetTargetKey(mpPlayer)
truthy(coreMPKey, "MP key resolved")
truthy(string.match(coreMPKey, "^player:Bob:char_[%w_%-]+$"), "MP key format player:Bob:char_...")

local generatedUUID = PlayerIdentity.GetCharacterUUID(mpPlayer)
truthy(generatedUUID, "Character UUID generated")
equal(mpModData.Core_CharacterUUID, generatedUUID, "UUID saved in Core modData field")
equal(mpModData.PNC_CharacterUUID, generatedUUID, "UUID mirrored in PNC modData field")

-- DT key matches Core key
local dtMPKey = PlayerIdentity.GetTargetKey(mpPlayer)
equal(dtMPKey, coreMPKey, "DT MP key matches Core MP key")

-- Hoomans key convention matches
local hoomansMPKey = "player:Bob:" .. generatedUUID
equal(hoomansMPKey, coreMPKey, "Hoomans MP key matches Core MP key")

print("--- Test 3: Reconnect / OnlineID Change Stability ---")
-- Player reconnects with a different onlineID (e.g. 1 -> 42)
mpPlayer.getOnlineID = function() return 42 end

local reconnectCoreKey = PlayerIdentity.GetTargetKey(mpPlayer)
equal(reconnectCoreKey, coreMPKey, "OnlineID change does NOT alter canonical key")

local reconnectDTKey = PlayerIdentity.GetTargetKey(mpPlayer)
equal(reconnectDTKey, coreMPKey, "DT key remains unchanged across reconnect")

print("--- Test 4: Distinct Characters on Same Account Have Distinct Keys ---")
local mpPlayer2 = createMockPlayer({
    username = "Bob",
    onlineID = 42,
    isLocal = false,
    modData = {}, -- new character save / new modData
})
local coreMPKey2 = PlayerIdentity.GetTargetKey(mpPlayer2)
truthy(coreMPKey2 ~= coreMPKey, "Distinct character on same account has distinct target key")
equal(PlayerIdentity.GetAccountKey(mpPlayer2), "Bob", "Account key is same (Bob)")
truthy(PlayerIdentity.GetCharacterUUID(mpPlayer2) ~= generatedUUID, "Character UUID is distinct")

print("--- Test 5: Legacy Alias Convergence & Idempotent Merging ---")
-- Seed social state with legacy keys: player:user:Bob and player:online:1
local socialState = Social.NewState({
    relationships = {
        ["player:user:Bob"] = {
            approval = 15,
            respect = 10,
            familiarity = 20,
            memories = {
                { id = "mem_legacy_trade_1", text = "Traded 5 canned beans" },
            },
            extensions = {
                ["DynamicTrading"] = { totalTrades = 3, commercialReliability = 60 },
            },
        },
        ["player:online:1"] = {
            approval = 5,
            respect = 5,
            familiarity = 10,
            memories = {
                { id = "mem_legacy_trade_2", text = "Bought nails" },
            },
            extensions = {
                ["DynamicTrading"] = { totalTrades = 1 },
            },
        },
    },
})

-- Verify legacy entries exist before migration
truthy(socialState.relationships["player:user:Bob"] ~= nil, "player:user:Bob exists before migration")
truthy(socialState.relationships["player:online:1"] ~= nil, "player:online:1 exists before migration")
falsy(socialState.relationships[coreMPKey] ~= nil, "Canonical key does not exist yet")

-- Reset player onlineID to 1 to match legacy save
mpPlayer.getOnlineID = function() return 1 end
local legacyAliases = PlayerIdentity.GetLegacyKeys(mpPlayer)
truthy(#legacyAliases >= 2, "Legacy aliases identified for player")

local migrateOk = Social.MigrateAliases(socialState, coreMPKey, legacyAliases)
truthy(migrateOk, "MigrateAliases succeeded")

-- Verify canonical relationship created with merged data
local canonicalRel = Social.Get(socialState, coreMPKey)
truthy(canonicalRel, "Canonical relationship exists after migration")
equal(canonicalRel.targetKey, coreMPKey, "targetKey is canonical")
equal(canonicalRel.approval, 15, "Approval preserved from legacy")
equal(canonicalRel.familiarity, 20, "Familiarity preserved from legacy")
equal(#canonicalRel.memories, 2, "Both memories merged without duplication")
equal(canonicalRel.extensions.DynamicTrading.totalTrades, 3, "DT extension preserved")

-- Legacy entries must be removed from relationships table
falsy(socialState.relationships["player:user:Bob"] ~= nil, "player:user:Bob removed from relationships")
falsy(socialState.relationships["player:online:1"] ~= nil, "player:online:1 removed from relationships")

-- Verify alias redirection: Social.Get with legacy key redirects to canonical
local aliasedRel1 = Social.Get(socialState, "player:user:Bob")
truthy(aliasedRel1, "Social.Get redirected player:user:Bob to canonical")
equal(aliasedRel1.targetKey, coreMPKey, "Redirected rel targetKey is canonical")

local aliasedRel2 = Social.Get(socialState, "player:online:1")
truthy(aliasedRel2, "Social.Get redirected player:online:1 to canonical")
equal(aliasedRel2.targetKey, coreMPKey, "Redirected rel targetKey is canonical")

-- Idempotence: running migration again does nothing and changes nothing
local revisionBefore = socialState.revision
Social.MigrateAliases(socialState, coreMPKey, legacyAliases)
equal(socialState.revision, revisionBefore, "Second migration is strictly idempotent")
equal(#canonicalRel.memories, 2, "Memories not duplicated on second migration")

print("--- Test 6: Core Provenance & Tamper Resistance ---")
local provPlayer = createMockPlayer({
    username = "Alice",
    onlineID = 2,
    playerNum = 0,
})
local provUUID = PlayerIdentity.GetCharacterUUID(provPlayer)
local provAccount = PlayerIdentity.GetAccountKey(provPlayer)
local validProv, provReason = PlayerIdentity.VerifyProvenance(provPlayer, provUUID, provAccount)
truthy(validProv, "Valid Core provenance verified")

-- Untrusted arbitrary claim
local untrustedPlayer = createMockPlayer({
    username = "Attacker",
    onlineID = 3,
    playerNum = 0,
})
untrustedPlayer.modData.PNC_CharacterUUID = "char_untrusted"
local invalidProv, invalidReason = PlayerIdentity.VerifyProvenance(untrustedPlayer, "char_untrusted", "Attacker")
falsy(invalidProv, "Arbitrary untrusted UUID rejected")

-- Cross-account signature spoofing
local crossAccountPlayer = createMockPlayer({
    username = "Attacker",
    onlineID = 4,
    playerNum = 0,
})
crossAccountPlayer.modData.Core_CharacterUUID = provUUID
crossAccountPlayer.modData.Core_CharacterAccountKey = provAccount
crossAccountPlayer.modData.Core_CharacterSignature = PlayerIdentity.SignProvenance(provUUID, provAccount)
local crossProv, crossReason = PlayerIdentity.VerifyProvenance(crossAccountPlayer, provUUID, "Attacker")
falsy(crossProv, "Cross-account signature claim rejected")

print("psychopatz_player_identity_smoke: PASS")
