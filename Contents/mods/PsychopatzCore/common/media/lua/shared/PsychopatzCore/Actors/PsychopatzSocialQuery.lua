-- Bounded lifecycle-aware social query & hot interaction context surface.
-- Hot interaction click paths read cached snapshots and O(1) identity
-- projections with zero GC sweeps, zero world scans, and zero raw tombstone
-- or unbounded memoryBank exposure.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local Retention = require "PsychopatzCore/Actors/PsychopatzSocialRetention"
local Lifecycle = require "PsychopatzCore/Actors/PsychopatzActorLifecycle"

local SocialQuery = {}

SocialQuery.SCHEMA_VERSION = 1
SocialQuery.MAX_MEMORIES = 8
SocialQuery.MAX_CANDIDATES = 16
SocialQuery.MAX_EVENT_FILTERS = 8
SocialQuery.RECENTLY_DEAD_HOURS = 72

local diagnostics = {
    hotOpenCount = 0,
    planExecCount = 0,
    tokenValidations = 0,
    tokenRejections = 0,
    maxMemoriesReturned = 0,
    gcCallsDuringHotOpen = 0,
    totalHotOpenMs = 0,
    totalPlanMs = 0,
}

local function currentTimeMs()
    if type(getTimeInMillis) == "function" then
        local v = tonumber(getTimeInMillis())
        if v and v == v then return v end
    end
    return 0
end

local function finite(value, fallback)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return fallback
    end
    return num
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, finite(value, low)))
end

local function safeProjectIdentity(registry, ref)
    if type(registry) == "table" and type(registry.ProjectIdentity) == "function" then
        return registry:ProjectIdentity(ref)
    end
    return Lifecycle.ProjectIdentity(registry, ref)
end

local function safeGetActor(registry, actorID)
    if type(registry) ~= "table" or type(actorID) ~= "string" or actorID == "" then
        return nil
    end
    if type(registry.Get) == "function" then
        return registry:Get(actorID)
    end
    if type(registry.records) == "table" then
        return registry.records[actorID]
    end
    return nil
end

local function gcGenerationOf(registry)
    if type(registry) ~= "table" then return 0 end
    local stateGen = type(registry._gcState) == "table"
        and tonumber(registry._gcState.generation) or 0
    local metaGen = type(registry.gcMeta) == "table"
        and tonumber(registry.gcMeta.generation) or 0
    return math.max(0, math.max(stateGen, metaGen))
end

function SocialQuery.ResetDiagnostics()
    diagnostics = {
        hotOpenCount = 0,
        planExecCount = 0,
        tokenValidations = 0,
        tokenRejections = 0,
        maxMemoriesReturned = 0,
        gcCallsDuringHotOpen = 0,
        totalHotOpenMs = 0,
        totalPlanMs = 0,
    }
    return true
end

function SocialQuery.GetDiagnostics()
    local avgHot = diagnostics.hotOpenCount > 0
        and (diagnostics.totalHotOpenMs / diagnostics.hotOpenCount) or 0
    local avgPlan = diagnostics.planExecCount > 0
        and (diagnostics.totalPlanMs / diagnostics.planExecCount) or 0
    return {
        hotOpenCount = diagnostics.hotOpenCount,
        planExecCount = diagnostics.planExecCount,
        tokenValidations = diagnostics.tokenValidations,
        tokenRejections = diagnostics.tokenRejections,
        maxMemoriesReturned = diagnostics.maxMemoriesReturned,
        gcCallsDuringHotOpen = diagnostics.gcCallsDuringHotOpen,
        totalHotOpenMs = diagnostics.totalHotOpenMs,
        avgHotOpenMs = avgHot,
        totalPlanMs = diagnostics.totalPlanMs,
        avgPlanMs = avgPlan,
    }
end

function SocialQuery.ProjectTargetReference(registry, ref, rel, mem, now, options)
    local rawLabel = (type(mem) == "table" and (mem.degradedLabel or mem.roleLabel))
        or (type(rel) == "table" and (rel.degradedLabel or rel.historicalLabel or rel.historicalRole))
        or (type(options) == "table" and (options.degradedLabel or options.roleLabel))
        or nil
    local hasLabel = type(rawLabel) == "string" and rawLabel ~= ""

    local refStr = type(ref) == "string" and ref or tostring(ref or "")
    if refStr == "" then
        return {
            schema = "PsychopatzCore.TargetReferenceProjection",
            schemaVersion = SocialQuery.SCHEMA_VERSION,
            ref = nil,
            status = Lifecycle.STATUS_FORGOTTEN,
            referenceMode = hasLabel and "LABEL_ONLY" or "ANONYMOUS",
            displayName = nil,
            role = hasLabel and rawLabel or nil,
            degradedLabel = hasLabel and rawLabel or "someone",
            lifecycleRevision = 0,
            recentlyDead = false,
        }
    end

    local proj = registry and safeProjectIdentity(registry, refStr) or nil
    local status = (proj and proj.status)
        or (type(rel) == "table" and rel.targetLifecycleStatus)
        or Lifecycle.STATUS_FORGOTTEN
    local lifecycleRev = tonumber((proj and proj.lifecycleRevision)
        or (type(rel) == "table" and rel.targetLifecycleRevision) or 0) or 0
    local canonicalRef = (proj and proj.ref) or refStr

    if status == Lifecycle.STATUS_LIVE then
        return {
            schema = "PsychopatzCore.TargetReferenceProjection",
            schemaVersion = SocialQuery.SCHEMA_VERSION,
            ref = canonicalRef,
            status = Lifecycle.STATUS_LIVE,
            referenceMode = "LIVE_ENTITY",
            displayName = proj and proj.displayName or nil,
            role = proj and proj.role or nil,
            lifecycleRevision = lifecycleRev,
            recentlyDead = false,
        }
    end

    if status == Lifecycle.STATUS_RETIRED then
        local retiredAt = proj and tonumber(proj.retiredAt) or nil
        local nowHours = tonumber(now)
        local recent = false
        if nowHours ~= nil and retiredAt ~= nil then
            local age = nowHours - retiredAt
            recent = age >= 0 and age <= SocialQuery.RECENTLY_DEAD_HOURS
        end
        return {
            schema = "PsychopatzCore.TargetReferenceProjection",
            schemaVersion = SocialQuery.SCHEMA_VERSION,
            ref = canonicalRef,
            status = Lifecycle.STATUS_RETIRED,
            referenceMode = "HISTORICAL_NAMED",
            displayName = (proj and proj.displayName)
                or (type(rel) == "table" and rel.historicalLabel)
                or nil,
            role = proj and proj.role or nil,
            retiredAt = retiredAt,
            reason = proj and proj.reason or nil,
            lifecycleRevision = lifecycleRev,
            recentlyDead = recent,
        }
    end

    return {
        schema = "PsychopatzCore.TargetReferenceProjection",
        schemaVersion = SocialQuery.SCHEMA_VERSION,
        ref = canonicalRef,
        status = Lifecycle.STATUS_FORGOTTEN,
        referenceMode = hasLabel and "LABEL_ONLY" or "ANONYMOUS",
        displayName = nil,
        role = hasLabel and rawLabel or nil,
        degradedLabel = hasLabel and rawLabel or "someone",
        lifecycleRevision = lifecycleRev,
        recentlyDead = false,
    }
end

local function buildDecisionToken(actorID, actorProj, targetIdentity, hotSnapshot, social, now)
    local relRev = tonumber(hotSnapshot and hotSnapshot.relationshipRevision) or 0
    local socialRev = tonumber((hotSnapshot and hotSnapshot.socialRevision)
        or (social and social.revision)) or 0
    return {
        schemaVersion = SocialQuery.SCHEMA_VERSION,
        actorID = tostring(actorID),
        targetRef = targetIdentity and targetIdentity.ref or nil,
        actorLifecycleStatus = actorProj and actorProj.status or Lifecycle.STATUS_FORGOTTEN,
        actorLifecycleRevision = tonumber(actorProj and actorProj.lifecycleRevision) or 0,
        targetLifecycleStatus = targetIdentity and targetIdentity.status or Lifecycle.STATUS_FORGOTTEN,
        targetLifecycleRevision = tonumber(targetIdentity and targetIdentity.lifecycleRevision) or 0,
        socialRevision = socialRev,
        relationshipRevision = relRev,
        issuedAt = tonumber(now) or 0,
    }
end

function SocialQuery.OpenInteractionHotContext(registry, actorID, targetRef, options)
    options = type(options) == "table" and options or {}
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    if type(actorID) ~= "string" or actorID == "" then
        return nil, "actor_id_required"
    end

    local startMs = currentTimeMs()
    local genBefore = gcGenerationOf(registry)
    diagnostics.hotOpenCount = diagnostics.hotOpenCount + 1

    local actorProj = safeProjectIdentity(registry, actorID)
    if not actorProj then
        diagnostics.totalHotOpenMs = diagnostics.totalHotOpenMs + math.max(0, currentTimeMs() - startMs)
        return nil, "actor_projection_failed"
    end
    if actorProj.status ~= Lifecycle.STATUS_LIVE and options.allowHistoricalRead ~= true then
        diagnostics.totalHotOpenMs = diagnostics.totalHotOpenMs + math.max(0, currentTimeMs() - startMs)
        local err = actorProj.status == Lifecycle.STATUS_RETIRED
            and "actor_retired" or "actor_forgotten"
        return nil, err, actorProj
    end

    local actor = safeGetActor(registry, actorID)
    if not actor and options.allowHistoricalRead ~= true then
        diagnostics.totalHotOpenMs = diagnostics.totalHotOpenMs + math.max(0, currentTimeMs() - startMs)
        return nil, "actor_not_found"
    end

    local social = (actor and actor.social) or Social.NewState({})
    local maxMems = math.max(0, math.min(4, math.floor(tonumber(options.maxMemories) or 4)))
    local hotSnapshot = targetRef and Social.GetHotRelationshipSnapshot(social, targetRef, {
        maxMemories = maxMems,
        registry = registry,
        now = options.now,
    }) or nil

    local rel = targetRef and Social.GetRelationshipSummary(social, targetRef) or nil
    local targetIdentity = targetRef
        and SocialQuery.ProjectTargetReference(registry, targetRef, rel, nil, options.now, options)
        or nil

    local token = buildDecisionToken(
        actorID,
        actorProj,
        targetIdentity,
        hotSnapshot,
        social,
        options.now
    )

    local genAfter = gcGenerationOf(registry)
    if genAfter ~= genBefore then
        diagnostics.gcCallsDuringHotOpen = diagnostics.gcCallsDuringHotOpen + 1
    end
    diagnostics.totalHotOpenMs = diagnostics.totalHotOpenMs + math.max(0, currentTimeMs() - startMs)

    return {
        schema = "PsychopatzCore.HotInteractionContext",
        schemaVersion = SocialQuery.SCHEMA_VERSION,
        actorIdentity = actorProj,
        targetIdentity = targetIdentity,
        hotSnapshot = hotSnapshot,
        decisionToken = token,
        revisions = {
            lifecycleRevision = actorProj.lifecycleRevision,
            targetLifecycleRevision = targetIdentity and targetIdentity.lifecycleRevision or 0,
            socialRevision = token.socialRevision,
            relationshipRevision = token.relationshipRevision,
        },
    }
end

local function normalizeSet(list, maxItems, transformFn)
    if type(list) ~= "table" then return nil end
    local set = {}
    local count = 0
    for index = 1, math.min(#list, maxItems) do
        local raw = list[index]
        local val = transformFn and transformFn(raw) or raw
        if type(val) == "string" and val ~= "" and not set[val] then
            set[val] = true
            count = count + 1
        end
    end
    return count > 0 and set or nil
end

local function collectPlanCandidates(social, plan)
    local targetRef = plan.targetRef or plan.target
    if type(targetRef) == "string" and targetRef ~= "" then
        return Social.GetMemoriesForTarget(social, targetRef, {
            includeAllRoles = plan.includeAllRoles == true,
        })
    end

    local seen = {}
    local out = {}
    local function addList(list)
        for index = 1, #(list or {}) do
            local mem = list[index]
            local id = type(mem) == "table" and mem.id or nil
            if id and not seen[id] then
                seen[id] = true
                out[#out + 1] = mem
            end
        end
    end

    if type(plan.retentionClasses) == "table" and #plan.retentionClasses > 0 then
        for index = 1, math.min(#plan.retentionClasses, 3) do
            addList(Social.GetMemoriesByClass(social, plan.retentionClasses[index]))
        end
        return out
    end

    if type(plan.eventTypes) == "table" and #plan.eventTypes > 0 then
        for index = 1, math.min(#plan.eventTypes, SocialQuery.MAX_EVENT_FILTERS) do
            addList(Social.GetMemoriesByEvent(social, plan.eventTypes[index]))
        end
        return out
    end

    addList(Social.GetMemoriesByClass(social, Retention.ANCHOR))
    addList(Social.GetMemoriesByClass(social, Retention.LONG))
    addList(Social.GetMemoriesByClass(social, Retention.SHORT))
    return out
end

local function compactSanitizedMemory(registry, rel, mem, strength, now)
    local cls = Retention.EffectiveClass(mem)
    local targetRef = mem.aboutKey or mem.targetKey
    local targetRefProj = SocialQuery.ProjectTargetReference(registry, targetRef, rel, mem, now)
    local sourceRefProj = type(mem.sourceKey) == "string" and mem.sourceKey ~= ""
        and SocialQuery.ProjectTargetReference(registry, mem.sourceKey, nil, mem, now)
        or nil

    return {
        id = mem.id,
        type = mem.type or "event",
        retentionClass = cls,
        refStrength = mem.refStrength,
        salience = Retention.MemorySalience(mem),
        effectiveStrength = strength,
        confidence = finite(
            mem.confidence,
            Retention.DefaultConfidence(mem.sourceMode, mem.knowledgeSource)
        ),
        sourceMode = Retention.NormalizeSourceMode(mem.sourceMode, mem.knowledgeSource),
        createdAt = mem.createdAt,
        count = tonumber(mem.count) or 1,
        targetReference = targetRefProj,
        sourceReference = sourceRefProj,
    }
end

function SocialQuery.ExecutePlan(registry, actorID, plan, options)
    options = type(options) == "table" and options or {}
    plan = type(plan) == "table" and plan or {}
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    if type(actorID) ~= "string" or actorID == "" then
        return nil, "actor_id_required"
    end

    local startMs = currentTimeMs()
    diagnostics.planExecCount = diagnostics.planExecCount + 1

    local actorProj = safeProjectIdentity(registry, actorID)
    if not actorProj then
        diagnostics.totalPlanMs = diagnostics.totalPlanMs + math.max(0, currentTimeMs() - startMs)
        return nil, "actor_projection_failed"
    end
    if actorProj.status ~= Lifecycle.STATUS_LIVE and options.allowHistoricalRead ~= true then
        diagnostics.totalPlanMs = diagnostics.totalPlanMs + math.max(0, currentTimeMs() - startMs)
        local err = actorProj.status == Lifecycle.STATUS_RETIRED
            and "actor_retired" or "actor_forgotten"
        return nil, err, actorProj
    end

    local actor = safeGetActor(registry, actorID)
    if not actor and options.allowHistoricalRead ~= true then
        diagnostics.totalPlanMs = diagnostics.totalPlanMs + math.max(0, currentTimeMs() - startMs)
        return nil, "actor_not_found"
    end

    local social = (actor and actor.social) or Social.NewState({})
    local now = finite(plan.now or options.now or options.worldAgeHours, nil)
    local targetRef = plan.targetRef or plan.target
    local rel = targetRef and Social.GetRelationshipSummary(social, targetRef) or nil
    local targetIdentity = targetRef
        and SocialQuery.ProjectTargetReference(registry, targetRef, rel, nil, now, options)
        or nil

    local maxMemories = math.floor(clamp(plan.maxMemories or 6, 0, SocialQuery.MAX_MEMORIES))
    local classSet = normalizeSet(plan.retentionClasses, 3, function(v)
        return Retention.NormalizeClass(v, false)
    end)
    local eventSet = normalizeSet(plan.eventTypes, SocialQuery.MAX_EVENT_FILTERS)
    local refStrengthSet = normalizeSet(plan.refStrengths, 3)
    local minSalience = finite(plan.minSalience, 0)

    local candidates = collectPlanCandidates(social, plan)
    local ranked = {}
    for index = 1, #candidates do
        local mem = candidates[index]
        if type(mem) == "table" then
            local cls = Retention.EffectiveClass(mem)
            local sal = Retention.MemorySalience(mem)
            local classOK = (not classSet) or classSet[cls] == true
            local eventOK = (not eventSet) or eventSet[tostring(mem.type or "")] == true
            local strOK = (not refStrengthSet)
                or refStrengthSet[tostring(mem.refStrength or "")] == true
            local salOK = sal >= minSalience
            if classOK and eventOK and strOK and salOK then
                local strength = Retention.CalculateMemoryStrength(mem, now)
                if strength > 0 then
                    local conf = clamp(finite(
                        mem.confidence,
                        Retention.DefaultConfidence(mem.sourceMode, mem.knowledgeSource)
                    ), 0, 1)
                    local priority = strength * (sal / 100) * conf
                    ranked[#ranked + 1] = {
                        view = compactSanitizedMemory(registry, rel, mem, strength, now),
                        priority = priority,
                        createdAt = finite(mem.createdAt, 0),
                        seq = finite(mem.eventSequence, 0),
                        id = tostring(mem.id or ""),
                    }
                end
            end
        end
    end

    table.sort(ranked, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        if a.createdAt ~= b.createdAt then return a.createdAt > b.createdAt end
        if a.seq ~= b.seq then return a.seq > b.seq end
        return a.id < b.id
    end)

    local memoriesOut = {}
    for index = 1, math.min(maxMemories, #ranked) do
        memoriesOut[index] = ranked[index].view
    end
    if #memoriesOut > diagnostics.maxMemoriesReturned then
        diagnostics.maxMemoriesReturned = #memoriesOut
    end

    local hotSnapshot = targetRef and Social.GetHotRelationshipSnapshot(social, targetRef, {
        maxMemories = 0,
        registry = registry,
        now = now,
    }) or nil
    local token = buildDecisionToken(actorID, actorProj, targetIdentity, hotSnapshot, social, now)

    local summary = nil
    if rel then
        summary = Util.clone(rel)
        summary.memories = nil
    end

    diagnostics.totalPlanMs = diagnostics.totalPlanMs + math.max(0, currentTimeMs() - startMs)

    return {
        schema = "PsychopatzCore.SocialQueryResult",
        schemaVersion = SocialQuery.SCHEMA_VERSION,
        actorIdentity = actorProj,
        targetIdentity = targetIdentity,
        relationshipSummary = summary,
        memories = memoriesOut,
        totalCandidateCount = #ranked,
        decisionToken = token,
        revisions = {
            lifecycleRevision = actorProj.lifecycleRevision,
            targetLifecycleRevision = targetIdentity and targetIdentity.lifecycleRevision or 0,
            socialRevision = token.socialRevision,
            relationshipRevision = token.relationshipRevision,
        },
    }
end

function SocialQuery.ValidateDecisionToken(registry, token, options)
    options = type(options) == "table" and options or {}
    diagnostics.tokenValidations = diagnostics.tokenValidations + 1

    local function reject(reason, detail)
        diagnostics.tokenRejections = diagnostics.tokenRejections + 1
        return false, reason, detail
    end

    if type(registry) ~= "table" then return reject("actor_registry_required") end
    if type(token) ~= "table" or type(token.actorID) ~= "string" or token.actorID == "" then
        return reject("decision_token_invalid")
    end

    local actorProj = safeProjectIdentity(registry, token.actorID)
    if not actorProj then return reject("actor_projection_failed") end
    if actorProj.status ~= Lifecycle.STATUS_LIVE then
        return reject(
            actorProj.status == Lifecycle.STATUS_RETIRED
                and "actor_retired" or "actor_forgotten",
            actorProj
        )
    end
    if token.actorLifecycleRevision ~= nil
        and tonumber(token.actorLifecycleRevision) ~= tonumber(actorProj.lifecycleRevision)
    then
        return reject("lifecycle_revision_conflict", actorProj)
    end

    local actor = safeGetActor(registry, token.actorID)
    if not actor then return reject("actor_not_found") end
    local social = actor.social
    local currentSocialRev = tonumber(social and social.revision) or 0
    if not options.allowSocialAdvance and token.socialRevision ~= nil
        and tonumber(token.socialRevision) ~= currentSocialRev
    then
        return reject("social_revision_conflict", {
            expected = token.socialRevision,
            actual = currentSocialRev,
        })
    end

    if type(token.targetRef) == "string" and token.targetRef ~= "" then
        if token.relationshipRevision ~= nil and social then
            local rel = Social.GetRelationshipSummary(social, token.targetRef)
            local currentRelRev = tonumber(rel and rel.revision) or 0
            if tonumber(token.relationshipRevision) ~= currentRelRev then
                return reject("relationship_revision_conflict", {
                    expected = token.relationshipRevision,
                    actual = currentRelRev,
                })
            end
        end

        local targetProj = safeProjectIdentity(registry, token.targetRef)
        if options.requireTargetLive == true
            and (not targetProj or targetProj.status ~= Lifecycle.STATUS_LIVE)
        then
            return reject(
                targetProj and targetProj.status == Lifecycle.STATUS_RETIRED
                    and "target_retired" or "target_forgotten",
                targetProj
            )
        end
        if options.strictTargetRevision == true and targetProj and (
            targetProj.status ~= token.targetLifecycleStatus
            or tonumber(targetProj.lifecycleRevision) ~= tonumber(token.targetLifecycleRevision)
        ) then
            return reject("target_lifecycle_conflict", targetProj)
        end
    end

    return true, {
        actorLifecycleRevision = actorProj.lifecycleRevision,
        socialRevision = currentSocialRev,
        relationshipRevision = token.relationshipRevision or 0,
    }
end

return SocialQuery
