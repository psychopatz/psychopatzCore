-- Server-authoritative, provider-driven mark-and-sweep garbage collection for
-- retired actor tombstones and bounded social weak-reference compaction.
-- Uses no persistent reference counts and never runs full GC per Tick.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Lifecycle = require "PsychopatzCore/Actors/PsychopatzActorLifecycle"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local GC = {}

GC.MAX_PROVIDERS = 64
GC.MAX_REFS_PER_PROVIDER = 4096
GC.DEFAULT_MAX_REFS_PER_PROVIDER = 2048
GC.DEFAULT_SLICE_BUDGET = 64
GC.TOMBSTONE_THRESHOLD = 64
GC.MAX_PURGE_EXPLANATIONS = 64
GC.MAX_RUN_FULL_STEPS = 1024

GC.Providers = GC.Providers or {}

local function safeID(value, limit)
    local text = Util.text(value, nil)
    if not text or #text > (limit or 96) or string.find(text, "[%c]") then
        return nil
    end
    return text
end

local function finiteNumber(value, fallback)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return fallback
    end
    return num
end

local function countMapKeys(map)
    local count = 0
    for _ in pairs(type(map) == "table" and map or {}) do
        count = count + 1
    end
    return count
end

local function sortedKeys(map)
    local keys = {}
    for key in pairs(type(map) == "table" and map or {}) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys
end

local function stripSocialPrefix(value)
    if type(value) ~= "string" then return nil end
    if string.sub(value, 1, 4) == "npc:" then
        return string.sub(value, 5)
    end
    if string.sub(value, 1, 6) == "actor:" then
        return string.sub(value, 7)
    end
    return nil
end

local function buildMatchSet(ref, ts)
    local set = {}
    local function add(value)
        if type(value) == "string" and value ~= "" then
            set[value] = true
        end
    end
    add(ref)
    add("actor:" .. tostring(ref))
    add("npc:" .. tostring(ref))
    local bare = stripSocialPrefix(ref)
    if bare then
        add(bare)
        add("actor:" .. bare)
        add("npc:" .. bare)
    end
    if type(ts) == "table" and type(ts.aliases) == "table" then
        for index = 1, #ts.aliases do
            local alias = ts.aliases[index]
            add(alias)
            add("actor:" .. tostring(alias))
            add("npc:" .. tostring(alias))
            local aliasBare = stripSocialPrefix(alias)
            if aliasBare then add(aliasBare) end
        end
    end
    return set
end

local function validateProviderSpec(providerID, provider)
    local id = safeID(providerID, 96)
    if not id then return nil, "provider_id_invalid" end
    if type(provider) ~= "table" then return nil, "provider_table_required" end
    local owner = safeID(provider.owner, 64)
    if not owner then return nil, "provider_owner_required" end
    if type(provider.CollectStrongRefs) ~= "function" then
        return nil, "provider_collect_strong_required"
    end
    for _, optionalKey in ipairs({
        "CollectWeakRefs", "OnBeforePurge", "IsOwnedActive",
    }) do
        if provider[optionalKey] ~= nil
            and type(provider[optionalKey]) ~= "function"
        then
            return nil, "provider_callback_invalid"
        end
    end
    local maxRefs = GC.DEFAULT_MAX_REFS_PER_PROVIDER
    if provider.maxRefs ~= nil then
        local parsed = Util.integer(provider.maxRefs, nil)
        if parsed == nil or parsed ~= tonumber(provider.maxRefs)
            or parsed < 1 or parsed > GC.MAX_REFS_PER_PROVIDER
        then
            return nil, "provider_max_refs_invalid"
        end
        maxRefs = parsed
    end
    return {
        id = id,
        owner = owner,
        maxRefs = maxRefs,
        CollectStrongRefs = provider.CollectStrongRefs,
        CollectWeakRefs = provider.CollectWeakRefs,
        OnBeforePurge = provider.OnBeforePurge,
        IsOwnedActive = provider.IsOwnedActive,
    }
end

function GC.RegisterReferenceProvider(providerID, provider)
    local normalized, err = validateProviderSpec(providerID, provider)
    if not normalized then return false, err end
    if not GC.Providers[normalized.id]
        and countMapKeys(GC.Providers) >= GC.MAX_PROVIDERS
    then
        return false, "provider_limit_exceeded"
    end
    GC.Providers[normalized.id] = normalized
    return true
end

function GC.UnregisterReferenceProvider(providerID)
    local id = safeID(providerID, 96)
    if not id or not GC.Providers[id] then
        return false, "provider_not_found"
    end
    GC.Providers[id] = nil
    return true
end

function GC.ListReferenceProviders()
    local ids = sortedKeys(GC.Providers)
    local out = {}
    for index = 1, #ids do
        local p = GC.Providers[ids[index]]
        out[index] = {
            id = p.id,
            owner = p.owner,
            maxRefs = p.maxRefs,
            hasWeakCollector = type(p.CollectWeakRefs) == "function",
            hasPurgeHook = type(p.OnBeforePurge) == "function",
            hasActiveOwnerCheck = type(p.IsOwnedActive) == "function",
        }
    end
    return out
end

local function isStrongRelationship(rel)
    if type(rel) ~= "table" then return false end
    if rel.historicalPin == true then return true, "historical_pin" end
    local ext = rel.extensions
    if type(ext) == "table" and type(ext.ProjectHoomans) == "table"
        and type(ext.ProjectHoomans.bond) == "table"
    then
        local cls = ext.ProjectHoomans.bond.class
        if type(cls) == "string" and cls ~= "" and cls ~= "none" then
            return true, "durable_bond"
        end
    end
    for _, mem in ipairs(rel.memories or {}) do
        if type(mem) == "table" then
            if mem.refStrength == "STRONG" then
                return true, "strong_memory"
            end
            if mem.retentionClass == "ANCHOR" or mem.permanent == true then
                return true, "anchor_memory"
            end
        end
    end
    local approval = math.abs(tonumber(rel.approval) or 0)
    local respect = math.abs(tonumber(rel.respect) or 0)
    if approval >= 35 or respect >= 35 then
        return true, "significant_relationship"
    end
    return false
end

local function builtinSocialStrong(ctx, emit)
    local registry = ctx and ctx.registry
    if not registry or type(registry.records) ~= "table" then return true end
    local actorIDs = sortedKeys(registry.records)
    for _, actorID in ipairs(actorIDs) do
        local actor = registry.records[actorID]
        local social = actor and actor.social
        if type(social) == "table" and type(social.relationships) == "table" then
            local targetKeys = sortedKeys(social.relationships)
            for _, targetKey in ipairs(targetKeys) do
                local rel = social.relationships[targetKey]
                local strong, reason = isStrongRelationship(rel)
                if strong then
                    emit(targetKey, reason, { ownerActor = actorID })
                end
                for _, mem in ipairs((rel and rel.memories) or {}) do
                    if type(mem) == "table"
                        and mem.sourceRefStrength == "STRONG"
                        and type(mem.sourceKey) == "string"
                        and mem.sourceKey ~= ""
                    then
                        emit(mem.sourceKey, "strong_memory_source", {
                            ownerActor = actorID,
                            targetKey = targetKey,
                        })
                    end
                end
            end
        end
    end
    return true
end

local function builtinSocialWeak(ctx, emit)
    local registry = ctx and ctx.registry
    if not registry or type(registry.records) ~= "table" then return true end
    local actorIDs = sortedKeys(registry.records)
    for _, actorID in ipairs(actorIDs) do
        local actor = registry.records[actorID]
        local social = actor and actor.social
        if type(social) == "table" and type(social.relationships) == "table" then
            local targetKeys = sortedKeys(social.relationships)
            for _, targetKey in ipairs(targetKeys) do
                local rel = social.relationships[targetKey]
                if not isStrongRelationship(rel) then
                    emit(targetKey, "weak_relationship", {
                        ownerActor = actorID,
                    })
                end
                for _, mem in ipairs((rel and rel.memories) or {}) do
                    if type(mem) == "table"
                        and mem.sourceRefStrength ~= "STRONG"
                        and type(mem.sourceKey) == "string"
                        and mem.sourceKey ~= ""
                    then
                        emit(mem.sourceKey, "weak_memory_source", {
                            ownerActor = actorID,
                            targetKey = targetKey,
                        })
                    end
                end
            end
        end
    end
    return true
end

local function builtinSocialOnBeforePurge(ref, ctx)
    local registry = ctx and ctx.registry
    if not registry or type(registry.records) ~= "table" then
        return true, 0
    end
    local matchSet = buildMatchSet(ref, ctx.tombstone)
    local compacted = 0
    local actorIDs = sortedKeys(registry.records)
    for _, actorID in ipairs(actorIDs) do
        local actor = registry.records[actorID]
        local social = actor and actor.social
        if type(social) == "table" then
            local changed = false
            if type(social.relationships) == "table" then
                local keys = sortedKeys(social.relationships)
                for _, targetKey in ipairs(keys) do
                    local rel = social.relationships[targetKey]
                    if matchSet[targetKey] and not isStrongRelationship(rel) then
                        social.relationships[targetKey] = nil
                        compacted = compacted + 1
                        changed = true
                    elseif type(rel) == "table"
                        and type(rel.memories) == "table"
                    then
                        for _, mem in ipairs(rel.memories) do
                            if type(mem) == "table"
                                and type(mem.sourceKey) == "string"
                                and matchSet[mem.sourceKey]
                                and mem.sourceRefStrength ~= "STRONG"
                            then
                                mem.sourceKey = nil
                                mem.sourceDegraded = true
                                compacted = compacted + 1
                                changed = true
                            end
                        end
                    end
                end
            end
            if type(social.aliases) == "table" then
                local aliasKeys = sortedKeys(social.aliases)
                for _, aliasKey in ipairs(aliasKeys) do
                    local canonicalTarget = social.aliases[aliasKey]
                    if matchSet[aliasKey] or matchSet[canonicalTarget] then
                        social.aliases[aliasKey] = nil
                        compacted = compacted + 1
                        changed = true
                    end
                end
            end
            if changed then
                social.revision = (tonumber(social.revision) or 0) + 1
                actor.revision = (tonumber(actor.revision) or 0) + 1
            end
        end
    end
    return true, compacted
end

local function resolveSurvivorWorld(ctx)
    if type(ctx) == "table" and ctx.survivorWorld ~= nil then
        return ctx.survivorWorld
    end
    local sw = PsychopatzCore and PsychopatzCore.SurvivorWorld or nil
    return sw and sw.DefaultRegistry or nil
end

local function collectSWEntries(sw)
    local sets = {}
    if not sw then return sets end
    if type(sw.snapshot) == "table" then
        sets[#sets + 1] = {
            kind = "faction",
            map = sw.snapshot.factions,
            activeOnly = true,
        }
        sets[#sets + 1] = {
            kind = "community",
            map = sw.snapshot.communities,
            activeOnly = true,
        }
        sets[#sets + 1] = {
            kind = "group",
            map = sw.snapshot.groups,
            activeOnly = false,
        }
        return sets
    end
    if type(sw.ListFactions) == "function" then
        sets[#sets + 1] = {
            kind = "faction",
            list = sw:ListFactions(),
            activeOnly = true,
        }
    end
    if type(sw.ListCommunities) == "function" then
        sets[#sets + 1] = {
            kind = "community",
            list = sw:ListCommunities(),
            activeOnly = true,
        }
    end
    if type(sw.ListGroups) == "function" then
        sets[#sets + 1] = {
            kind = "group",
            list = sw:ListGroups(),
            activeOnly = false,
        }
    end
    return sets
end

local function eachSWEntry(set, fn)
    if type(set.map) == "table" then
        for _, key in ipairs(sortedKeys(set.map)) do
            fn(set.map[key])
        end
        return
    end
    for _, entry in ipairs(set.list or {}) do
        fn(entry)
    end
end

local function builtinSWStrong(ctx, emit)
    local sw = resolveSurvivorWorld(ctx)
    for _, set in ipairs(collectSWEntries(sw)) do
        eachSWEntry(set, function(entry)
            if type(entry) == "table" then
                local status = entry.status or "active"
                local active = (set.activeOnly and status == "active")
                    or (not set.activeOnly and status ~= "destroyed")
                if active and type(entry.leaderActorID) == "string"
                    and entry.leaderActorID ~= ""
                then
                    emit(entry.leaderActorID, set.kind .. "_leader", {
                        id = entry.id,
                    })
                end
            end
        end)
    end
    return true
end

local function builtinSWWeak(ctx, emit)
    local sw = resolveSurvivorWorld(ctx)
    for _, set in ipairs(collectSWEntries(sw)) do
        eachSWEntry(set, function(entry)
            if type(entry) == "table"
                and type(entry.memberActorIDs) == "table"
            then
                for _, memberID in ipairs(entry.memberActorIDs) do
                    if type(memberID) == "string" and memberID ~= "" then
                        emit(memberID, set.kind .. "_member", { id = entry.id })
                    end
                end
            end
        end)
    end
    return true
end

local function builtinSWOnBeforePurge(ref, ctx)
    local sw = resolveSurvivorWorld(ctx)
    if not sw or type(sw.snapshot) ~= "table" then return true, 0 end
    local matchSet = buildMatchSet(ref, ctx.tombstone)
    local removed = 0
    for _, set in ipairs(collectSWEntries(sw)) do
        eachSWEntry(set, function(entry)
            if type(entry) == "table"
                and type(entry.memberActorIDs) == "table"
            then
                local kept = {}
                local dirty = false
                for _, memberID in ipairs(entry.memberActorIDs) do
                    if matchSet[memberID] then
                        removed = removed + 1
                        dirty = true
                    else
                        kept[#kept + 1] = memberID
                    end
                end
                if dirty then
                    entry.memberActorIDs = kept
                    entry.revision = (tonumber(entry.revision) or 0) + 1
                end
            end
        end)
    end
    if removed > 0 then
        sw.snapshot.revision = (tonumber(sw.snapshot.revision) or 0) + 1
    end
    return true, removed
end

local function resolveWorldKnowledge(ctx)
    if type(ctx) == "table" and ctx.worldKnowledge ~= nil then
        return ctx.worldKnowledge
    end
    return PsychopatzCore and PsychopatzCore.WorldKnowledgeState or nil
end

local function builtinWKStrong()
    return true
end

local function builtinWKWeak(ctx, emit)
    local wk = resolveWorldKnowledge(ctx)
    if type(wk) ~= "table" or type(wk.byActor) ~= "table" then return true end
    for _, actorID in ipairs(sortedKeys(wk.byActor)) do
        emit(actorID, "world_knowledge_actor_bucket")
        local entry = wk.byActor[actorID]
        if type(entry) == "table" and type(entry.refs) == "table" then
            for _, factID in ipairs(sortedKeys(entry.refs)) do
                local factRef = entry.refs[factID]
                if type(factRef) == "table"
                    and type(factRef.sourceActorID) == "string"
                    and factRef.sourceActorID ~= ""
                then
                    emit(factRef.sourceActorID, "world_knowledge_source", {
                        ownerActor = actorID,
                        factID = factID,
                    })
                end
            end
        end
    end
    return true
end

local function builtinWKOnBeforePurge(ref, ctx)
    local wk = resolveWorldKnowledge(ctx)
    if type(wk) ~= "table" or type(wk.byActor) ~= "table" then
        return true, 0
    end
    local matchSet = buildMatchSet(ref, ctx.tombstone)
    local compacted = 0
    for _, actorID in ipairs(sortedKeys(wk.byActor)) do
        if matchSet[actorID] then
            wk.byActor[actorID] = nil
            compacted = compacted + 1
        else
            local entry = wk.byActor[actorID]
            if type(entry) == "table" and type(entry.refs) == "table" then
                for _, factID in ipairs(sortedKeys(entry.refs)) do
                    local factRef = entry.refs[factID]
                    if type(factRef) == "table"
                        and type(factRef.sourceActorID) == "string"
                        and matchSet[factRef.sourceActorID]
                    then
                        factRef.sourceActorID = nil
                        factRef.sourceDegraded = true
                        compacted = compacted + 1
                    end
                end
            end
        end
    end
    return true, compacted
end

function GC.RegisterBuiltinProviders()
    GC.RegisterReferenceProvider("PsychopatzCore.Social", {
        owner = "PsychopatzCore",
        maxRefs = GC.MAX_REFS_PER_PROVIDER,
        CollectStrongRefs = builtinSocialStrong,
        CollectWeakRefs = builtinSocialWeak,
        OnBeforePurge = builtinSocialOnBeforePurge,
    })
    GC.RegisterReferenceProvider("PsychopatzCore.SurvivorWorld", {
        owner = "PsychopatzCore",
        maxRefs = GC.MAX_REFS_PER_PROVIDER,
        CollectStrongRefs = builtinSWStrong,
        CollectWeakRefs = builtinSWWeak,
        OnBeforePurge = builtinSWOnBeforePurge,
    })
    GC.RegisterReferenceProvider("PsychopatzCore.WorldKnowledge", {
        owner = "PsychopatzCore",
        maxRefs = GC.MAX_REFS_PER_PROVIDER,
        CollectStrongRefs = builtinWKStrong,
        CollectWeakRefs = builtinWKWeak,
        OnBeforePurge = builtinWKOnBeforePurge,
    })
    return true
end

local function snapshotProviders(explicitProviders)
    local source = type(explicitProviders) == "table"
        and explicitProviders or GC.Providers
    local validated = {}
    local ids = {}
    for key, provider in pairs(source) do
        local pid = type(provider) == "table" and (provider.id or key) or key
        local norm, err = validateProviderSpec(pid, provider)
        if not norm then
            return nil, err, tostring(pid)
        end
        validated[norm.id] = norm
        ids[#ids + 1] = norm.id
    end
    table.sort(ids)
    local ordered = {}
    for index = 1, #ids do
        ordered[index] = validated[ids[index]]
    end
    return ordered
end

local function ensureState(registry)
    registry._gcState = registry._gcState or {
        generation = math.max(0,
            Util.integer(registry.gcMeta and registry.gcMeta.generation, 0)),
        phase = "idle",
        providers = {},
        providerCursor = 1,
        markedStrong = {},
        markedWeak = {},
        failedProviders = {},
        tombstoneSnapshot = {},
        sweepCursor = 1,
        purgedRefs = {},
        retainedCount = 0,
        skippedGraceCount = 0,
        activeOwnershipBlocked = 0,
        purgeFailedRefs = {},
        purgeExplanations = {},
        purgeHistoryByRef = {},
        contextSnapshot = {},
    }
    return registry._gcState
end

local function recordPurgeExplanation(state, entry)
    local list = state.purgeExplanations
    local byRef = state.purgeHistoryByRef
    list[#list + 1] = entry
    byRef[entry.ref] = entry
    while #list > GC.MAX_PURGE_EXPLANATIONS do
        local dropped = table.remove(list, 1)
        if dropped and byRef[dropped.ref] == dropped then
            byRef[dropped.ref] = nil
        end
    end
end

local function collectFromProvider(registry, provider, context, strongOut, weakOut)
    local emittedCount = 0
    local collectorFailed = nil

    local function makeEmitter(kind, targetMap)
        return function(rawRef, reason, detail)
            if collectorFailed then return end
            emittedCount = emittedCount + 1
            if emittedCount > provider.maxRefs then
                collectorFailed = "provider_ref_limit_exceeded"
                return
            end
            if type(rawRef) ~= "string" or rawRef == ""
                or #rawRef > Lifecycle.MAX_REF_LENGTH
                or string.find(rawRef, "[%c]")
            then
                collectorFailed = "provider_malformed_ref"
                return
            end
            local resolved, resolveErr = Lifecycle.ResolveRef(registry, rawRef)
            if not resolved then
                collectorFailed = resolveErr or "provider_ref_resolve_failed"
                return
            end
            local key = resolved.canonicalRef
            targetMap[key] = targetMap[key] or {}
            local list = targetMap[key]
            list[#list + 1] = {
                providerID = provider.id,
                owner = provider.owner,
                strength = kind,
                reason = safeID(reason, 64) or (kind == "STRONG" and "strong_root" or "weak_root"),
                rawRef = rawRef,
                detail = detail ~= nil and Util.clone(detail) or nil,
            }
        end
    end

    -- External/adopter GC provider boundary: fail closed on exception or false.
    local okStrong, resStrong, errStrong = pcall(
        provider.CollectStrongRefs,
        context,
        makeEmitter("STRONG", strongOut)
    )
    if not okStrong then
        return false, "provider_exception:" .. tostring(resStrong)
    end
    if resStrong == false then
        return false, tostring(errStrong or "provider_failed")
    end
    if collectorFailed then
        return false, collectorFailed
    end

    if type(provider.CollectWeakRefs) == "function" then
        -- External/adopter GC provider weak-ref boundary: fail closed on error.
        local okWeak, resWeak, errWeak = pcall(
            provider.CollectWeakRefs,
            context,
            makeEmitter("WEAK", weakOut)
        )
        if not okWeak then
            return false, "provider_weak_exception:" .. tostring(resWeak)
        end
        if resWeak == false then
            return false, tostring(errWeak or "provider_weak_failed")
        end
        if collectorFailed then
            return false, collectorFailed
        end
    end

    return true, emittedCount
end

local function checkActiveOwnership(registry, ref, providers, context)
    local reasons = {}
    if registry.records and registry.records[ref] ~= nil then
        reasons[#reasons + 1] = "live_actor_record"
    end
    for _, provider in ipairs(providers) do
        if type(provider.IsOwnedActive) == "function" then
            -- External/adopter GC active-ownership boundary: fail closed.
            local ok, owned, reason = pcall(provider.IsOwnedActive, ref, context)
            if not ok then
                reasons[#reasons + 1] = provider.id .. ":ownership_check_error"
            elseif owned == true then
                reasons[#reasons + 1] = provider.id .. ":" .. tostring(reason or "active_owner")
            end
        end
    end
    return reasons
end

function GC.Step(registry, options)
    local allowed, authErr = Lifecycle.RequireServerAuthority(options)
    if not allowed then return nil, authErr end
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    options = type(options) == "table" and options or {}

    local state = ensureState(registry)
    local budget = math.max(1, Util.integer(options.budget, GC.DEFAULT_SLICE_BUDGET))
    local now = math.max(0, finiteNumber(options.now, 0))

    if state.phase == "idle" then
        local ordered, snapErr, badID = snapshotProviders(options.providers)
        if not ordered then
            return {
                ok = false,
                completed = true,
                aborted = true,
                generation = state.generation,
                failedProviders = { { providerID = badID or "unknown", reason = snapErr } },
                purgedCount = 0,
            }
        end
        state.generation = math.max(0,
            Util.integer(registry.gcMeta and registry.gcMeta.generation, 0)) + 1
        state.phase = "marking"
        state.providers = ordered
        state.providerCursor = 1
        state.markedStrong = {}
        state.markedWeak = {}
        state.failedProviders = {}
        state.tombstoneSnapshot = {}
        state.sweepCursor = 1
        state.purgedRefs = {}
        state.retainedCount = 0
        state.skippedGraceCount = 0
        state.activeOwnershipBlocked = 0
        state.purgeFailedRefs = {}
        state.contextSnapshot = {
            survivorWorld = options.survivorWorld,
            worldKnowledge = options.worldKnowledge,
        }
    end

    local workUsed = 0
    local ctxBase = {
        registry = registry,
        now = now,
        generation = state.generation,
        survivorWorld = options.survivorWorld ~= nil
            and options.survivorWorld or state.contextSnapshot.survivorWorld,
        worldKnowledge = options.worldKnowledge ~= nil
            and options.worldKnowledge or state.contextSnapshot.worldKnowledge,
    }

    if state.phase == "marking" then
        while state.providerCursor <= #state.providers and workUsed < budget do
            local provider = state.providers[state.providerCursor]
            local ok, countOrErr = collectFromProvider(
                registry,
                provider,
                ctxBase,
                state.markedStrong,
                state.markedWeak
            )
            if not ok then
                state.failedProviders[#state.failedProviders + 1] = {
                    providerID = provider.id,
                    reason = tostring(countOrErr),
                }
            end
            state.providerCursor = state.providerCursor + 1
            workUsed = workUsed + 1
        end

        if state.providerCursor > #state.providers then
            if #state.failedProviders > 0 then
                local failed = Util.clone(state.failedProviders)
                local failedGen = state.generation
                state.phase = "idle"
                return {
                    ok = false,
                    completed = true,
                    aborted = true,
                    generation = failedGen,
                    failedProviders = failed,
                    purgedCount = 0,
                    purgedRefs = {},
                }
            end
            state.tombstoneSnapshot = sortedKeys(registry.tombstones)
            state.sweepCursor = 1
            state.phase = "sweeping"
        else
            return {
                ok = true,
                completed = false,
                aborted = false,
                phase = state.phase,
                generation = state.generation,
                providerCursor = state.providerCursor,
                providerTotal = #state.providers,
            }
        end
    end

    if state.phase == "sweeping" then
        while state.sweepCursor <= #state.tombstoneSnapshot and workUsed < budget do
            local ref = state.tombstoneSnapshot[state.sweepCursor]
            state.sweepCursor = state.sweepCursor + 1
            workUsed = workUsed + 1

            local ts = registry.tombstones and registry.tombstones[ref] or nil
            if ts ~= nil then
                if state.markedStrong[ref] ~= nil then
                    state.retainedCount = state.retainedCount + 1
                else
                    local graceLimit = math.max(
                        tonumber(ts.graceUntil) or tonumber(ts.retiredAt) or 0,
                        tonumber(ts.minPurgeAt) or 0
                    )
                    if options.ignoreGrace ~= true and now < graceLimit then
                        state.skippedGraceCount = state.skippedGraceCount + 1
                    else
                        local ownerCtx = {
                            registry = registry,
                            now = now,
                            generation = state.generation,
                            tombstone = Util.clone(ts),
                            survivorWorld = ctxBase.survivorWorld,
                            worldKnowledge = ctxBase.worldKnowledge,
                        }
                        local activeReasons = checkActiveOwnership(
                            registry,
                            ref,
                            state.providers,
                            ownerCtx
                        )
                        if #activeReasons > 0 then
                            state.activeOwnershipBlocked =
                                state.activeOwnershipBlocked + 1
                        else
                            local prePurgeOk = true
                            local prePurgeErr = nil
                            local prePurgeProvider = nil
                            local weakCompacted = 0
                            for _, provider in ipairs(state.providers) do
                                if type(provider.OnBeforePurge) == "function" then
                                    -- External/adopter GC pre-purge boundary: abort purging this ref on error.
                                    local ok, res, extra = pcall(
                                        provider.OnBeforePurge,
                                        ref,
                                        ownerCtx
                                    )
                                    if not ok then
                                        prePurgeOk = false
                                        prePurgeProvider = provider.id
                                        prePurgeErr = "on_before_purge_exception:" .. tostring(res)
                                        break
                                    elseif res == false then
                                        prePurgeOk = false
                                        prePurgeProvider = provider.id
                                        prePurgeErr = tostring(extra or "on_before_purge_failed")
                                        break
                                    elseif type(extra) == "number" then
                                        weakCompacted = weakCompacted + extra
                                    end
                                end
                            end

                            if not prePurgeOk then
                                state.purgeFailedRefs[#state.purgeFailedRefs + 1] = {
                                    ref = ref,
                                    providerID = prePurgeProvider,
                                    reason = prePurgeErr,
                                }
                            else
                                local purged, purgeErr = Lifecycle.PurgeTombstone(
                                    registry,
                                    ref,
                                    {
                                        authority = "server",
                                        reason = "gc_sweep",
                                        now = now,
                                        expectedLifecycleRevision = ts.rev,
                                    }
                                )
                                if purged then
                                    state.purgedRefs[#state.purgedRefs + 1] = ref
                                    recordPurgeExplanation(state, {
                                        purged = true,
                                        ref = ref,
                                        generation = state.generation,
                                        purgedAt = now,
                                        retiredAt = ts.retiredAt,
                                        graceUntil = ts.graceUntil,
                                        weakRefsCompacted = weakCompacted,
                                        weakRootsBeforePurge = Util.clone(
                                            state.markedWeak[ref] or {}
                                        ),
                                    })
                                else
                                    state.purgeFailedRefs[#state.purgeFailedRefs + 1] = {
                                        ref = ref,
                                        providerID = "PsychopatzCore.Lifecycle",
                                        reason = tostring(purgeErr),
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end

        if state.sweepCursor > #state.tombstoneSnapshot then
            local result = {
                ok = true,
                completed = true,
                aborted = false,
                generation = state.generation,
                purgedCount = #state.purgedRefs,
                purgedRefs = Util.clone(state.purgedRefs),
                retainedCount = state.retainedCount,
                skippedGraceCount = state.skippedGraceCount,
                activeOwnershipBlocked = state.activeOwnershipBlocked,
                purgeFailedRefs = Util.clone(state.purgeFailedRefs),
                markedStrongCount = countMapKeys(state.markedStrong),
                markedWeakCount = countMapKeys(state.markedWeak),
            }
            registry.gcMeta = {
                generation = state.generation,
                lastSweepAt = now,
            }
            state.phase = "idle"
            return result
        end

        return {
            ok = true,
            completed = false,
            aborted = false,
            phase = state.phase,
            generation = state.generation,
            cursor = state.sweepCursor,
            total = #state.tombstoneSnapshot,
            purgedSoFar = #state.purgedRefs,
        }
    end

    state.phase = "idle"
    return {
        ok = false,
        completed = true,
        aborted = true,
        generation = state.generation,
        purgedCount = 0,
    }
end

function GC.RunFull(registry, options)
    local allowed, authErr = Lifecycle.RequireServerAuthority(options)
    if not allowed then return nil, authErr end
    local stepOptions = {}
    if type(options) == "table" then
        for key, value in pairs(options) do
            stepOptions[key] = value
        end
    end
    stepOptions.budget = stepOptions.budget or GC.DEFAULT_SLICE_BUDGET

    local lastResult = nil
    for _ = 1, GC.MAX_RUN_FULL_STEPS do
        local res, err = GC.Step(registry, stepOptions)
        if not res then return nil, err end
        lastResult = res
        if res.completed == true then
            return res
        end
    end
    return lastResult, "gc_max_steps_exceeded"
end

function GC.ExplainRetention(registry, ref, options)
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    options = type(options) == "table" and options or {}
    local now = math.max(0, finiteNumber(options.now, 0))

    local resolved, resolveErr = Lifecycle.ResolveRef(registry, ref)
    if not resolved then return nil, resolveErr end

    local providers, snapErr, badID = snapshotProviders(options.providers)
    local strongMap, weakMap, failed = {}, {}, {}
    if not providers then
        failed[#failed + 1] = { providerID = badID or "unknown", reason = snapErr }
        providers = {}
    else
        local ctx = {
            registry = registry,
            now = now,
            readOnly = true,
            survivorWorld = options.survivorWorld,
            worldKnowledge = options.worldKnowledge,
        }
        for _, provider in ipairs(providers) do
            local ok, err = collectFromProvider(
                registry, provider, ctx, strongMap, weakMap
            )
            if not ok then
                failed[#failed + 1] = {
                    providerID = provider.id,
                    reason = tostring(err),
                }
            end
        end
    end

    local canonicalRef = resolved.canonicalRef
    local ts = resolved.tombstone
    local graceRemainingHours = 0
    if ts then
        local graceLimit = math.max(
            tonumber(ts.graceUntil) or tonumber(ts.retiredAt) or 0,
            tonumber(ts.minPurgeAt) or 0
        )
        graceRemainingHours = math.max(0, graceLimit - now)
    end

    local ownerCtx = {
        registry = registry,
        now = now,
        readOnly = true,
        tombstone = ts and Util.clone(ts) or nil,
        survivorWorld = options.survivorWorld,
        worldKnowledge = options.worldKnowledge,
    }
    local activeOwnershipReasons = checkActiveOwnership(
        registry, canonicalRef, providers, ownerCtx
    )
    local strongRoots = strongMap[canonicalRef] or {}
    local weakRoots = weakMap[canonicalRef] or {}

    local retained = resolved.status == Lifecycle.STATUS_LIVE
        or #strongRoots > 0
        or #activeOwnershipReasons > 0
        or (ts ~= nil and graceRemainingHours > 0)
        or #failed > 0

    return {
        ref = tostring(ref),
        canonicalRef = canonicalRef,
        status = resolved.status,
        hasTombstone = ts ~= nil,
        retained = retained,
        graceRemainingHours = graceRemainingHours,
        activeOwnershipReasons = activeOwnershipReasons,
        strongRoots = strongRoots,
        weakRoots = weakRoots,
        failedProviders = failed,
        wouldPurgeNow = resolved.status == Lifecycle.STATUS_RETIRED
            and ts ~= nil
            and not retained,
    }
end

function GC.ExplainPurge(registry, ref, options)
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    local norm = Lifecycle.NormalizeRef(ref)
    if not norm then return nil, "actor_reference_required" end

    local state = ensureState(registry)
    local recorded = state.purgeHistoryByRef[norm]
    if not recorded then
        local resolved = Lifecycle.ResolveRef(registry, norm)
        if resolved and state.purgeHistoryByRef[resolved.canonicalRef] then
            recorded = state.purgeHistoryByRef[resolved.canonicalRef]
        end
    end
    if recorded then
        return Util.clone(recorded)
    end

    local ret, err = GC.ExplainRetention(registry, ref, options)
    if not ret then return nil, err end

    local blocking = {}
    if ret.status == Lifecycle.STATUS_LIVE then
        blocking[#blocking + 1] = "actor_is_live"
    elseif not ret.hasTombstone then
        blocking[#blocking + 1] = "no_tombstone"
    end
    if ret.graceRemainingHours > 0 then
        blocking[#blocking + 1] = "grace_period_active"
    end
    for _, root in ipairs(ret.strongRoots) do
        blocking[#blocking + 1] = "strong_root:" .. root.providerID .. ":" .. root.reason
    end
    for _, ownerReason in ipairs(ret.activeOwnershipReasons) do
        blocking[#blocking + 1] = "active_owner:" .. ownerReason
    end
    for _, fail in ipairs(ret.failedProviders) do
        blocking[#blocking + 1] = "provider_failed:" .. fail.providerID .. ":" .. fail.reason
    end

    return {
        purged = false,
        ref = ret.canonicalRef,
        status = ret.status,
        eligible = ret.wouldPurgeNow,
        blockingReasons = blocking,
        strongRoots = ret.strongRoots,
        weakRoots = ret.weakRoots,
        graceRemainingHours = ret.graceRemainingHours,
        activeOwnershipReasons = ret.activeOwnershipReasons,
    }
end

function GC.GetDiagnostics(registry, options)
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    options = type(options) == "table" and options or {}
    local now = math.max(0, finiteNumber(options.now, 0))
    local state = ensureState(registry)

    local oldestAge = 0
    local tombstoneList = {}
    for _, ref in ipairs(sortedKeys(registry.tombstones)) do
        local ts = registry.tombstones[ref]
        tombstoneList[#tombstoneList + 1] = ts
        local age = math.max(0, now - (tonumber(ts.retiredAt) or 0))
        if age > oldestAge then oldestAge = age end
    end

    local tombstoneBytes = 0
    if #tombstoneList > 0 then
        local encoded = Json.Encode(tombstoneList)
        tombstoneBytes = type(encoded) == "string" and #encoded or 0
    end

    local orphanedAliases = 0
    for _, targetRef in pairs(registry.tombstoneAliases or {}) do
        if not registry.tombstones or not registry.tombstones[targetRef] then
            orphanedAliases = orphanedAliases + 1
        end
    end

    local providerCounts = {}
    local strongMap, weakMap = {}, {}
    local providers = snapshotProviders(options.providers)
    if providers then
        local ctx = {
            registry = registry,
            now = now,
            readOnly = true,
            survivorWorld = options.survivorWorld,
            worldKnowledge = options.worldKnowledge,
        }
        for _, provider in ipairs(providers) do
            local pStrong, pWeak = {}, {}
            local ok = collectFromProvider(registry, provider, ctx, pStrong, pWeak)
            providerCounts[provider.id] = {
                ok = ok == true,
                strong = countMapKeys(pStrong),
                weak = countMapKeys(pWeak),
            }
            for k, v in pairs(pStrong) do strongMap[k] = v end
            for k, v in pairs(pWeak) do weakMap[k] = v end
        end
    end

    return {
        generation = math.max(
            state.generation,
            Util.integer(registry.gcMeta and registry.gcMeta.generation, 0)
        ),
        phase = state.phase,
        cursor = state.phase == "marking" and state.providerCursor
            or (state.phase == "sweeping" and state.sweepCursor or 0),
        liveActors = countMapKeys(registry.records),
        tombstones = #tombstoneList,
        oldestTombstoneAgeHours = oldestAge,
        tombstoneBytesEstimate = tombstoneBytes,
        providerCount = countMapKeys(GC.Providers),
        providerCounts = providerCounts,
        orphanedAliasCount = orphanedAliases,
    }
end

function GC.ReconcileOnLoad(registry, options)
    local allowed, authErr = Lifecycle.RequireServerAuthority(options)
    if not allowed then return nil, authErr end
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    options = type(options) == "table" and options or {}

    local repairedConflicts = 0
    if type(registry.tombstones) == "table"
        and type(registry.records) == "table"
    then
        for _, ref in ipairs(sortedKeys(registry.tombstones)) do
            if registry.records[ref] ~= nil then
                registry.tombstones[ref] = nil
                repairedConflicts = repairedConflicts + 1
            end
        end
    end

    local aliases, ambiguous =
        Lifecycle.RebuildTombstoneIndex(registry.tombstones)
    registry.tombstoneAliases = aliases
    registry.tombstoneAmbiguousAliases = ambiguous

    local state = ensureState(registry)
    state.phase = "idle"

    local stepResult = nil
    if countMapKeys(registry.tombstones) > 0 then
        stepResult = GC.Step(registry, {
            authority = "server",
            budget = options.budget or GC.DEFAULT_SLICE_BUDGET,
            now = options.now or 0,
            survivorWorld = options.survivorWorld,
            worldKnowledge = options.worldKnowledge,
            providers = options.providers,
        })
    end

    return {
        ok = true,
        repairedConflicts = repairedConflicts,
        stepResult = stepResult,
    }
end

function GC.TickBudgeted(registry, options)
    local allowed, authErr = Lifecycle.RequireServerAuthority(options)
    if not allowed then return nil, authErr end
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    local state = ensureState(registry)
    local count = countMapKeys(registry.tombstones)
    if state.phase == "idle" and count < GC.TOMBSTONE_THRESHOLD then
        return { ok = true, skipped = true, reason = "below_threshold" }
    end
    return GC.Step(registry, options)
end

GC.RegisterBuiltinProviders()

return GC
