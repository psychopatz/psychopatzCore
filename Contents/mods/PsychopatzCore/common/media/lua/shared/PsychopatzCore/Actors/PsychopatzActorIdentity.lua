-- Provider-neutral actor identity and reference resolution.
-- Logical actor IDs are opaque.  Physical body IDs are presence metadata and
-- are deliberately not used as logical aliases.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Identity = {}

Identity.SCHEMA = "PsychopatzCore.ActorIdentity"
Identity.SCHEMA_VERSION = 1
Identity.EXTENSION = "PsychopatzCore.ActorIdentity"
Identity.MAX_ALIASES = 16
Identity.MAX_CAPABILITIES = 32

local function text(value)
    return Util.text(value, nil)
end

local function appendUnique(output, seen, value)
    value = text(value)
    if not value or seen[value] then return end
    seen[value] = true
    output[#output + 1] = value
end

local function appendAliases(output, seen, value)
    if #output >= Identity.MAX_ALIASES then return end
    if type(value) == "string" then
        appendUnique(output, seen, value)
        return
    end
    if type(value) ~= "table" then return end

    local values = {}
    for key, child in pairs(value) do
        if type(key) == "number" then
            values[#values + 1] = child
        elseif child == true then
            values[#values + 1] = key
        end
    end
    table.sort(values, function(left, right)
        return tostring(left) < tostring(right)
    end)
    for _, child in ipairs(values) do
        if #output >= Identity.MAX_ALIASES then return end
        appendUnique(output, seen, child)
    end
end

local function normalizedCapabilities(value)
    if type(value) ~= "table" then return nil end
    local output = {}
    local count = 0
    for key, enabled in pairs(value) do
        local capability = text(key)
        if capability and enabled == true then
            count = count + 1
            if count > Identity.MAX_CAPABILITIES then break end
            output[capability] = true
        end
    end
    return count > 0 and output or nil
end

local function mergedCapabilities(base, overlay)
    local output = normalizedCapabilities(base) or {}
    local additions = normalizedCapabilities(overlay) or {}
    local count = 0
    for key in pairs(output) do count = count + 1 end
    for key in pairs(additions) do
        if output[key] == nil and count < Identity.MAX_CAPABILITIES then
            output[key] = true
            count = count + 1
        end
    end
    return count > 0 and output or nil
end

local function metadata(actor)
    local extensions = actor
        and type(actor.extensions) == "table"
        and actor.extensions or {}
    local value = extensions[Identity.EXTENSION]
    return type(value) == "table" and value or {}
end

local function sourceAliases(actor, output, seen)
    local source = actor and actor.source
    if type(source) ~= "table" then return end
    for _, key in ipairs({
        "actorID", "actorId", "id", "npcID", "npcId", "memberID",
        "memberId", "traderID", "traderId",
    }) do
        appendAliases(output, seen, source[key])
        if #output >= Identity.MAX_ALIASES then return end
    end
end

function Identity.DescribeActor(actor, spec)
    if type(actor) ~= "table" then return nil, "actor_required" end
    spec = type(spec) == "table" and spec or {}

    local actorID = text(actor.actorId or actor.actorID)
    if not actorID then return nil, "actor_id_required" end
    local meta = metadata(actor)
    local canonical = text(
        spec.canonicalActorID
            or spec.canonicalActorId
            or meta.canonicalActorID
            or meta.canonicalActorId
            or actorID
    )
    if not canonical then return nil, "canonical_actor_id_required" end

    local aliases = {}
    local seen = {}
    appendAliases(aliases, seen, spec.aliases)
    appendAliases(aliases, seen, meta.aliases)
    appendAliases(aliases, seen, actorID)
    sourceAliases(actor, aliases, seen)
    if canonical ~= actorID then appendAliases(aliases, seen, actorID) end

    local lease = actor.providerLease or {}
    local state = text(
        spec.presenceState or spec.presenceMode or meta.presenceState
            or lease.state
    ) or "released"
    local provider = text(
        spec.providerID or spec.provider or meta.providerID or meta.provider
            or lease.provider or actor.ownerMod
    ) or "PsychopatzCore"
    local bodyID = text(spec.bodyID or spec.bodyId or lease.bodyID)
    if state ~= "materialized" and state ~= "live" then bodyID = nil end

    local capabilities = mergedCapabilities(
        meta.capabilities,
        spec.capabilities
    )

    return {
        schema = Identity.SCHEMA,
        schemaVersion = Identity.SCHEMA_VERSION,
        canonicalActorID = canonical,
        aliases = aliases,
        bodyID = bodyID,
        providerID = provider,
        presenceState = state,
        capabilities = capabilities,
    }
end

function Identity.ReferenceValue(reference)
    if type(reference) == "table" then
        for _, key in ipairs({
            "canonicalActorID", "canonicalActorId", "actorID", "actorId",
            "sourceRef", "id", "npcID", "npcId", "memberID", "memberId",
            "traderID", "traderId",
        }) do
            local value = text(reference[key])
            if value then return value end
        end
        return nil
    end
    return text(reference)
end

local Resolver = {}
Resolver.__index = Resolver

function Identity.NewResolver(records)
    local resolver = setmetatable({
        canonical = {},
        aliases = {},
        ambiguous = {},
        records = {},
    }, Resolver)
    if records then
        local ok, reason = resolver:Rebuild(records)
        if not ok then return nil, reason end
    end
    return resolver
end

function Resolver:Rebuild(records)
    if type(records) ~= "table" then return false, "records_required" end
    local canonical = {}
    local aliases = {}
    local ambiguous = {}
    local outputRecords = {}

    for recordID, actor in pairs(records) do
        local description, reason = Identity.DescribeActor(actor)
        if not description then return false, reason end
        local owner = tostring(recordID)
        local canonicalID = description.canonicalActorID
        local existing = canonical[canonicalID]
        if existing and existing.recordID ~= owner then
            return false, "canonical_actor_id_collision"
        end
        canonical[canonicalID] = {
            recordID = owner,
            canonicalActorID = canonicalID,
            aliasKind = "canonical",
        }
        outputRecords[owner] = actor

        for _, alias in ipairs(description.aliases or {}) do
            if alias ~= canonicalID then
                local previous = aliases[alias]
                if previous and previous.recordID ~= owner then
                    ambiguous[alias] = true
                    aliases[alias] = nil
                elseif not ambiguous[alias] then
                    aliases[alias] = {
                        recordID = owner,
                        canonicalActorID = canonicalID,
                        aliasKind = "alias",
                    }
                end
            end
        end
    end

    self.canonical = canonical
    self.aliases = aliases
    self.ambiguous = ambiguous
    self.records = outputRecords
    return true
end

function Resolver:Resolve(reference)
    local value = Identity.ReferenceValue(reference)
    if not value then return nil, "actor_reference_required" end
    if self.ambiguous[value] then
        return nil, "actor_reference_ambiguous"
    end
    local resolved = self.canonical[value] or self.aliases[value]
    if not resolved then return nil, "actor_not_found" end
    return Util.clone(resolved)
end

function Resolver:Has(reference)
    return self:Resolve(reference) ~= nil
end

Identity.Resolver = Resolver

return Identity
