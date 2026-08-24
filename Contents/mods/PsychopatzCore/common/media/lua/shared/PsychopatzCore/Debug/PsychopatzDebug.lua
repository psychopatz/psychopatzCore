PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Debug = Core.Debug or {}
Core.Debug = Debug

Debug.COMMAND = Debug.COMMAND or "SetDebugAccess"
Debug.localOverride = Debug.localOverride == true
Debug.serverOverrides = Debug.serverOverrides or {}

local function callBoolean(target, method)
    if not target or type(target[method]) ~= "function" then
        return false
    end
    local ok, value = pcall(target[method], target)
    return ok and value == true
end

local function playerKey(player)
    if not player then return nil end
    local steamID = Core.GetSafeSteamID and Core.GetSafeSteamID(player) or "0"
    if steamID ~= "0" then return "steam:" .. steamID end
    if player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return "user:" .. username end
    end
    return nil
end

function Debug.IsEngineEnabled()
    if isDebugEnabled then
        local ok, enabled = pcall(isDebugEnabled)
        if ok and enabled == true then return true end
    end
    if getCore then
        local ok, gameCore = pcall(getCore)
        if ok and callBoolean(gameCore, "getDebug") then return true end
    end
    return false
end

function Debug.IsAdmin(player)
    if not player or not player.getAccessLevel then return false end
    local ok, access = pcall(player.getAccessLevel, player)
    return ok and string.lower(tostring(access or "")) == "admin"
end

function Debug.IsOwner(player)
    return Core.IsOwner and Core.IsOwner(player) == true or false
end

function Debug.IsLocalOverrideEnabled(player)
    if Debug.localOverride ~= true then return false end
    return not player or Debug.IsOwner(player)
end

function Debug.IsServerOverrideEnabled(player)
    local key = playerKey(player)
    return key ~= nil and Debug.serverOverrides[key] == true
end

function Debug.SetLocalOverride(enabled, player)
    if player and not Debug.IsOwner(player) then
        return false, "owner_required"
    end
    Debug.localOverride = enabled == true
    return true
end

function Debug.SetServerOverride(player, enabled)
    if not Debug.IsOwner(player) then
        return false, "owner_required"
    end
    local key = playerKey(player)
    if not key then return false, "player_required" end
    if enabled == true then
        Debug.serverOverrides[key] = true
    else
        Debug.serverOverrides[key] = nil
    end
    return true
end

-- This is the only debug authorization check that consuming mods should use.
-- Engine debug and real admin access are valid everywhere; the Psychopatz
-- override is deliberately restricted to the owner and is synchronized by
-- PsychopatzDebugServer before a multiplayer server accepts it.
function Debug.CanUse(player)
    if Debug.IsEngineEnabled() then return true end
    if Debug.IsAdmin(player) then return true end
    if Debug.IsServerOverrideEnabled(player) then return true end
    return Debug.IsLocalOverrideEnabled(player)
end

function Debug.GetStatus(player)
    local engine = Debug.IsEngineEnabled()
    local admin = Debug.IsAdmin(player)
    local serverOverride = Debug.IsServerOverrideEnabled(player)
    local localOverride = Debug.IsLocalOverrideEnabled(player)
    return {
        allowed = engine or admin or serverOverride or localOverride,
        engine = engine,
        admin = admin,
        localOverride = localOverride,
        serverOverride = serverOverride,
    }
end

return Debug
