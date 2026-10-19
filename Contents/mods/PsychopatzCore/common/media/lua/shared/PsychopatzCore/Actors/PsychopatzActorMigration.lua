local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"

local Migration = {}
local Store = {}
Store.__index = Store

Migration.SCHEMA_VERSION = 1

function Migration.NewStore()
    return setmetatable({
        schemaVersion = Migration.SCHEMA_VERSION,
        mappings = {},
        backups = {},
        disabled = {},
    }, Store)
end

function Store:Export()
    return Util.clone(self)
end

function Store:Import(payload)
    if type(payload) ~= "table"
        or tonumber(payload.schemaVersion) ~= Migration.SCHEMA_VERSION
        or type(payload.mappings) ~= "table"
    then return false, "migration_store_schema_mismatch" end
    self.mappings = Util.clone(payload.mappings)
    self.backups = Util.clone(payload.backups or {})
    self.disabled = Util.clone(payload.disabled or {})
    return true
end

local function sourceHash(raw)
    return Json.Fingerprint(Json.Encode(raw or {}))
end

local function result(status, reason, plan, raw, mappingKey, actorId, hash)
    return {
        status = status,
        reason = reason,
        actorId = actorId,
        mappingKey = mappingKey,
        sourceHash = hash,
        rawPayload = Util.clone(raw),
        sourcePreserved = true,
        writesPerformed = status == "imported" or status == "already_imported",
        rollback = {
            schemaVersion = 1,
            strategy = status == "imported"
                and "DISABLE_CANDIDATE_MAPPING"
                or "NO_WRITE_QUARANTINE",
            sourceHash = hash,
            sourcePreserved = true,
            writesPerformed = status == "imported",
        },
        planStatus = plan and plan.status or nil,
    }
end

local function fail(reason, plan, raw, mappingKey, actorId, hash)
    return result("quarantined", reason, plan, raw, mappingKey, actorId, hash)
end

local function voiceProfile(survivor)
    local voice = survivor and survivor.voice
    if type(voice) == "table" then
        return {
            schemaVersion = 1,
            voice = voice.voice or voice.legacy,
            voicePrefix = voice.voicePrefix or voice.prefix,
            voiceType = voice.voiceType or voice.type,
            voicePitch = voice.voicePitch or voice.pitch,
            complete = voice.complete == true,
        }
    end
    local profile = survivor and survivor.voiceProfile
    if type(profile) == "table" then return Util.clone(profile) end
    return nil
end

local function identitySpec(identity)
    if type(identity) ~= "table" or type(identity.survivor) ~= "table" then
        return nil, "identity_contract_invalid"
    end
    local survivor = Util.clone(identity.survivor)
    local profile = voiceProfile(identity.survivor)
    if not profile or profile.voice == nil or profile.voicePrefix == nil
        or profile.voiceType == nil or profile.voicePitch == nil
    then return nil, "voice_profile_incomplete" end
    survivor.voiceProfile = profile
    survivor.voice = profile.voice
    survivor.voicePrefix = profile.voicePrefix
    survivor.voiceType = profile.voiceType
    survivor.voicePitch = profile.voicePitch
    if survivor.gender == nil and identity.isFemale ~= nil then
        survivor.gender = identity.isFemale and "female" or "male"
    end
    return {
        identitySeed = identity.seed,
        identity = {
            displayName = identity.displayName,
            archetypeID = identity.archetypeID,
            survivor = survivor,
        },
    }
end

local function itemList(inventory)
    if type(inventory) ~= "table" or type(inventory.items) ~= "table" then
        return nil, "inventory_source_shape_unverified"
    end
    if tonumber(inventory.metadataSchema) ~= 2 then
        return nil, "portable_metadata_invalid"
    end
    local keys = {}
    for key in pairs(inventory.items) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)
    local output = {}
    for index = 1, #keys do
        local key = keys[index]
        local item = inventory.items[key]
        if type(item) ~= "table" or type(item.id) ~= "string"
            or item.id == "" or tostring(item.id) ~= tostring(key)
        then return nil, "item_identity_invalid" end
        local fullType = item.type or item.fullType
        if type(fullType) ~= "string" or fullType == "" then
            return nil, "item_type_missing"
        end
        if item.legacyTemplateKey ~= nil
            and (type(item.legacyTemplateKey) ~= "string"
                or item.legacyTemplateKey == "")
        then return nil, "portable_metadata_invalid" end
        output[#output + 1] = {
            itemId = item.id,
            fullType = fullType,
            quantity = item.stack or item.quantity or 1,
            metadata = {
                source = "ProjectHoomans",
                legacyTemplateKey = item.legacyTemplateKey,
                legacyItem = Util.clone(item),
            },
        }
    end
    if #output == 0 then return nil, "inventory_empty" end
    return output
end

local function applyEquipment(ledger, inventory)
    local categories = {
        { name = "worn", values = inventory.worn },
        { name = "equipped", values = inventory.equipped },
        { name = "attached", values = inventory.attached },
    }
    for index = 1, #categories do
        local category = categories[index]
        for slot, itemId in pairs(category.values or {}) do
            if ledger:Get(itemId) then
                local ok, reason = ledger:SetEquipment(itemId, slot, category.name)
                if not ok then return false, reason end
            end
        end
    end
    return true
end

local function buildActor(plan, raw, hash, options)
    local candidate = plan.candidate
    if type(candidate) ~= "table" then return nil, "candidate_missing" end
    local identity, identityReason = identitySpec(candidate.identity)
    if not identity then return nil, identityReason end
    local inventoryItems, inventoryReason = itemList(candidate.inventory)
    if not inventoryItems then return nil, inventoryReason end

    local appearance = candidate.appearance or {}
    local policy = type(appearance.policy) == "table"
        and Util.clone(appearance.policy) or nil
    local generated = policy and (policy.mode == "GENERATED_DEFAULT"
        or policy.mode == "generated" or policy.authored == false)
    local spec = {
        actorId = candidate.actorId,
        ownerMod = "ProjectHoomans",
        identitySeed = identity.identitySeed,
        identity = identity.identity,
        archetypeID = identity.identity.archetypeID,
        appearance = generated and nil or {
            policy = policy,
            resolved = appearance.resolved,
        },
        source = {
            provider = "ProjectHoomans",
            sourceRecordHash = hash,
            importedFromVersion = candidate.source
                and candidate.source.persistenceVersion,
            decisionSet = options.decisionSet,
            opaque = candidate.source and Util.clone(candidate.source.opaque),
        },
        social = Util.clone(candidate.relationships),
        world = Util.clone(candidate.location),
        extensions = {
            ["ProjectHoomans:opaque"] = candidate.source
                and Util.clone(candidate.source.opaque) or {},
        },
        starterItems = inventoryItems,
    }
    local actor, reason = Factory.Generate(spec)
    if not actor then return nil, reason end
    actor.appearance.policy = policy or actor.appearance.policy
    actor.appearance.resolved = Util.clone(appearance.resolved)
        or actor.appearance.resolved
    actor.appearance.contract.mode = generated
        and "GENERATED_DEFAULT" or "AUTHORED_POLICY"
    actor.appearance.contract.policyHash = Json.Fingerprint(
        Json.Encode(actor.appearance.policy))
    actor.source = spec.source
    actor.social = spec.social
    actor.world = spec.world

    local ledger, ledgerReason = ActorInventory.new({
        actorId = actor.actorId,
        seed = identity.identitySeed,
        starterVersion = candidate.inventory and candidate.inventory.revision,
        starterItems = inventoryItems,
    })
    if not ledger then return nil, ledgerReason end
    local equipmentOK, equipmentReason = applyEquipment(ledger, candidate.inventory)
    if not equipmentOK then return nil, equipmentReason end
    actor.personalInventory = ledger:ToPayload("FULL")
    return actor
end

function Migration.Import(plan, registry, store, options)
    options = type(options) == "table" and options or {}
    store = store or Migration.NewStore()
    if type(plan) ~= "table" or plan.status ~= "ready" then
        return fail(plan and plan.reason or "plan_not_ready", plan,
            options.rawPayload, nil, nil, nil)
    end
    local raw = options.rawPayload or plan.rawPayload
    if type(raw) ~= "table" then
        return fail("source_payload_missing", plan, raw, nil, nil, nil)
    end
    local candidate = plan.candidate
    local mappingKey = options.mappingKey or raw.id
    local actorId = candidate and candidate.actorId
    local hash = plan.sourceHash or sourceHash(raw)
    if type(mappingKey) ~= "string" or mappingKey == ""
        or type(actorId) ~= "string" or actorId == ""
    then return fail("identity_conflict", plan, raw, mappingKey, actorId, hash) end

    local existing = store.mappings[mappingKey]
    if existing then
        if existing.actorId == actorId and existing.sourceHash == hash then
            return result("already_imported", nil, plan, raw, mappingKey,
                actorId, hash)
        end
        return fail("identity_conflict", plan, raw, mappingKey, actorId, hash)
    end
    if not registry or type(registry.Register) ~= "function" then
        return fail("core_registry_unavailable", plan, raw, mappingKey, actorId, hash)
    end
    if registry:Has(actorId) then
        local existingActor = registry:Get(actorId)
        if existingActor and existingActor.source
            and existingActor.source.sourceRecordHash == hash
        then
            store.mappings[mappingKey] = { actorId = actorId, sourceHash = hash,
                state = "active" }
            return result("already_imported", nil, plan, raw, mappingKey,
                actorId, hash)
        end
        return fail("identity_conflict", plan, raw, mappingKey, actorId, hash)
    end

    local actor, reason = buildActor(plan, raw, hash, options)
    if not actor then return fail(reason, plan, raw, mappingKey, actorId, hash) end
    local valid, validationReason = Factory.ValidateActor(actor)
    if not valid then
        return fail(validationReason, plan, raw, mappingKey, actorId, hash)
    end
    store.backups[mappingKey] = {
        sourceHash = hash,
        rawPayload = Util.clone(raw),
        candidateHash = plan.candidateHash,
    }
    local registered, registerReason = registry:Register(actor)
    if not registered then
        store.backups[mappingKey] = nil
        return fail(registerReason, plan, raw, mappingKey, actorId, hash)
    end
    store.mappings[mappingKey] = {
        actorId = actorId,
        sourceHash = hash,
        state = "active",
    }
    return result("imported", nil, plan, raw, mappingKey, actorId, hash)
end

function Migration.Rollback(importResult, registry, store)
    if type(importResult) ~= "table" or importResult.status ~= "imported" then
        return false, "import_result_required"
    end
    store = store or Migration.NewStore()
    local mapping = store.mappings[importResult.mappingKey]
    if not mapping or mapping.actorId ~= importResult.actorId then
        return false, "mapping_not_found"
    end
    if not registry or type(registry.Remove) ~= "function" then
        return false, "core_registry_unavailable"
    end
    local removed, reason = registry:Remove(mapping.actorId)
    if not removed then return false, reason end
    mapping.state = "disabled"
    store.disabled[importResult.mappingKey] = mapping
    store.mappings[importResult.mappingKey] = nil
    return true
end

Migration.Store = Store
return Migration
