-- Canonical portable actor lifecycle state, compact tombstones, and bounded
-- identity projections across Core NPC/trader actors and player characters.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Identity = require "PsychopatzCore/Actors/PsychopatzActorIdentity"
local PlayerIdentity = require "PsychopatzCore/Actors/PsychopatzPlayerIdentity"
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

local Lifecycle = {}

Lifecycle.STATUS_LIVE = "LIVE"
Lifecycle.STATUS_RETIRED = "RETIRED"
Lifecycle.STATUS_FORGOTTEN = "FORGOTTEN"

Lifecycle.TOMBSTONE_SCHEMA = "PsychopatzCore.ActorTombstone"
Lifecycle.TOMBSTONE_SCHEMA_VERSION = 1
Lifecycle.PROJECTION_SCHEMA = "PsychopatzCore.ActorIdentityProjection"
Lifecycle.PROJECTION_SCHEMA_VERSION = 1

Lifecycle.DEFAULT_GRACE_HOURS = 168
Lifecycle.MAX_LABEL_LENGTH = 64
Lifecycle.MAX_OWNER_LENGTH = 48
Lifecycle.MAX_ROLE_LENGTH = 32
Lifecycle.MAX_TOMBSTONE_ALIASES = 4
Lifecycle.MAX_REF_LENGTH = 192
Lifecycle.FLAG_PLAYER_CHARACTER = 1

Lifecycle.VALID_KINDS = {
    npc = true,
    trader = true,
    player = true,
    actor = true,
}

Lifecycle.VALID_RETIRE_REASONS = {
    death = true,
    departed = true,
    player_death = true,
    retired = true,
    missing_permanent = true,
    other = true,
}

Lifecycle.VALID_HARD_DELETE_REASONS = {
    rollback = true,
    uncommitted_creation = true,
    superseded_migration = true,
    test_cleanup = true,
}

Lifecycle.FORBIDDEN_TOMBSTONE_FIELDS = {
    personalInventory = true,
    inventory = true,
    appearance = true,
    persona = true,
    knowledge = true,
    social = true,
    memories = true,
    relationships = true,
    world = true,
    providerLease = true,
    tasks = true,
    needs = true,
    body = true,
    transcript = true,
    stock = true,
    budget = true,
    quotes = true,
    extensions = true,
}

local ALLOWED_TOMBSTONE_FIELDS = {
    ref = true,
    kind = true,
    label = true,
    owner = true,
    retiredAt = true,
    reason = true,
    rev = true,
    graceUntil = true,
    minPurgeAt = true,
    role = true,
    aliases = true,
    flags = true,
}

local function markProjectionDirty(reason)
    local core = PsychopatzCore
    local sync = core and core.ActorProjectionSync or nil
    if sync and type(sync.MarkDirty) == "function" then
        sync.MarkDirty(reason)
    end
end

local function safeText(value, limit)
    local text = Util.text(value, nil)
    if not text or string.find(text, "[%c]") then
        return nil
    end
    if limit and #text > limit then
        text = string.sub(text, 1, limit)
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

local function worldNow(spec)
    if type(spec) == "table" then
        local explicit = finiteNumber(spec.retiredAt or spec.now, nil)
        if explicit ~= nil then return math.max(0, explicit) end
    end
    if type(getGameTime) == "function" then
        local gameTime = getGameTime()
        if gameTime and type(gameTime.getWorldAgeHours) == "function" then
            local hours = finiteNumber(gameTime:getWorldAgeHours(), nil)
            if hours ~= nil then return math.max(0, hours) end
        end
    end
    return 0
end

function Lifecycle.RequireServerAuthority(spec)
    if RuntimeRole and type(RuntimeRole.AllowsServerCode) == "function"
        and not RuntimeRole.AllowsServerCode()
    then
        return false, "server_authority_required"
    end
    if type(spec) == "table" and spec.authority ~= nil
        and spec.authority ~= "server"
    then
        return false, "server_authority_required"
    end
    return true
end

function Lifecycle.NormalizeRef(ref)
    if type(ref) == "string" then
        return safeText(ref, Lifecycle.MAX_REF_LENGTH)
    end
    if type(ref) ~= "table" then return nil end

    local directTarget = safeText(ref.targetKey, Lifecycle.MAX_REF_LENGTH)
    if directTarget then return directTarget end

    local idRef = Identity.ReferenceValue(ref)
    if idRef then return safeText(idRef, Lifecycle.MAX_REF_LENGTH) end

    local uuid = PlayerIdentity.NormalizeUUID(ref.characterUUID or ref.uuid)
    if uuid and ref.accountKey then
        return safeText(
            "player:" .. tostring(ref.accountKey) .. ":" .. uuid,
            Lifecycle.MAX_REF_LENGTH
        )
    end

    local modData = nil
    if type(ref.getModData) == "function" then
        modData = ref:getModData()
    elseif type(ref.modData) == "table" then
        modData = ref.modData
    end
    if type(modData) == "table" then
        local storedUUID = PlayerIdentity.NormalizeUUID(
            modData[PlayerIdentity.MODDATA_CORE_UUID]
                or modData[PlayerIdentity.MODDATA_PNC_UUID]
        )
        if storedUUID then
            local accountKey = modData[PlayerIdentity.MODDATA_CORE_ACCOUNT]
                or PlayerIdentity.GetAccountKey(ref)
            return safeText(
                "player:" .. tostring(accountKey) .. ":" .. storedUUID,
                Lifecycle.MAX_REF_LENGTH
            )
        end
    end

    return nil
end

function Lifecycle.ParsePlayerRef(ref)
    local norm = Lifecycle.NormalizeRef(ref)
    if not norm then return nil end
    local parsed = PlayerIdentity.Parse(norm)
    if parsed and parsed.isCanonical == true and parsed.kind == "player" then
        return parsed
    end
    return nil
end

function Lifecycle.IsPlayerRef(ref)
    return Lifecycle.ParsePlayerRef(ref) ~= nil
end

local function inferKindFromActor(actor, explicitKind)
    if explicitKind and Lifecycle.VALID_KINDS[explicitKind] then
        return explicitKind
    end
    local lease = type(actor) == "table" and actor.providerLease or nil
    local provider = type(lease) == "table" and lease.provider or nil
    if provider == "DTAbstract" or provider == "DTHoomans" then
        return "trader"
    end
    local ownerMod = type(actor) == "table" and actor.ownerMod or nil
    if ownerMod == "DynamicTrading" or ownerMod == "DTCommon"
        or ownerMod == "DTAbstract" or ownerMod == "DTHoomans"
    then
        return "trader"
    end
    return "npc"
end

local function inferKindFromRef(norm, explicitKind)
    if explicitKind and Lifecycle.VALID_KINDS[explicitKind] then
        return explicitKind
    end
    if Lifecycle.IsPlayerRef(norm) then return "player" end
    if string.sub(norm, 1, 7) == "trader:" then return "trader" end
    if string.sub(norm, 1, 4) == "npc:" then return "npc" end
    return "actor"
end

local function stripSocialPrefix(norm)
    if string.sub(norm, 1, 4) == "npc:" then
        return string.sub(norm, 5)
    end
    if string.sub(norm, 1, 6) == "actor:" then
        return string.sub(norm, 7)
    end
    return nil
end

local function collectCompactAliases(actor, canonicalRef, explicitAliases)
    local output = {}
    local seen = {}
    local function addAlias(value)
        if #output >= Lifecycle.MAX_TOMBSTONE_ALIASES then return end
        local alias = safeText(value, Lifecycle.MAX_REF_LENGTH)
        if not alias or alias == canonicalRef or seen[alias] then return end
        seen[alias] = true
        output[#output + 1] = alias
    end

    if type(explicitAliases) == "table" then
        for _, value in ipairs(explicitAliases) do
            addAlias(value)
        end
    end
    if type(actor) == "table" then
        if actor.actorId and actor.actorId ~= canonicalRef then
            addAlias(actor.actorId)
        end
        local desc = Identity.DescribeActor(actor)
        if desc and type(desc.aliases) == "table" then
            for _, value in ipairs(desc.aliases) do
                addAlias(value)
            end
        end
    end
    return output
end

function Lifecycle.ValidateTombstone(ts)
    if type(ts) ~= "table" then return false, "tombstone_invalid" end

    for key, _ in pairs(ts) do
        if Lifecycle.FORBIDDEN_TOMBSTONE_FIELDS[key] then
            return false, "tombstone_field_forbidden"
        end
        if not ALLOWED_TOMBSTONE_FIELDS[key] then
            return false, "tombstone_unknown_field"
        end
    end

    local ref = safeText(ts.ref, Lifecycle.MAX_REF_LENGTH)
    if not ref or ref ~= ts.ref then
        return false, "tombstone_ref_invalid"
    end
    if not Lifecycle.VALID_KINDS[ts.kind] then
        return false, "tombstone_kind_invalid"
    end
    if not Lifecycle.VALID_RETIRE_REASONS[ts.reason] then
        return false, "tombstone_reason_invalid"
    end

    local retiredAt = finiteNumber(ts.retiredAt, nil)
    local graceUntil = finiteNumber(ts.graceUntil, nil)
    local rev = Util.integer(ts.rev, nil)
    if retiredAt == nil or retiredAt < 0 then
        return false, "tombstone_retired_at_invalid"
    end
    if graceUntil == nil or graceUntil < retiredAt then
        return false, "tombstone_grace_invalid"
    end
    if ts.minPurgeAt ~= nil then
        local minPurgeAt = finiteNumber(ts.minPurgeAt, nil)
        if minPurgeAt == nil or minPurgeAt < retiredAt then
            return false, "tombstone_min_purge_invalid"
        end
    end
    if rev == nil or rev < 1 or rev ~= tonumber(ts.rev) then
        return false, "tombstone_revision_invalid"
    end

    if ts.label ~= nil then
        if type(ts.label) ~= "string" or ts.label == ""
            or #ts.label > Lifecycle.MAX_LABEL_LENGTH
            or string.find(ts.label, "[%c]")
        then
            return false, "tombstone_label_invalid"
        end
    end
    if ts.owner ~= nil then
        if type(ts.owner) ~= "string" or ts.owner == ""
            or #ts.owner > Lifecycle.MAX_OWNER_LENGTH
            or string.find(ts.owner, "[%c]")
        then
            return false, "tombstone_owner_invalid"
        end
    end
    if ts.role ~= nil then
        if type(ts.role) ~= "string" or ts.role == ""
            or #ts.role > Lifecycle.MAX_ROLE_LENGTH
            or string.find(ts.role, "[%c]")
        then
            return false, "tombstone_role_invalid"
        end
    end
    if ts.flags ~= nil then
        local flags = Util.integer(ts.flags, nil)
        if flags == nil or flags < 0 or flags ~= tonumber(ts.flags) then
            return false, "tombstone_flags_invalid"
        end
    end
    if ts.aliases ~= nil then
        if type(ts.aliases) ~= "table"
            or #ts.aliases > Lifecycle.MAX_TOMBSTONE_ALIASES
        then
            return false, "tombstone_aliases_invalid"
        end
        local seen = {}
        for index = 1, #ts.aliases do
            local alias = ts.aliases[index]
            local safe = safeText(alias, Lifecycle.MAX_REF_LENGTH)
            if not safe or safe ~= alias or safe == ref or seen[safe] then
                return false, "tombstone_aliases_invalid"
            end
            seen[safe] = true
        end
    end

    return true
end

function Lifecycle.BuildTombstone(spec)
    if type(spec) ~= "table" then return nil, "tombstone_spec_required" end

    for key, _ in pairs(spec) do
        if Lifecycle.FORBIDDEN_TOMBSTONE_FIELDS[key] then
            return nil, "tombstone_field_forbidden"
        end
    end

    local ref = safeText(spec.ref or spec.actorId or spec.actorID,
        Lifecycle.MAX_REF_LENGTH)
    if not ref then return nil, "tombstone_ref_invalid" end

    local kind = spec.kind or inferKindFromRef(ref)
    if not Lifecycle.VALID_KINDS[kind] then
        return nil, "tombstone_kind_invalid"
    end

    local reason = safeText(spec.reason, 32)
        or (kind == "player" and "player_death" or "death")
    if not Lifecycle.VALID_RETIRE_REASONS[reason] then
        return nil, "tombstone_reason_invalid"
    end

    local retiredAt = math.max(0, finiteNumber(spec.retiredAt, 0))
    local graceHours = math.max(0,
        finiteNumber(spec.graceHours, Lifecycle.DEFAULT_GRACE_HOURS))
    local graceUntil = finiteNumber(spec.graceUntil, nil)
    if graceUntil == nil then
        graceUntil = retiredAt + graceHours
    end
    graceUntil = math.max(retiredAt, graceUntil)

    local minPurgeAt = finiteNumber(spec.minPurgeAt, nil)
    if minPurgeAt ~= nil then
        minPurgeAt = math.max(retiredAt, minPurgeAt)
        if minPurgeAt == graceUntil then minPurgeAt = nil end
    end

    local rev = math.max(1, Util.integer(spec.rev or spec.lifecycleRevision, 1))
    local owner = safeText(spec.owner, Lifecycle.MAX_OWNER_LENGTH)
    if owner == "PsychopatzCore" then owner = nil end

    local ts = {
        ref = ref,
        kind = kind,
        retiredAt = retiredAt,
        reason = reason,
        rev = rev,
        graceUntil = graceUntil,
    }

    local label = safeText(spec.label or spec.displayName,
        Lifecycle.MAX_LABEL_LENGTH)
    if label then ts.label = label end
    if owner then ts.owner = owner end
    if minPurgeAt ~= nil then ts.minPurgeAt = minPurgeAt end
    local role = safeText(spec.role, Lifecycle.MAX_ROLE_LENGTH)
    if role then ts.role = role end

    if type(spec.aliases) == "table" and #spec.aliases > 0 then
        local aliases = {}
        local seen = {}
        for _, value in ipairs(spec.aliases) do
            if #aliases >= Lifecycle.MAX_TOMBSTONE_ALIASES then break end
            local alias = safeText(value, Lifecycle.MAX_REF_LENGTH)
            if alias and alias ~= ref and not seen[alias] then
                seen[alias] = true
                aliases[#aliases + 1] = alias
            end
        end
        if #aliases > 0 then ts.aliases = aliases end
    end

    local flags = Util.integer(spec.flags, 0)
    if kind == "player" and flags == 0 then
        flags = Lifecycle.FLAG_PLAYER_CHARACTER
    end
    if flags > 0 then ts.flags = flags end

    local valid, err = Lifecycle.ValidateTombstone(ts)
    if not valid then return nil, err end
    return ts
end

function Lifecycle.RebuildTombstoneIndex(tombstones)
    local aliases = {}
    local ambiguous = {}
    for canonicalRef, ts in pairs(tombstones or {}) do
        if type(ts) == "table" and type(ts.aliases) == "table" then
            for _, alias in ipairs(ts.aliases) do
                if alias ~= canonicalRef then
                    local previous = aliases[alias]
                    if previous and previous ~= canonicalRef then
                        ambiguous[alias] = true
                        aliases[alias] = nil
                    elseif not ambiguous[alias] then
                        aliases[alias] = canonicalRef
                    end
                end
            end
        end
    end
    return aliases, ambiguous
end

local function resolveCandidate(registry, candidate)
    if not candidate then return nil end

    if registry.records then
        local direct = registry.records[candidate]
        if direct then
            local desc = Identity.DescribeActor(direct)
            local canonicalRef = (desc and desc.canonicalActorID)
                or direct.actorId or candidate
            return {
                status = Lifecycle.STATUS_LIVE,
                kind = inferKindFromActor(direct),
                canonicalRef = canonicalRef,
                recordID = candidate,
                actor = direct,
            }
        end
        if registry.identityResolver then
            local resolved, resolveErr =
                registry.identityResolver:Resolve(candidate)
            if resolved and resolved.recordID then
                local actor = registry.records[resolved.recordID]
                if actor then
                    return {
                        status = Lifecycle.STATUS_LIVE,
                        kind = inferKindFromActor(actor),
                        canonicalRef = resolved.canonicalActorID
                            or actor.actorId,
                        recordID = resolved.recordID,
                        actor = actor,
                    }
                end
            elseif resolveErr == "actor_reference_ambiguous" then
                return nil, "actor_reference_ambiguous"
            end
        end
    end

    if registry.tombstones then
        local ts = registry.tombstones[candidate]
        if ts then
            return {
                status = Lifecycle.STATUS_RETIRED,
                kind = ts.kind or inferKindFromRef(ts.ref),
                canonicalRef = ts.ref,
                tombstone = ts,
            }
        end
        if registry.tombstoneAmbiguousAliases
            and registry.tombstoneAmbiguousAliases[candidate]
        then
            return nil, "actor_reference_ambiguous"
        end
        local aliased = registry.tombstoneAliases
            and registry.tombstoneAliases[candidate]
        if aliased and registry.tombstones[aliased] then
            local tsAlias = registry.tombstones[aliased]
            return {
                status = Lifecycle.STATUS_RETIRED,
                kind = tsAlias.kind or inferKindFromRef(tsAlias.ref),
                canonicalRef = tsAlias.ref,
                tombstone = tsAlias,
            }
        end
    end

    return nil
end

function Lifecycle.ResolveRef(registry, ref)
    local norm = Lifecycle.NormalizeRef(ref)
    if not norm then return nil, "actor_reference_required" end
    registry = type(registry) == "table" and registry or {}

    local direct, directErr = resolveCandidate(registry, norm)
    if direct then return direct end
    if directErr then return nil, directErr end

    local bare = stripSocialPrefix(norm)
    if bare then
        local bareResolved, bareErr = resolveCandidate(registry, bare)
        if bareResolved then return bareResolved end
        if bareErr then return nil, bareErr end
    end

    local parsedPlayer = Lifecycle.ParsePlayerRef(norm)
    if parsedPlayer then
        local issued = PlayerIdentity.ResolveIssuedIdentity(
            parsedPlayer.characterUUID,
            parsedPlayer.accountKey,
            { includeRetired = true }
        )
        if issued then
            if issued.lifecycleStatus == Lifecycle.STATUS_RETIRED then
                return {
                    status = Lifecycle.STATUS_RETIRED,
                    kind = "player",
                    canonicalRef = norm,
                    playerRecord = issued,
                    tombstone = registry.tombstones
                        and registry.tombstones[norm] or nil,
                }
            end
            return {
                status = Lifecycle.STATUS_LIVE,
                kind = "player",
                canonicalRef = norm,
                playerRecord = issued,
            }
        end
    end

    return {
        status = Lifecycle.STATUS_FORGOTTEN,
        kind = inferKindFromRef(norm),
        canonicalRef = norm,
    }
end

function Lifecycle.GetLifecycleState(registry, ref)
    local resolved, err = Lifecycle.ResolveRef(registry, ref)
    if not resolved then return nil, 0, err end

    if resolved.status == Lifecycle.STATUS_LIVE then
        local rev = 1
        if resolved.actor then
            rev = math.max(1,
                Util.integer(resolved.actor.lifecycleRevision, 1))
        elseif resolved.playerRecord then
            rev = math.max(1,
                Util.integer(resolved.playerRecord.lifecycleRevision, 1))
        end
        return Lifecycle.STATUS_LIVE, rev, resolved
    end

    if resolved.status == Lifecycle.STATUS_RETIRED then
        local rev = 2
        if resolved.tombstone then
            rev = math.max(1, Util.integer(resolved.tombstone.rev, 2))
        elseif resolved.playerRecord then
            rev = math.max(1,
                Util.integer(resolved.playerRecord.lifecycleRevision, 2))
        end
        return Lifecycle.STATUS_RETIRED, rev, resolved
    end

    local regRev = math.max(0,
        Util.integer(type(registry) == "table" and registry.lifecycleRevision, 0))
    return Lifecycle.STATUS_FORGOTTEN, regRev, resolved
end

function Lifecycle.ProjectIdentity(registry, ref)
    local status, rev, resolved = Lifecycle.GetLifecycleState(registry, ref)
    if not status then return nil, resolved end

    local out = {
        schema = Lifecycle.PROJECTION_SCHEMA,
        schemaVersion = Lifecycle.PROJECTION_SCHEMA_VERSION,
        ref = resolved.canonicalRef,
        status = status,
        kind = resolved.kind,
        lifecycleRevision = rev,
        hasTombstone = resolved.tombstone ~= nil,
    }

    if status == Lifecycle.STATUS_LIVE then
        if resolved.actor then
            local identity = resolved.actor.identity
            out.displayName = safeText(
                identity and identity.displayName,
                Lifecycle.MAX_LABEL_LENGTH
            )
            out.owner = safeText(resolved.actor.ownerMod,
                Lifecycle.MAX_OWNER_LENGTH)
        elseif resolved.playerRecord then
            out.displayName = safeText(
                resolved.playerRecord.displayName,
                Lifecycle.MAX_LABEL_LENGTH
            )
            out.owner = "PsychopatzCore"
            out.role = "player"
        end
    elseif status == Lifecycle.STATUS_RETIRED then
        local ts = resolved.tombstone
        local prec = resolved.playerRecord
        out.displayName = safeText(
            (ts and ts.label) or (prec and prec.displayName),
            Lifecycle.MAX_LABEL_LENGTH
        )
        out.role = ts and ts.role or (resolved.kind == "player" and "player" or nil)
        out.owner = (ts and (ts.owner or "PsychopatzCore"))
            or (prec and "PsychopatzCore")
        out.retiredAt = (ts and ts.retiredAt) or (prec and prec.retiredAt)
        out.reason = (ts and ts.reason) or (prec and prec.reason)
    end

    return out
end

local function rebuildLiveAndTombstoneIndexes(registry)
    if registry.identityResolver then
        local ok, reason = registry.identityResolver:Rebuild(registry.records)
        if not ok then return false, reason end
    end
    local aliases, ambiguous =
        Lifecycle.RebuildTombstoneIndex(registry.tombstones)
    registry.tombstoneAliases = aliases
    registry.tombstoneAmbiguousAliases = ambiguous
    return true
end

function Lifecycle.Retire(registry, ref, spec)
    local allowed, authErr = Lifecycle.RequireServerAuthority(spec)
    if not allowed then return nil, authErr end
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    spec = type(spec) == "table" and spec or {}

    local resolved, resolveErr = Lifecycle.ResolveRef(registry, ref)
    if not resolved then return nil, resolveErr end

    if resolved.status == Lifecycle.STATUS_RETIRED then
        if spec.allowAlreadyRetired == true and resolved.tombstone then
            return Util.clone(resolved.tombstone), "already_retired"
        end
        return nil, "already_retired"
    end

    local retiredAt = worldNow(spec)
    local graceHours = math.max(0,
        finiteNumber(spec.graceHours, Lifecycle.DEFAULT_GRACE_HOURS))

    -- Case A: live Core actor record
    if resolved.status == Lifecycle.STATUS_LIVE and resolved.recordID then
        local actor = registry.records[resolved.recordID]
        if not actor then return nil, "actor_not_found" end

        local currentLifecycleRev = math.max(1,
            Util.integer(actor.lifecycleRevision, 1))
        if spec.expectedLifecycleRevision ~= nil
            and Util.integer(spec.expectedLifecycleRevision, -1)
                ~= currentLifecycleRev
        then
            return nil, "lifecycle_revision_conflict"
        end

        local expectedActorRev = spec.expectedActorRevision or spec.expectedRevision
        if expectedActorRev ~= nil
            and Util.integer(expectedActorRev, -1)
                ~= Util.integer(actor.revision, -1)
        then
            return nil, "revision_conflict"
        end

        if spec.requireReleasedLease == true
            and type(actor.providerLease) == "table"
            and actor.providerLease.state == "materialized"
        then
            return nil, "body_lease_active"
        end

        local canonicalRef = resolved.canonicalRef
        if registry.tombstones[canonicalRef] then
            if spec.allowAlreadyRetired == true then
                return Util.clone(registry.tombstones[canonicalRef]),
                    "already_retired"
            end
            return nil, "already_retired"
        end

        local label = spec.label or spec.displayName
            or (actor.identity and actor.identity.displayName)
        local kind = inferKindFromActor(actor, spec.kind)
        local owner = spec.owner or actor.ownerMod
        local nextLifecycleRev = currentLifecycleRev + 1
        local aliases = collectCompactAliases(actor, canonicalRef, spec.aliases)

        local ts, tsErr = Lifecycle.BuildTombstone({
            ref = canonicalRef,
            kind = kind,
            label = label,
            owner = owner,
            retiredAt = retiredAt,
            reason = spec.reason or "death",
            rev = nextLifecycleRev,
            graceHours = graceHours,
            graceUntil = spec.graceUntil,
            minPurgeAt = spec.minPurgeAt,
            role = spec.role,
            aliases = aliases,
            flags = spec.flags,
        })
        if not ts then return nil, tsErr end

        registry.records[resolved.recordID] = nil
        registry.tombstones = registry.tombstones or {}
        registry.tombstones[canonicalRef] = ts

        local indexed, indexErr = rebuildLiveAndTombstoneIndexes(registry)
        if not indexed then
            registry.records[resolved.recordID] = actor
            registry.tombstones[canonicalRef] = nil
            rebuildLiveAndTombstoneIndexes(registry)
            return nil, indexErr
        end

        registry.revision = (tonumber(registry.revision) or 0) + 1
        registry.lifecycleRevision =
            (tonumber(registry.lifecycleRevision) or 0) + 1
        markProjectionDirty("actor_retired")
        return Util.clone(ts)
    end

    -- Case B: persistent player-character ref
    local parsedPlayer = Lifecycle.ParsePlayerRef(resolved.canonicalRef)
    if parsedPlayer then
        local issued, issueErr = PlayerIdentity.ResolveIssuedIdentity(
            parsedPlayer.characterUUID,
            parsedPlayer.accountKey,
            { includeRetired = true }
        )
        if not issued then
            if spec.adoptUnissued == true then
                local adopted, adoptErr = PlayerIdentity.RegisterIssuedIdentity(
                    parsedPlayer.characterUUID,
                    parsedPlayer.accountKey,
                    { source = spec.source or "lifecycle_adopted" }
                )
                if not adopted then return nil, adoptErr end
                issued = adopted
            else
                return nil, "player_identity_not_issued"
            end
        end

        local currentLifecycleRev = math.max(1,
            Util.integer(issued.lifecycleRevision, 1))
        if spec.expectedLifecycleRevision ~= nil
            and Util.integer(spec.expectedLifecycleRevision, -1)
                ~= currentLifecycleRev
        then
            return nil, "lifecycle_revision_conflict"
        end

        local nextLifecycleRev = currentLifecycleRev + 1
        local reason = safeText(spec.reason, 32) or "player_death"
        local label = safeText(
            spec.label or spec.displayName or issued.displayName,
            Lifecycle.MAX_LABEL_LENGTH
        )

        local ts, tsErr = Lifecycle.BuildTombstone({
            ref = resolved.canonicalRef,
            kind = "player",
            label = label,
            owner = spec.owner or "PsychopatzCore",
            retiredAt = retiredAt,
            reason = reason,
            rev = nextLifecycleRev,
            graceHours = graceHours,
            graceUntil = spec.graceUntil,
            minPurgeAt = spec.minPurgeAt,
            role = spec.role or "player",
            aliases = spec.aliases,
            flags = spec.flags or Lifecycle.FLAG_PLAYER_CHARACTER,
        })
        if not ts then return nil, tsErr end

        local retiredRecord, retireErr = PlayerIdentity.RetireIssuedIdentity(
            parsedPlayer.characterUUID,
            parsedPlayer.accountKey,
            {
                authority = "server",
                retiredAt = retiredAt,
                reason = reason,
                lifecycleRevision = nextLifecycleRev,
                displayName = label,
            }
        )
        if not retiredRecord then return nil, retireErr end

        registry.tombstones = registry.tombstones or {}
        registry.tombstones[resolved.canonicalRef] = ts
        local aliases, ambiguous =
            Lifecycle.RebuildTombstoneIndex(registry.tombstones)
        registry.tombstoneAliases = aliases
        registry.tombstoneAmbiguousAliases = ambiguous
        registry.revision = (tonumber(registry.revision) or 0) + 1
        registry.lifecycleRevision =
            (tonumber(registry.lifecycleRevision) or 0) + 1
        markProjectionDirty("player_retired")
        return Util.clone(ts)
    end

    return nil, "actor_not_found"
end

function Lifecycle.PurgeTombstone(registry, ref, spec)
    local allowed, authErr = Lifecycle.RequireServerAuthority(spec)
    if not allowed then return nil, authErr end
    if type(registry) ~= "table" then return nil, "actor_registry_required" end
    spec = type(spec) == "table" and spec or {}

    local resolved, resolveErr = Lifecycle.ResolveRef(registry, ref)
    if not resolved then return nil, resolveErr end
    if resolved.status ~= Lifecycle.STATUS_RETIRED or not resolved.tombstone then
        return nil, "tombstone_not_found"
    end

    local ts = resolved.tombstone
    if spec.expectedLifecycleRevision ~= nil
        and Util.integer(spec.expectedLifecycleRevision, -1)
            ~= Util.integer(ts.rev, -1)
    then
        return nil, "lifecycle_revision_conflict"
    end

    if ts.kind == "player" then
        local parsedPlayer = Lifecycle.ParsePlayerRef(ts.ref)
        if parsedPlayer then
            local issued = PlayerIdentity.ResolveIssuedIdentity(
                parsedPlayer.characterUUID,
                parsedPlayer.accountKey,
                { includeRetired = true }
            )
            if issued then
                local purged, purgeErr = PlayerIdentity.PurgeRetiredIdentity(
                    parsedPlayer.characterUUID,
                    parsedPlayer.accountKey,
                    { authority = "server" }
                )
                if not purged then return nil, purgeErr end
            end
        end
    end

    local snapshot = Util.clone(ts)
    registry.tombstones[ts.ref] = nil
    local aliases, ambiguous =
        Lifecycle.RebuildTombstoneIndex(registry.tombstones)
    registry.tombstoneAliases = aliases
    registry.tombstoneAmbiguousAliases = ambiguous
    registry.revision = (tonumber(registry.revision) or 0) + 1
    registry.lifecycleRevision =
        (tonumber(registry.lifecycleRevision) or 0) + 1
    markProjectionDirty("tombstone_purged")
    return true, snapshot
end

return Lifecycle
