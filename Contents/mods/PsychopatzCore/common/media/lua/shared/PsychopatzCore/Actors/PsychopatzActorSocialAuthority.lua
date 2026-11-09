local Social = require "PsychopatzCore/Actors/PsychopatzSocial"

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

local function commitSocial(actorID, social, core, expectedRevision)
    local allowed, reason = requireServerAuthority()
    if not allowed then return nil, reason end

    local actor, registry = requireActor(actorID, core)
    if not actor then return nil, registry end

    local normalized
    normalized, reason = Social.NewState(social)
    if not normalized then return nil, reason end
    local valid
    valid, reason = Social.Validate(normalized)
    if not valid then return nil, reason end

    if expectedRevision == nil then
        expectedRevision = actor.revision
    end
    return registry:Commit(actorID, { social = normalized }, expectedRevision)
end

function Authority.Get(actorID, core)
    return requireActor(actorID, core)
end

function Authority.GetSocial(actorID, core)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end
    return Social.NewState(actor.social)
end

function Authority.CommitSocial(actorID, social, core, expectedRevision)
    return commitSocial(actorID, social, core, expectedRevision)
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

function Authority.MigrateAliases(actorID, canonicalKey, aliasKeys, core,
    expectedActorRevision)
    local actor, reason = Authority.Get(actorID, core)
    if not actor then return nil, reason end

    local social = Social.NewState(actor.social)
    if not social then return nil, "social_state_invalid" end
    local migrated
    migrated, reason = Social.MigrateAliases(social, canonicalKey, aliasKeys)
    if not migrated then return nil, reason end

    return commitSocial(actorID, social, core, expectedActorRevision)
end

return Authority
