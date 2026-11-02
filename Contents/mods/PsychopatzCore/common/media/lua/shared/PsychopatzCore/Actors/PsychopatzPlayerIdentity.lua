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

local function randomHex(len)
    local chars = "0123456789abcdef"
    local result = {}
    for i = 1, len do
        local r = math.random(1, 16)
        result[i] = string.sub(chars, r, r)
    end
    return table.concat(result)
end

PlayerIdentity.STORAGE_KEY = "PsychopatzCore.PlayerIdentity"

function PlayerIdentity.GetStorage()
    if ModData and type(ModData.getOrCreate) == "function" then
        local root = ModData.getOrCreate(PlayerIdentity.STORAGE_KEY)
        root.identities = root.identities or {}
        return root
    end
    PlayerIdentity._inMemoryStorage = PlayerIdentity._inMemoryStorage or { identities = {} }
    return PlayerIdentity._inMemoryStorage
end

function PlayerIdentity.RegisterIssuedIdentity(uuid, accountKey, options)
    local normUUID = PlayerIdentity.NormalizeUUID(uuid)
    if not normUUID then return nil, "malformed_uuid" end
    local account = tostring(accountKey or "player")
    local storage = PlayerIdentity.GetStorage()
    local existing = storage.identities[normUUID]
    if existing then
        if tostring(existing.accountKey) == account then
            return existing
        else
            return nil, "cross_account_conflict"
        end
    end
    local record = {
        uuid = normUUID,
        accountKey = account,
        source = options and options.source or "core_generated",
        issuedAt = (os.time and os.time()) or 0,
    }
    storage.identities[normUUID] = record
    return record
end

function PlayerIdentity.IsIssuedIdentity(uuid, accountKey)
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
    return true, record
end

function PlayerIdentity.ResolveIssuedIdentity(uuid, accountKey)
    local valid, res = PlayerIdentity.IsIssuedIdentity(uuid, accountKey)
    if valid then return res end
    return nil, res
end

function PlayerIdentity.Save()
    local storage = PlayerIdentity.GetStorage()
    return Util.clone(storage.identities)
end

function PlayerIdentity.Load(data)
    local storage = PlayerIdentity.GetStorage()
    storage.identities = {}
    if type(data) == "table" then
        local items = data.identities or data
        for k, v in pairs(items) do
            if type(v) == "table" and v.uuid then
                storage.identities[v.uuid] = Util.clone(v)
            elseif type(v) == "string" then
                storage.identities[k] = { uuid = k, accountKey = v }
            end
        end
    end
    return true
end

function PlayerIdentity.Reset()
    local storage = PlayerIdentity.GetStorage()
    storage.identities = {}
    if PlayerIdentity._inMemoryStorage then
        PlayerIdentity._inMemoryStorage.identities = {}
    end
    return true
end

function PlayerIdentity.GenerateUUID()
    local seed = Util.hash(tostring(os.time() or 123456) .. tostring(math.random(100000, 999999)))
    local hex = string.format("%08x", seed) .. randomHex(16)
    return PlayerIdentity.UUID_PREFIX .. hex
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
        local newUUID = PlayerIdentity.GenerateUUID()
        local accountKey = PlayerIdentity.GetAccountKey(player)
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

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = PsychopatzCore.Actors or {}
PsychopatzCore.Actors.PlayerIdentity = PlayerIdentity
PsychopatzCore.PlayerIdentity = PlayerIdentity

return PlayerIdentity
