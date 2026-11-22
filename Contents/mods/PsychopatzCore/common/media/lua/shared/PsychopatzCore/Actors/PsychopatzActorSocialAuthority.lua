local Social = require "PsychopatzCore/Actors/PsychopatzSocial"
local SocialQuery = require "PsychopatzCore/Actors/PsychopatzSocialQuery"

local Authority = {}

local function registryFor(core)
    local owner = core or PsychopatzCore
    local actors = owner and owner.Actors
    return actors and actors.DefaultRegistry or nil
end

local function requireServerAuthority()
    local runtimeRole = PsychopatzCore
        and PsychopatzCore.RuntimeRole or nil
    if runtimeRole and type(runtimeRole.AllowsServerCode) == "function"
        and not runtimeRole.AllowsServerCode()
    then
        return nil, "server_authority_required"
    end
    return true
end

local function requireActor(actorID, core)
    if type(actorID) ~= "string" or actorID == "" then
        return nil, "actor_id_required"
    end
    local registry = registryFor(core)
    if not registry then return nil, "core_registry_unavailable" end
    local actor, reason = registry:Get(actorID)
    if not actor then return nil, reason or "actor_not_found" end
    return actor, registry
end

local function peekActor(actorID, core)
    if type(actorID) ~= "string" or actorID == "" then
        return nil, "actor_id_required"
    end
    local registry = registryFor(core)
    if not registry then return nil, "core_registry_unavailable" end
    local actor, reason
    if type(registry.Peek) == "function" then
        actor, reason = registry:Peek(actorID)
    else
        actor, reason = registry:Get(actorID)
    end
    if not actor then return nil, reason or "actor_not_found" end
    return actor, registry
end

local function commitSocial(actorID, social, core, expectedRevision, options)
    local allowed, reason = requireServerAuthority()
    if not allowed then return nil, reason end

    local actor, registry = peekActor(actorID, core)
    if not actor then return nil, registry end

    if type(social) ~= "table" then
        local _, invalidReason = Social.NewState(social)
        return nil, invalidReason or "social_state_required"
    end

    if expectedRevision == nil then
        expectedRevision = actor.revision
    end
    -- Registry:Commit already clones, normalizes via Social.NewState, and
    -- validates patch.social, avoiding a redundant full-graph pass here.
    return registry:Commit(actorID, { social = social }, expectedRevision, options)
end

function Authority.Get(actorID, core)
    return requireActor(actorID, core)
end

function Authority.GetSocial(actorID, core)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end
    return Social.NewState(actor.social)
end

function Authority.CommitSocial(actorID, social, core, expectedRevision, options)
    return commitSocial(actorID, social, core, expectedRevision, options)
end

function Authority.MutateRelationship(actorID, target, mutatorFn, core,
    expectedActorRevision, expectedRelationshipRevision)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local relationship
    relationship, reason = Social.MutateRelationship(
        social,
        target,
        mutatorFn,
        "server",
        expectedRelationshipRevision
    )
    if not relationship then return nil, reason end

    return commitSocial(actorID, social, core, expectedActorRevision)
end

function Authority.RecordAuthorizedEvent(actorID, event, core,
    expectedActorRevision)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local updated
    updated, reason = Social.RecordAuthorizedEvent(social, event)
    if not updated then return nil, reason end

    return commitSocial(actorID, updated, core, expectedActorRevision)
end

function Authority.SetExtension(actorID, target, extensionID, payload, core,
    expectedActorRevision)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local updated
    updated, reason = Social.SetExtension(
        social,
        target,
        extensionID,
        payload,
        "server"
    )
    if not updated then return nil, reason end

    return commitSocial(actorID, updated, core, expectedActorRevision)
end

function Authority.SetPersonality(actorID, personality, core,
    expectedActorRevision)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local updated
    updated, reason = Social.SetPersonality(
        social,
        personality,
        "server"
    )
    if not updated then return nil, reason end

    return commitSocial(actorID, updated, core, expectedActorRevision)
end

function Authority.RecalculateRelationship(actorID, target, worldAgeHours,
    core, expectedActorRevision, options)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local updated
    updated, reason = Social.RecalculateRelationship(
        social,
        target,
        worldAgeHours,
        options
    )
    if not updated then return nil, reason end

    return commitSocial(actorID, social, core, expectedActorRevision)
end

function Authority.QueryCandidateProjection(actorID, target, options, core)
    local actor, reason = peekActor(actorID, core)
    if not actor then return nil, reason end
    local social = actor.social
    if not social then return nil, "social_state_invalid" end
    return Social.QueryCandidateProjection(social, target, options)
end

function Authority.GetHotRelationshipSnapshot(actorID, target, options, core)
    local actor, reason = peekActor(actorID, core)
    if not actor then return nil, reason end
    local social = actor.social
    if not social then return nil, "social_state_invalid" end
    local queryOpts = type(options) == "table" and options or {}
    if queryOpts.registry == nil then
        local copied = {}
        for k, v in pairs(queryOpts) do copied[k] = v end
        copied.registry = registryFor(core)
        queryOpts = copied
    end
    return Social.GetHotRelationshipSnapshot(social, target, queryOpts)
end

function Authority.OpenInteractionHotContext(actorID, target, options, core)
    local registry = registryFor(core)
    if not registry then return nil, "core_registry_unavailable" end
    return SocialQuery.OpenInteractionHotContext(registry, actorID, target, options)
end

function Authority.ExecuteSocialQueryPlan(actorID, plan, options, core)
    local registry = registryFor(core)
    if not registry then return nil, "core_registry_unavailable" end
    return SocialQuery.ExecutePlan(registry, actorID, plan, options)
end

function Authority.ValidateDecisionToken(token, options, core)
    local registry = registryFor(core)
    if not registry then return false, "core_registry_unavailable" end
    return SocialQuery.ValidateDecisionToken(registry, token, options)
end

function Authority.CompactHistoricalEdge(actorID, target, tombstoneOrInfo, core,
    expectedActorRevision)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local compacted
    compacted, reason = Social.CompactHistoricalEdge(social, target, tombstoneOrInfo)
    if not compacted then return nil, reason end

    return commitSocial(actorID, social, core, expectedActorRevision)
end

function Authority.RemoveMemory(actorID, memoryID, core, expectedActorRevision)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local ok
    ok, reason = Social.RemoveMemory(social, memoryID, "server")
    if not ok then return nil, reason end

    return commitSocial(actorID, social, core, expectedActorRevision)
end

return Authority
