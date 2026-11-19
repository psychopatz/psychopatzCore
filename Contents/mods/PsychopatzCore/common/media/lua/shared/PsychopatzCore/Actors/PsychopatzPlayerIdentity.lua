-- PsychopatzPlayerIdentity: Canonical Cross-Adopter Player Social Target Identity
--
-- Owns the single persistent player-character identity contract for PsychopatzCore,
-- DynamicTrading, and ProjectHoomans.
--
-- Ensures:
-- 1. SP and MP player characters resolve to one durable target key:
--    - MP: player:<accountIdentity>:<characterUUID>
--    - SP: player:sp_slot_<slot>:<characterUUID>
-- 2. Character UUID is persisted in player modData (Core_CharacterUUID & PNC_CharacterUUID).
-- 3. Transient online reconnects/onlineID changes do NOT create new relationships.
-- 4. Legacy DT (player:user:*, player:online:*) and legacy Hoomans keys converge.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

local PlayerIdentity = {}

PlayerIdentity.UUID_PREFIX = "char_"
PlayerIdentity.MODDATA_CORE_UUID = "Core_CharacterUUID"
PlayerIdentity.MODDATA_PNC_UUID = "PNC_CharacterUUID"
PlayerIdentity.MODDATA_CORE_ACCOUNT = "Core_CharacterAccountKey"
PlayerIdentity.MODDATA_CORE_SIGNATURE = "Core_CharacterSignature"

local function safeCall(obj, method, ...)
    if not obj then return nil end
    local fn = obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, res = pcall(fn, obj, ...)
    if ok then return res end
    return nil
end

local function isSinglePlayerAuthority()
    local server = isServer and isServer() == true
    local client = isClient and isClient() == true
    return not server and not client
end

local function nowTimestamp()
    if type(getTimeInMillis) == "function" then
        local ms = tonumber(getTimeInMillis())
        if ms and ms == ms then return math.floor(ms / 1000) end
    end
    if type(getTimestampMs) == "function" then
        local ms = tonumber(getTimestampMs())
        if ms and ms == ms then return math.floor(ms / 1000) end
    end
    if type(getTimestamp) == "function" then
        local ts = tonumber(getTimestamp())
        if ts and ts == ts then return math.floor(ts) end
    end
    local gameTime = type(getGameTime) == "function" and getGameTime() or nil
    local hours = safeCall(gameTime, "getWorldAgeHours")
    if hours ~= nil then
        local numericHours = tonumber(hours)
        if numericHours and numericHours == numericHours then
            return math.floor(numericHours * 3600)
        end
    end
    return 0
end

local function randomInt(count)
    count = math.max(1, math.floor(tonumber(count) or 1))
    if type(ZombRand) == "function" then
        local value = tonumber(ZombRand(count))
        if value and value == value then
            return (math.abs(math.floor(value)) % count) + 1
        end
    end
    return math.random(1, count)
end

local function randomHex(len)
    local chars = "0123456789abcdef"
    local result = {}
    for i = 1, len do
        local r = randomInt(16)
        result[i] = string.sub(chars, r, r)
    end
    return table.concat(result)
end

local function nextIssuanceSequence(storage)
    storage.sequence = math.max(0, math.floor(tonumber(storage.sequence) or 0)) + 1
    return storage.sequence
end

PlayerIdentity.STORAGE_KEY = "PsychopatzCore.PlayerIdentity"

function PlayerIdentity.GetStorage()
    if ModData and type(ModData.getOrCreate) == "function" then
        local root = ModData.getOrCreate(PlayerIdentity.STORAGE_KEY)
        root.identities = root.identities or {}
        root.sequence = math.max(0, math.floor(tonumber(root.sequence) or 0))
        return root
    end
    PlayerIdentity._inMemoryStorage = PlayerIdentity._inMemoryStorage
        or { identities = {}, sequence = 0 }
    PlayerIdentity._inMemoryStorage.identities =
        PlayerIdentity._inMemoryStorage.identities or {}
    PlayerIdentity._inMemoryStorage.sequence = math.max(
        0,
        math.floor(tonumber(PlayerIdentity._inMemoryStorage.sequence) or 0)
    )
    return PlayerIdentity._inMemoryStorage
end

local function serverAuthorityAllowed(options)
    if RuntimeRole and type(RuntimeRole.AllowsServerCode) == "function"
        and not RuntimeRole.AllowsServerCode()
    then
        return false, "server_authority_required"
    end
    if type(options) == "table" and options.authority ~= nil
        and options.authority ~= "server"
    then
        return false, "server_authority_required"
    end
    return true
end

function PlayerIdentity.RegisterIssuedIdentity(uuid, accountKey, options)
    local normUUID = PlayerIdentity.NormalizeUUID(uuid)
    if not normUUID then return nil, "malformed_uuid" end
    local account = tostring(accountKey or "player")
    local storage = PlayerIdentity.GetStorage()
    local existing = storage.identities[normUUID]
    if existing then
        if tostring(existing.accountKey) ~= account then
            return nil, "cross_account_conflict"
        end
        if existing.lifecycleStatus == "RETIRED" then
            return nil, "identity_retired"
        end
        return existing
    end
    local seq = nextIssuanceSequence(storage)
    local record = {
        uuid = normUUID,
        accountKey = account,
        source = options and options.source or "core_generated",
        issuedAt = nowTimestamp(),
        issuedSeq = seq,
        lifecycleStatus = "LIVE",
        lifecycleRevision = 1,
    }
    if type(options) == "table" and type(options.displayName) == "string"
        and options.displayName ~= ""
    then
        record.displayName = string.sub(options.displayName, 1, 64)
    end
    storage.identities[normUUID] = record
    return record
end

function PlayerIdentity.IsIssuedIdentity(uuid, accountKey, options)
    local normUUID = PlayerIdentity.NormalizeUUID(uuid)
    if not normUUID then return false, "malformed_uuid" end
    local storage = PlayerIdentity.GetStorage()
    local record = storage.identities[normUUID]
    if not record then
        return false, "not_issued"
    end
    if accountKey ~= nil and tostring(record.accountKey) ~= tostring(accountKey) then
        return false, "account_mismatch"
    end
    local includeRetired = type(options) == "table" and options.includeRetired == true
    if not includeRetired and record.lifecycleStatus == "RETIRED" then
        return false, "identity_retired"
    end
    return true, record
end

function PlayerIdentity.ResolveIssuedIdentity(uuid, accountKey, options)
    local valid, res = PlayerIdentity.IsIssuedIdentity(uuid, accountKey, options)
    if valid then return res end
    return nil, res
end

function PlayerIdentity.RetireIssuedIdentity(uuid, accountKey, options)
    local allowed, authErr = serverAuthorityAllowed(options)
    if not allowed then return nil, authErr end
    local normUUID = PlayerIdentity.NormalizeUUID(uuid)
    if not normUUID then return nil, "malformed_uuid" end
    local storage = PlayerIdentity.GetStorage()
    local record = storage.identities[normUUID]
    if not record then return nil, "not_issued" end
    if accountKey ~= nil and tostring(record.accountKey) ~= tostring(accountKey) then
        return nil, "account_mismatch"
    end
    options = type(options) == "table" and options or {}
    if record.lifecycleStatus == "RETIRED" then
        if options.allowAlreadyRetired == true then
            return Util.clone(record), "already_retired"
        end
        return nil, "already_retired"
    end
    local currentRev = math.max(1, math.floor(tonumber(record.lifecycleRevision) or 1))
    if options.expectedLifecycleRevision ~= nil
        and tonumber(options.expectedLifecycleRevision) ~= currentRev
    then
        return nil, "lifecycle_revision_conflict"
    end
    local nextRev = math.max(currentRev + 1,
        math.floor(tonumber(options.lifecycleRevision) or (currentRev + 1)))
    record.lifecycleStatus = "RETIRED"
    record.lifecycleRevision = nextRev
    record.retiredAt = tonumber(options.retiredAt) or nowTimestamp()
    record.reason = tostring(options.reason or "player_death")
    if type(options.displayName) == "string" and options.displayName ~= "" then
        record.displayName = string.sub(options.displayName, 1, 64)
    end
    return Util.clone(record)
end

function PlayerIdentity.PurgeRetiredIdentity(uuid, accountKey, options)
    local allowed, authErr = serverAuthorityAllowed(options)
    if not allowed then return false, authErr end
    local normUUID = PlayerIdentity.NormalizeUUID(uuid)
    if not normUUID then return false, "malformed_uuid" end
    local storage = PlayerIdentity.GetStorage()
    local record = storage.identities[normUUID]
    if not record then return false, "not_issued" end
    if accountKey ~= nil and tostring(record.accountKey) ~= tostring(accountKey) then
        return false, "account_mismatch"
    end
    if record.lifecycleStatus ~= "RETIRED" then
        return false, "identity_not_retired"
    end
    storage.identities[normUUID] = nil
    return true
end

function PlayerIdentity.GetLifecycleState(uuid, accountKey)
    local record, reason = PlayerIdentity.ResolveIssuedIdentity(
        uuid, accountKey, { includeRetired = true }
    )
    if not record then
        return "FORGOTTEN", 0, reason
    end
    if record.lifecycleStatus == "RETIRED" then
        return "RETIRED", math.max(1, math.floor(tonumber(record.lifecycleRevision) or 2)), Util.clone(record)
    end
    return "LIVE", math.max(1, math.floor(tonumber(record.lifecycleRevision) or 1)), Util.clone(record)
end

function PlayerIdentity.Save()
    local storage = PlayerIdentity.GetStorage()
    return Util.clone(storage.identities)
end

function PlayerIdentity.Load(data)
    local storage = PlayerIdentity.GetStorage()
    storage.identities = {}
    local maxSeq = 0
    local loadedCount = 0
    if type(data) == "table" then
        local items = data.identities or data
        for k, v in pairs(items) do
            if type(v) == "table" and v.uuid then
                storage.identities[v.uuid] = Util.clone(v)
                loadedCount = loadedCount + 1
                local seq = tonumber(v.issuedSeq) or 0
                if seq > maxSeq then maxSeq = seq end
            elseif type(v) == "string" then
                storage.identities[k] = { uuid = k, accountKey = v }
                loadedCount = loadedCount + 1
            end
        end
    end
    storage.sequence = math.max(maxSeq, loadedCount, tonumber(type(data) == "table" and data.sequence) or 0)
    return true
end

function PlayerIdentity.Reset()
    local storage = PlayerIdentity.GetStorage()
    storage.identities = {}
    storage.sequence = 0
    if PlayerIdentity._inMemoryStorage then
        PlayerIdentity._inMemoryStorage.identities = {}
        PlayerIdentity._inMemoryStorage.sequence = 0
    end
    return true
end

function PlayerIdentity.GenerateUUID(accountKey)
    local storage = PlayerIdentity.GetStorage()
    local ts = nowTimestamp()
    local acct = tostring(accountKey or "anonymous")
    for attempt = 1, 16 do
        local seq = nextIssuanceSequence(storage)
        local entropy = tostring(randomInt(1000000))
        local seed = Util.hash(
            table.concat({ tostring(ts), tostring(seq), acct, entropy, tostring(attempt) }, ":")
        )
        local hex = string.format("%08x", seed)
            .. string.format("%04x", seq % 65536)
            .. randomHex(12)
        local candidate = PlayerIdentity.UUID_PREFIX .. hex
        if not storage.identities[candidate] then
            return candidate
        end
    end
    return PlayerIdentity.UUID_PREFIX .. string.format("%08x%08x", nextIssuanceSequence(storage), math.abs(ts) % 0xffffffff)
end

function PlayerIdentity.NormalizeUUID(value)
    if type(value) ~= "string" then return nil end
    local trimmed = string.match(value, "^%s*(.-)%s*$")
    if not trimmed or string.find(trimmed, ":", 1, true) then return nil end
    if string.match(trimmed, "^char_[%w_%-]+$") then
        return trimmed
    end
    return nil
end

function PlayerIdentity.SignProvenance(uuid, accountKey)
    if not uuid or not accountKey then return nil end
    local seed = "PsychopatzCore:PlayerIdentity:v1:" .. tostring(accountKey) .. ":" .. tostring(uuid)
    return "sig_" .. string.format("%08x", Util.hash(seed))
end

function PlayerIdentity.VerifyProvenance(player, claimedUUID, expectedAccountKey)
    if not player or not claimedUUID then return false, "missing_parameters" end
    local normUUID = PlayerIdentity.NormalizeUUID(claimedUUID)
    if not normUUID then return false, "malformed_uuid" end
    local accountKey = expectedAccountKey or PlayerIdentity.GetAccountKey(player)

    -- Authoritative Issuance Check: Core must have actually issued or adopted this identity!
    local issued, issueReason = PlayerIdentity.IsIssuedIdentity(normUUID, accountKey)
    if not issued then
        return false, issueReason or "not_issued"
    end

    local data = safeCall(player, "getModData") or (type(player) == "table" and player.modData)
    if type(data) ~= "table" then return false, "no_moddata" end
    local coreUUID = PlayerIdentity.NormalizeUUID(data[PlayerIdentity.MODDATA_CORE_UUID])
    if not coreUUID or coreUUID ~= normUUID then
        return false, "untrusted_uuid_mismatch"
    end
    local coreAccount = data[PlayerIdentity.MODDATA_CORE_ACCOUNT]
    if coreAccount and tostring(coreAccount) ~= tostring(accountKey) then
        return false, "account_mismatch"
    end
    local sig = data[PlayerIdentity.MODDATA_CORE_SIGNATURE]
    local expectedSig = PlayerIdentity.SignProvenance(normUUID, accountKey)
    if not sig or sig ~= expectedSig then
        return false, "invalid_signature"
    end
    return true, "valid_provenance"
end

function PlayerIdentity.GetCharacterUUID(player)
    if not player then return nil end

    -- Direct string candidate
    if type(player) == "string" then
        return PlayerIdentity.NormalizeUUID(player)
    end

    -- Object/table player candidate
    local data = safeCall(player, "getModData") or (type(player) == "table" and player.modData)
    if type(data) == "table" then
        -- 1. Check Core UUID
        local coreUUID = PlayerIdentity.NormalizeUUID(data[PlayerIdentity.MODDATA_CORE_UUID])
        if coreUUID then
            local accountKey = PlayerIdentity.GetAccountKey(player)
            if PlayerIdentity.IsIssuedIdentity(coreUUID, accountKey) then
                if not data[PlayerIdentity.MODDATA_PNC_UUID] then
                    data[PlayerIdentity.MODDATA_PNC_UUID] = coreUUID
                end
                if not data[PlayerIdentity.MODDATA_CORE_ACCOUNT] then
                    data[PlayerIdentity.MODDATA_CORE_ACCOUNT] = accountKey
                end
                if not data[PlayerIdentity.MODDATA_CORE_SIGNATURE] then
                    data[PlayerIdentity.MODDATA_CORE_SIGNATURE] = PlayerIdentity.SignProvenance(coreUUID, accountKey)
                end
                if not data["PNC_CharacterAccountKey"] then
                    data["PNC_CharacterAccountKey"] = accountKey
                end
                return coreUUID
            end
        end

        -- 2. Check existing Hoomans PNC UUID ONLY if already Core-issued
        local pncUUID = PlayerIdentity.NormalizeUUID(data[PlayerIdentity.MODDATA_PNC_UUID])
        if pncUUID then
            local accountKey = PlayerIdentity.GetAccountKey(player)
            if PlayerIdentity.IsIssuedIdentity(pncUUID, accountKey) then
                data[PlayerIdentity.MODDATA_CORE_UUID] = pncUUID
                data[PlayerIdentity.MODDATA_CORE_ACCOUNT] = accountKey
                data[PlayerIdentity.MODDATA_CORE_SIGNATURE] = PlayerIdentity.SignProvenance(pncUUID, accountKey)
                if not data["PNC_CharacterAccountKey"] then
                    data["PNC_CharacterAccountKey"] = accountKey
                end
                return pncUUID
            end
            -- An unknown/unissued PNC mirror must NEVER be auto-registered into Core authority.
        end

        -- 3. If neither exists, generate and store in both fields
        local accountKey = PlayerIdentity.GetAccountKey(player)
        local newUUID = PlayerIdentity.GenerateUUID(accountKey)
        PlayerIdentity.RegisterIssuedIdentity(newUUID, accountKey, { source = "core_generated" })
        data[PlayerIdentity.MODDATA_CORE_UUID] = newUUID
        data[PlayerIdentity.MODDATA_PNC_UUID] = newUUID
        data[PlayerIdentity.MODDATA_CORE_ACCOUNT] = accountKey
        data[PlayerIdentity.MODDATA_CORE_SIGNATURE] = PlayerIdentity.SignProvenance(newUUID, accountKey)
        data["PNC_CharacterAccountKey"] = accountKey
        data["PNC_CharacterIdentityVersion"] = 2
        return newUUID
    end

    -- Direct field fallback on mock/fixture objects
    if type(player) == "table" then
        local direct = PlayerIdentity.NormalizeUUID(player.characterUUID or player.uuid)
        if direct then return direct end
    end

    return nil
end

function PlayerIdentity.GetAccountKey(player)
    if not player then return "player" end

    if type(player) == "string" then
        local account = string.match(player, "^player:([^:]+):")
        if account then return account end
        return player
    end

    -- Explicit override on mock/fixture
    if type(player) == "table" and player.accountKey then
        return tostring(player.accountKey)
    end

    if isSinglePlayerAuthority() or (player.isLocalPlayer and player:isLocalPlayer() and not isClient()) then
        local slot = safeCall(player, "getPlayerNum")
        if slot == nil then slot = safeCall(player, "getPlayerIndex") end
        if slot ~= nil then
            return "sp_slot_" .. tostring(math.max(0, math.floor(tonumber(slot) or 0)))
        end
        -- Fall through to username for test doubles and players without slot
    end

    local username = safeCall(player, "getUsername") or (type(player) == "table" and player.username)
    if username and username ~= "" then
        return tostring(username)
    end

    return "player"
end

function PlayerIdentity.GetTargetKey(player)
    if not player then return nil end

    if type(player) == "string" then
        local trimmed = string.match(player, "^%s*(.-)%s*$")
        if not trimmed or trimmed == "" then return nil end
        -- Already canonical: player:<acc>:<uuid>
        if string.match(trimmed, "^player:[^:]+:char_[%w_%-]+$") then
            return trimmed
        end
        return trimmed
    end

    local uuid = PlayerIdentity.GetCharacterUUID(player)
    local accountKey = PlayerIdentity.GetAccountKey(player)
    if uuid and accountKey then
        return "player:" .. accountKey .. ":" .. uuid
    end

    -- Fallback for uninitialized transient players
    local username = safeCall(player, "getUsername") or (type(player) == "table" and player.username)
    if username and username ~= "" then
        return "player:user:" .. tostring(username)
    end

    return nil
end

function PlayerIdentity.GetLegacyKeys(player)
    local keys = {}
    if not player or type(player) == "string" then return keys end

    local username = safeCall(player, "getUsername") or (type(player) == "table" and player.username)
    if username and username ~= "" then
        keys[#keys + 1] = "player:user:" .. tostring(username)
        keys[#keys + 1] = "player:" .. tostring(username)
    end

    local onlineID = safeCall(player, "getOnlineID") or (type(player) == "table" and player.onlineID)
    if onlineID and tonumber(onlineID) and tonumber(onlineID) > 0 then
        keys[#keys + 1] = "player:online:" .. tostring(onlineID)
    end

    local slot = safeCall(player, "getPlayerNum") or (type(player) == "table" and player.playerNum)
    if slot ~= nil then
        keys[#keys + 1] = "player:sp_slot_" .. tostring(slot)
    end

    return keys
end

function PlayerIdentity.Parse(targetKey)
    if type(targetKey) ~= "string" then return nil end
    local account, uuid = string.match(targetKey, "^player:([^:]+):(char_[%w_%-]+)$")
    if account and uuid then
        return {
            targetKey = targetKey,
            kind = "player",
            accountKey = account,
            characterUUID = uuid,
            isCanonical = true,
        }
    end

    local user = string.match(targetKey, "^player:user:(.+)$")
    if user then
        return {
            targetKey = targetKey,
            kind = "player",
            username = user,
            isLegacy = true,
        }
    end

    local online = string.match(targetKey, "^player:online:(.+)$")
    if online then
        return {
            targetKey = targetKey,
            kind = "player",
            onlineID = online,
            isLegacy = true,
        }
    end

    return {
        targetKey = targetKey,
        kind = "unknown",
    }
end

local function resolvePlayerCanonicalRefForLifecycle(playerOrRef, explicitAccountKey)
    if type(playerOrRef) == "string" then
        local parsed = PlayerIdentity.Parse(playerOrRef)
        if parsed and parsed.isCanonical == true then
            return playerOrRef, parsed.accountKey, parsed.characterUUID
        end
        local normUUID = PlayerIdentity.NormalizeUUID(playerOrRef)
        if normUUID and explicitAccountKey then
            local acct = tostring(explicitAccountKey)
            return "player:" .. acct .. ":" .. normUUID, acct, normUUID
        end
        return nil
    end
    if type(playerOrRef) ~= "table" then return nil end

    local data = safeCall(playerOrRef, "getModData") or playerOrRef.modData
    if type(data) == "table" then
        local rawUUID = PlayerIdentity.NormalizeUUID(
            data[PlayerIdentity.MODDATA_CORE_UUID]
                or data[PlayerIdentity.MODDATA_PNC_UUID]
        )
        if rawUUID then
            local acct = tostring(explicitAccountKey
                or data[PlayerIdentity.MODDATA_CORE_ACCOUNT]
                or PlayerIdentity.GetAccountKey(playerOrRef))
            return "player:" .. acct .. ":" .. rawUUID, acct, rawUUID, playerOrRef
        end
    end

    local directUUID = PlayerIdentity.NormalizeUUID(playerOrRef.characterUUID or playerOrRef.uuid)
    if directUUID then
        local acct = tostring(explicitAccountKey or PlayerIdentity.GetAccountKey(playerOrRef))
        return "player:" .. acct .. ":" .. directUUID, acct, directUUID, playerOrRef
    end

    local key = PlayerIdentity.GetTargetKey(playerOrRef)
    local parsed = key and PlayerIdentity.Parse(key) or nil
    if parsed and parsed.isCanonical == true then
        return key, parsed.accountKey, parsed.characterUUID, playerOrRef
    end
    return nil
end

function PlayerIdentity.RetirePlayerCharacter(playerOrRef, options)
    local allowed, authErr = serverAuthorityAllowed(options)
    if not allowed then return nil, authErr end
    options = type(options) == "table" and options or {}

    local canonicalRef, accountKey, uuid, playerObj =
        resolvePlayerCanonicalRefForLifecycle(playerOrRef, options.accountKey)
    if not canonicalRef or not uuid then
        return nil, "player_ref_invalid"
    end

    local actors = PsychopatzCore and PsychopatzCore.Actors or nil
    local lifecycle = actors and actors.Lifecycle or nil
    if not lifecycle then
        local ok, mod = pcall(require, "PsychopatzCore/Actors/PsychopatzActorLifecycle")
        if ok and type(mod) == "table" then lifecycle = mod end
    end
    local registry = options.registry or (actors and actors.DefaultRegistry) or {}
    local label = options.label or options.displayName
        or (playerObj and safeCall(playerObj, "getDisplayName"))
        or nil

    if lifecycle and type(lifecycle.Retire) == "function" then
        return lifecycle.Retire(registry, canonicalRef, {
            authority = "server",
            reason = options.reason or "player_death",
            retiredAt = options.retiredAt,
            graceHours = options.graceHours,
            label = label,
            owner = options.owner or "PsychopatzCore",
            role = "player",
            expectedLifecycleRevision = options.expectedLifecycleRevision,
            allowAlreadyRetired = options.allowAlreadyRetired,
            adoptUnissued = options.adoptUnissued,
            source = options.source or "player_death",
        })
    end

    return PlayerIdentity.RetireIssuedIdentity(uuid, accountKey, {
        authority = "server",
        reason = options.reason or "player_death",
        retiredAt = options.retiredAt,
        displayName = label,
        expectedLifecycleRevision = options.expectedLifecycleRevision,
        allowAlreadyRetired = options.allowAlreadyRetired,
    })
end

function PlayerIdentity.ValidateLiveInteraction(playerOrRef, options)
    options = type(options) == "table" and options or {}
    local canonicalRef, accountKey, uuid, playerObj =
        resolvePlayerCanonicalRefForLifecycle(playerOrRef, options.accountKey)
    if not canonicalRef or not uuid then
        return false, "player_ref_invalid"
    end
    if options.expectedAccountKey ~= nil
        and tostring(options.expectedAccountKey) ~= tostring(accountKey)
    then
        return false, "account_mismatch"
    end

    local issuedRecord, issuedErr = PlayerIdentity.IsIssuedIdentity(
        uuid, accountKey, { includeRetired = true }
    )
    if not issuedRecord then
        if issuedErr == "account_mismatch" then return false, "account_mismatch" end
        return false, "actor_forgotten"
    end

    if playerObj then
        local data = safeCall(playerObj, "getModData") or playerObj.modData
        if type(data) == "table" and data[PlayerIdentity.MODDATA_CORE_SIGNATURE] ~= nil then
            local provOK, provErr = PlayerIdentity.VerifyProvenance(
                playerObj, uuid, accountKey
            )
            if not provOK then
                if provErr == "identity_retired" then
                    return false, "actor_retired"
                end
                return false, provErr or "untrusted_provenance"
            end
        end
    end

    local actors = PsychopatzCore and PsychopatzCore.Actors or nil
    local lifecycle = actors and actors.Lifecycle or nil
    if not lifecycle then
        local ok, mod = pcall(require, "PsychopatzCore/Actors/PsychopatzActorLifecycle")
        if ok and type(mod) == "table" then lifecycle = mod end
    end
    local registry = options.registry or (actors and actors.DefaultRegistry) or {}
    local status, rev
    if lifecycle and type(lifecycle.GetLifecycleState) == "function" then
        status, rev = lifecycle.GetLifecycleState(registry, canonicalRef)
    else
        status, rev = PlayerIdentity.GetLifecycleState(uuid, accountKey)
    end
    if status == "RETIRED" then
        return false, "actor_retired", rev
    end
    if status ~= "LIVE" then
        return false, "actor_forgotten", rev
    end
    if options.expectedLifecycleRevision ~= nil
        and tonumber(options.expectedLifecycleRevision) ~= tonumber(rev)
    then
        return false, "lifecycle_revision_conflict", rev
    end
    return true, {
        canonicalRef = canonicalRef,
        accountKey = accountKey,
        characterUUID = uuid,
        status = status,
        lifecycleRevision = rev,
    }
end

if Events and Events.OnPlayerDeath
    and type(Events.OnPlayerDeath.Add) == "function"
    and not PlayerIdentity._deathHookRegistered
then
    PlayerIdentity._deathHookRegistered = true
    Events.OnPlayerDeath.Add(function(player)
        if not serverAuthorityAllowed() or not player then return end
        PlayerIdentity.RetirePlayerCharacter(player, {
            authority = "server",
            reason = "player_death",
            allowAlreadyRetired = true,
            adoptUnissued = true,
        })
    end)
end

PsychopatzCore = PsychopatzCore or {}
-- Reading Actors through the lazy capability accessor here would re-enter
-- Actors while its dependencies are still loading.
local actors = rawget(PsychopatzCore, "Actors") or {}
PsychopatzCore.Actors = actors
actors.PlayerIdentity = PlayerIdentity
PsychopatzCore.PlayerIdentity = PlayerIdentity

return PlayerIdentity
