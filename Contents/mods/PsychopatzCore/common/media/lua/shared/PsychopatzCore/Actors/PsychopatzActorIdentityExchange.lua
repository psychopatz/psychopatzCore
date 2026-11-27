-- Provider-neutral identity-exchange primitives shared by ProjectHoomans and
-- DynamicTrading (DTAbstract & DTHoomans). Pure Lua / Kahlua2-safe.

PsychopatzCore = PsychopatzCore or {}

local ActorNames = require "PsychopatzCore/Actors/PsychopatzActorNames"

local Exchange = PsychopatzCore.ActorIdentityExchange or {}
PsychopatzCore.ActorIdentityExchange = Exchange

Exchange.VERSION = 1
Exchange.EVENT_CLAIM = "identity_claim"
Exchange.EVENT_EVASION = "identity_evasion"
Exchange.TRUST_UNTRUSTWORTHY = "untrustworthy"

Exchange.FACET_TOPICS = {
    IDENTITY_NAME = "identity_name",
    IDENTITY_NICKNAME = "identity_nickname",
    IDENTITY_FULL_NAME = "identity_full_name",
    FACTION = "faction",
}

Exchange.FAMILIARITY_THRESHOLDS = {
    identity_name = 0,
    identity_nickname = 0,
    faction = 10,
    identity_surname = 20,
    identity_full_name = 25,
}

local function clean(value)
    if value == nil then return "" end
    value = tostring(value)
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "%s+", " ")
    return value
end

local function methodValue(target, name)
    local method = target and target[name]
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, target)
    return ok and value or nil
end

function Exchange.CleanName(value)
    return clean(value)
end

function Exchange.NormalizeName(value)
    return string.lower(clean(value))
end

function Exchange.NamesEqual(left, right)
    local normalizedLeft = Exchange.NormalizeName(left)
    local normalizedRight = Exchange.NormalizeName(right)
    return normalizedLeft ~= "" and normalizedLeft == normalizedRight
end

-- Exact full-name or single-component (forename or surname) match; never a
-- prefix or fuzzy match so typos/fake names are caught as lies.
function Exchange.ClaimMatchesName(claimed, canonical)
    local normalizedClaim = Exchange.NormalizeName(claimed)
    local normalizedCanonical = Exchange.NormalizeName(canonical)
    if normalizedClaim == "" or normalizedCanonical == "" then return false end
    if normalizedClaim == normalizedCanonical then return true end
    if string.find(normalizedClaim, "%s") then return false end
    local forename, surname = string.match(
        normalizedCanonical, "^([^%s]+)%s+(.+)$"
    )
    return normalizedClaim == forename or normalizedClaim == surname
end

function Exchange.FirstName(value)
    local text = clean(value)
    if text == "" then return "" end
    return string.match(text, "^(%S+)") or text
end

function Exchange.ResolvePlayerName(player)
    if not player then return "" end
    if type(player) == "table" then
        local display = clean(player.displayName or player.fullName)
        if display ~= "" then return display end
        local f = clean(player.forename or player.firstName)
        local s = clean(player.surname or player.lastName)
        if f ~= "" and s ~= "" then return f .. " " .. s end
        if f ~= "" then return f end
    end
    local desc = methodValue(player, "getDescriptor")
    if desc then
        local f = clean(methodValue(desc, "getForename"))
        local s = clean(methodValue(desc, "getSurname"))
        if f ~= "" and s ~= "" then return f .. " " .. s end
        if f ~= "" then return f end
    end
    local display = clean(methodValue(player, "getDisplayName"))
    if display ~= "" then return display end
    return clean(methodValue(player, "getUsername"))
end

function Exchange.PlayerIdentitySeed(source)
    if type(source) == "table" then
        local value = source.identitySeed or source.characterUUID
            or source.entityKey or source.playerIdentitySeed
        if value ~= nil and clean(value) ~= "" then return tostring(value) end
        local player = source.player
        if player then
            value = player.characterUUID
                or methodValue(player, "getUsername")
                or methodValue(player, "getOnlineID")
            if value ~= nil and clean(value) ~= "" then
                return tostring(value)
            end
        end
    end
    return "player"
end

function Exchange.PlayerIsFemale(source)
    if type(source) ~= "table" then return false end
    local gender = string.lower(tostring(source.gender or ""))
    if gender ~= "" then return gender == "female" end
    local value = source.isFemale
    if type(value) == "function" then value = methodValue(source, "isFemale") end
    if type(value) == "boolean" then return value end
    local player = source.player
    value = player and player.isFemale or nil
    if type(value) == "function" then value = methodValue(player, "isFemale") end
    if type(value) == "boolean" then return value end
    local desc = player and methodValue(player, "getDescriptor") or nil
    value = desc and desc.isFemale or nil
    if type(value) == "function" then value = methodValue(desc, "isFemale") end
    return value == true
end

function Exchange.GenerateAlias(source, options)
    source = type(source) == "table" and source or {}
    options = type(options) == "table" and options or {}
    local seed = Exchange.PlayerIdentitySeed(source)
    local actualName = source.playerName or source.displayName
    local saveSeed = options.saveSeed or source.saveSeed
    local isFemale = Exchange.PlayerIsFemale(source)
    if type(ActorNames.Generate) == "function" then
        for attempt = 1, 8 do
            local value = ActorNames.Generate(seed, isFemale, {
                saveSeed = saveSeed,
                namespace = "psychopatzcore.identity.alias." .. tostring(attempt),
            })
            if type(value) == "string" and value ~= ""
                and not Exchange.ClaimMatchesName(value, actualName)
            then
                return value
            end
        end
    end
    return isFemale and "Morgan Reed" or "Alex Reed"
end

-- Initial disclosure policy: at familiarity >= 25 reveal full name (with
-- optional nickname); below 25 reveal nickname if present, else first name.
function Exchange.ResolveInitialDisclosedName(parts, familiarity)
    parts = type(parts) == "table" and parts or {}
    familiarity = tonumber(familiarity) or 0
    local full = clean(parts.fullName or parts.displayName)
    local nick = clean(parts.nickname)
    local first = clean(parts.forename or parts.firstName)
    if first == "" and full ~= "" then first = Exchange.FirstName(full) end
    if familiarity >= Exchange.FAMILIARITY_THRESHOLDS.identity_full_name then
        if full ~= "" then
            if nick ~= "" and not Exchange.NamesEqual(full, nick)
                and not Exchange.NamesEqual(first, nick)
            then
                return full .. " (" .. nick .. ")", "full_name"
            end
            return full, "full_name"
        end
    end
    if nick ~= "" then
        return nick, "nickname"
    end
    if first ~= "" then
        return first, "first_name"
    end
    return full, "full_name"
end

function Exchange.VerifyClaim(claimedName, canonicalPlayerName, claimMode)
    local canonical = clean(canonicalPlayerName)
    local mode = tostring(claimMode or "")
    if mode == "canonical" then
        if canonical == "" then return false, "", "player_name_unavailable" end
        return true, canonical, nil
    end
    local claimed = clean(claimedName)
    if claimed == "" then return false, "", "identity_claim_missing" end
    if mode == "generated" then
        if canonical ~= "" and Exchange.ClaimMatchesName(claimed, canonical) then
            return false, claimed, "identity_alias_conflict"
        end
        return false, claimed, nil
    end
    if canonical == "" then return false, claimed, "player_name_unavailable" end
    local truthful = Exchange.ClaimMatchesName(claimed, canonical)
    return truthful, truthful and canonical or claimed, nil
end

return Exchange
