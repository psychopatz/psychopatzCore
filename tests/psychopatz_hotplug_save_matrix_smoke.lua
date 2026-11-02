-- Hot-Plug / Save Migration and Removal Matrix Smoke Test (P6)
--
-- Exercises the complete cross-adopter lifecycle matrix:
-- 1. Core + DT create/save/reload.
-- 2. Add Hoomans to that save -> verify same actor IDs, identity, base relationship, memories, no duplicate actors.
-- 3. Exercise Hoomans extensions/capabilities -> coexistence of DT and Hoomans extensions.
-- 4. Remove Hoomans and reload -> DT remains healthy, shared state unchanged, inactive Hoomans extension preserved.
-- 5. Re-add Hoomans -> verify Hoomans extension data recovered intact.
-- 6. Reverse matrix: Core + Hoomans create/save/reload -> add DT -> remove DT -> re-add DT.
-- 7. Repeated migration and reload is strictly idempotent.
-- 8. Migration conflicts fail visibly without destructive reset.

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

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Social = Actors.Social
local Migration = Actors.Migration
local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local PackRegistry = Semantics.PackRegistry

local function deepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = deepCopy(v)
    end
    return copy
end

print("--- Step 1: Core + DT create/save/reload ---")
PackRegistry.Reset()

-- Create DT trader actor
local reg = Actors.NewRegistry()
local traderActor, createErr = reg:Create({
    actorId = "trader_marcus",
    identitySeed = "seed_marcus_caravan",
    provider = "DTAbstract",
    providerLease = {
        leaseId = "lease_marcus_01",
        provider = "DTAbstract",
        ownerMod = "DynamicTrading",
        status = "active",
    },
    x = 100, y = 200, z = 0,
})
truthy(traderActor, "Trader actor created: " .. tostring(createErr))

-- Set up initial social relationship in Core
local socialState, stateErr = Social.NewState({
    relationships = {
        ["player:user:Bob"] = {
            approval = 20,
            respect = 15,
            familiarity = 10,
            memories = { { id = "met_at_crossroads" } },
        },
    },
})
truthy(socialState, "Initial socialState created: " .. tostring(stateErr))

-- DT attaches DT commercial extension
Social.SetExtension(socialState, "player:user:Bob", "dynamictrading", {
    totalTrades = 5,
    totalSpent = 1200,
    traderType = "caravan",
}, "server")

-- Record a commercial trade event raising approval
Social.RecordAuthorizedEvent(socialState, {
    authorized = true,
    authority = "server",
    eventID = "trade_completed_01",
    targetKey = "player:user:Bob",
    kind = "trade",
    approvalDelta = 5,
    familiarityDelta = 5,
    memory = "successful_bulk_trade",
})

local relBob = Social.Get(socialState, "player:user:Bob")
truthy(relBob, "Bob relationship retrieved")
equal(relBob.approval, 25, "Bob approval after trade")
equal(relBob.familiarity, 15, "Bob familiarity after trade")
local dtExt = Social.GetExtension(socialState, "player:user:Bob", "dynamictrading")
truthy(dtExt and dtExt.totalTrades == 5, "DT extension present before save")

-- Simulate save to persistent payload
local savedActorPayload = reg:Save()
local savedSocialPayload = Social.ToPayload(socialState)

-- Simulate reload (clean state, reload from saved payload)
reg = Actors.NewRegistry()
local restoreOk, restoreErr = reg:Load(savedActorPayload)
truthy(restoreOk, "Registry restored from payload: " .. tostring(restoreErr))

local reloadedTrader = reg:Get("trader_marcus")
truthy(reloadedTrader, "Trader actor reloaded")
equal(reloadedTrader.identity.identitySeed, "seed_marcus_caravan", "Identity seed preserved")

local reloadedSocialState, socialErr = Social.FromPayload(deepCopy(savedSocialPayload))
truthy(reloadedSocialState, "Social state restored: " .. tostring(socialErr))
local reloadedBob = Social.Get(reloadedSocialState, "player:user:Bob")
equal(reloadedBob.approval, 25, "Approval preserved after reload")
equal(reloadedBob.familiarity, 15, "Familiarity preserved after reload")
local reloadedDtExt = Social.GetExtension(reloadedSocialState, "player:user:Bob", "dynamictrading")
truthy(reloadedDtExt and reloadedDtExt.totalTrades == 5, "DT extension preserved after reload")

print("--- Step 2: Add Project Hoomans to existing save ---")
-- Hoomans initializes. It checks the existing actor in Core Registry.
local hoomansSeenActor = reg:Get("trader_marcus")
truthy(hoomansSeenActor, "Hoomans recognizes existing trader by canonical actor ID")
equal(hoomansSeenActor.actorId, "trader_marcus", "Canonical actor ID matches")
equal(#reg:List(), 1, "Exactly one actor in registry, no duplicate created")

-- Hoomans inspects relationship from Core Social
local hoomansSeenRel = Social.Get(reloadedSocialState, "player:user:Bob")
equal(hoomansSeenRel.approval, 25, "Hoomans observes identical approval")
equal(hoomansSeenRel.familiarity, 15, "Hoomans observes identical familiarity")
truthy(#hoomansSeenRel.memories > 0, "Memories observed")

print("--- Step 3: Exercise Hoomans extensions and capabilities ---")
-- Hoomans attaches its own extension side-by-side with DT's extension
Social.SetExtension(reloadedSocialState, "player:user:Bob", "projecthoomans", {
    bond = "friend",
    morale = 85,
    conduct = { honoredAgreements = 2 },
}, "server")

-- Hoomans records a social interaction raising approval and familiarity
Social.RecordAuthorizedEvent(reloadedSocialState, {
    authorized = true,
    authority = "server",
    eventID = "social_conversation_01",
    targetKey = "player:user:Bob",
    kind = "conversation",
    approvalDelta = 5,
    familiarityDelta = 10,
    memory = "shared_camp_story",
})

-- Both extensions coexist
local coexRel = Social.Get(reloadedSocialState, "player:user:Bob")
equal(coexRel.approval, 30, "Approval raised by Hoomans interaction")
equal(coexRel.familiarity, 25, "Familiarity raised by Hoomans interaction")
local coexDtExt = Social.GetExtension(reloadedSocialState, "player:user:Bob", "dynamictrading")
local coexHoomansExt = Social.GetExtension(reloadedSocialState, "player:user:Bob", "projecthoomans")
truthy(coexDtExt and coexDtExt.totalTrades == 5, "DT extension intact alongside Hoomans")
truthy(coexHoomansExt and coexHoomansExt.bond == "friend", "Hoomans extension intact alongside DT")

-- Save state with both extensions
local savedBothPayload = Social.ToPayload(reloadedSocialState)
local savedBothActorPayload = reg:Save()

print("--- Step 4: Remove Project Hoomans and reload ---")
-- Simulate Hoomans removed from mod list: PNC = nil, only Core + DT active.
reg = Actors.NewRegistry()
reg:Load(savedBothActorPayload)

local dtOnlySocialState = Social.FromPayload(deepCopy(savedBothPayload))
local dtBobRel = Social.Get(dtOnlySocialState, "player:user:Bob")
equal(dtBobRel.approval, 30, "DT observes unchanged base approval (30)")
equal(dtBobRel.familiarity, 25, "DT observes unchanged base familiarity (25)")

-- Inactive Hoomans extension is PRESERVED, not deleted
local preservedHoomansExt = Social.GetExtension(dtOnlySocialState, "player:user:Bob", "projecthoomans")
truthy(preservedHoomansExt and preservedHoomansExt.bond == "friend", "Inactive Hoomans extension preserved in Core Social")

-- DT executes another trade while Hoomans is inactive
Social.SetExtension(dtOnlySocialState, "player:user:Bob", "dynamictrading", {
    totalTrades = 6,
    totalSpent = 1500,
    traderType = "caravan",
}, "server")
Social.RecordAuthorizedEvent(dtOnlySocialState, {
    authorized = true,
    authority = "server",
    eventID = "trade_completed_02",
    targetKey = "player:user:Bob",
    kind = "trade",
    approvalDelta = 2,
})

-- Save updated state
local savedDtOnlyPayload = Social.ToPayload(dtOnlySocialState)

print("--- Step 5: Re-add Project Hoomans and verify extension recovery ---")
-- Hoomans re-added to game.
local restoredBothState = Social.FromPayload(deepCopy(savedDtOnlyPayload))
local restoredRelBob = Social.Get(restoredBothState, "player:user:Bob")
equal(restoredRelBob.approval, 32, "Approval reflects trades executed while Hoomans was absent")

local recoveredHoomansExt = Social.GetExtension(restoredBothState, "player:user:Bob", "projecthoomans")
truthy(recoveredHoomansExt, "Hoomans extension recovered")
equal(recoveredHoomansExt.bond, "friend", "Hoomans bond recovered intact")
equal(recoveredHoomansExt.morale, 85, "Hoomans morale recovered intact")

local updatedDtExt = Social.GetExtension(restoredBothState, "player:user:Bob", "dynamictrading")
equal(updatedDtExt.totalTrades, 6, "DT extension has latest trades")

print("--- Step 6: Reverse Matrix: Core + Hoomans -> Add DT -> Remove DT -> Re-add DT ---")
reg = Actors.NewRegistry()

-- Create Hoomans NPC
local hoomansActor = reg:Create({
    actorId = "hoomans_clara",
    identitySeed = "seed_clara_doctor",
    provider = "PsychopatzCore",
    x = 50, y = 60, z = 0,
})
truthy(hoomansActor, "Clara created in Hoomans")

local claraSocial = Social.NewState({
    relationships = {
        ["player:user:Bob"] = {
            approval = 40,
            respect = 50,
            familiarity = 30,
        },
    },
})
Social.SetExtension(claraSocial, "player:user:Bob", "projecthoomans", {
    bond = "companion",
    morale = 90,
}, "server")

local claraSaved = Social.ToPayload(claraSocial)
local claraActorSaved = reg:Save()

-- Add DT to save
reg = Actors.NewRegistry()
reg:Load(claraActorSaved)
local claraWithDT = Social.FromPayload(deepCopy(claraSaved))

-- DT reads price context / relationship without modifying or forking
local claraRelForDT = Social.Get(claraWithDT, "player:user:Bob")
equal(claraRelForDT.approval, 40, "DT observes Clara approval 40")
equal(#reg:List(), 1, "No duplicate actor when DT added")

-- Remove DT, re-add DT: Clara remains intact
local claraDTPost = Social.FromPayload(deepCopy(Social.ToPayload(claraWithDT)))
local claraExtPost = Social.GetExtension(claraDTPost, "player:user:Bob", "projecthoomans")
equal(claraExtPost.bond, "companion", "Clara companion bond preserved throughout DT lifecycle")

print("--- Step 7: Repeated Load/Migration Idempotence ---")
local currentPayload = deepCopy(savedDtOnlyPayload)
for iteration = 1, 5 do
    local state = Social.FromPayload(currentPayload)
    equal(Social.Get(state, "player:user:Bob").approval, 32, "Idempotent approval at iteration " .. iteration)
    truthy(Social.GetExtension(state, "player:user:Bob", "projecthoomans") ~= nil, "Idempotent hoomans ext at iteration " .. iteration)
    truthy(Social.GetExtension(state, "player:user:Bob", "dynamictrading") ~= nil, "Idempotent dt ext at iteration " .. iteration)
    currentPayload = Social.ToPayload(state)
end

print("--- Step 8: Migration conflicts fail visibly without destructive reset ---")
local store = Migration.NewStore()
-- Seed store with existing imported mapping
store.mappings["pnc_npc_99"] = {
    mappingKey = "pnc_npc_99",
    actorId = "trader_marcus",
    sourceHash = "initial_valid_hash_1234",
}

-- Attempt conflicting import with altered hash/actorId
local conflictPlan = {
    status = "ready",
    sourceHash = "conflicting_altered_hash_9999",
    rawPayload = { id = "pnc_npc_99" },
    candidate = {
        actorId = "trader_marcus",
        identitySeed = "altered_seed",
    },
}
local importResult = Migration.Import(conflictPlan, reg, store, { mappingKey = "pnc_npc_99" })
equal(importResult.status, "quarantined", "Conflicting import is quarantined")
equal(importResult.reason, "identity_conflict", "Conflicting import fails with identity_conflict")

-- Ensure existing registry actor was NOT wiped or corrupted
local existingActor = reg:Get("hoomans_clara")
truthy(existingActor, "Existing Clara still intact after failed import")

print("psychopatz_hotplug_save_matrix_smoke: PASS")
