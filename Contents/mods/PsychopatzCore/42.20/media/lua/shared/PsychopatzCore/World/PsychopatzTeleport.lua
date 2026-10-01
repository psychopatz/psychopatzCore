require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/World/PsychopatzTeleportDestination"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Teleport = PsychopatzCore.Teleport or {}

local Core = PsychopatzCore
local Teleport = Core.Teleport
local Destination = Core.TeleportDestination

-- Both command names travel on Core.COMMAND_MODULE.
--   REQUEST_COMMAND: client -> server "may I move to these coordinates?"
--   COMMAND:         server -> client "yes, move to these coordinates"
Teleport.REQUEST_COMMAND = Teleport.REQUEST_COMMAND or "RequestTeleportApproval"
Teleport.COMMAND = Teleport.COMMAND or "TeleportApproved"

-- How long a multiplayer client waits for the server's approval before it
-- falls back to applying the teleport locally.
Teleport.APPROVAL_TIMEOUT_MS = 1000

-- Re-exported so callers have one place to look. The geometry itself lives in
-- PsychopatzTeleportDestination.
Teleport.MIN_Z = Destination.MIN_Z
Teleport.MAX_Z = Destination.MAX_Z
Teleport.NormalizeCoordinates = Destination.Normalize
Teleport.IsInsideWorld = Destination.IsInsideWorld
Teleport.ResolveDestination = Destination.Resolve

--- Single source of truth for debug authorization. This is the same gate
-- every other Psychopatz debug tool uses, so override/admin/debug semantics
-- stay identical across the arsenal.
function Teleport.CanUse(player)
    local debugAccess = Core.Debug
    return player ~= nil
        and debugAccess ~= nil
        and type(debugAccess.CanUse) == "function"
        and debugAccess.CanUse(player) == true
end

--- Applies the teleport on the peer that actually owns the player object.
-- In multiplayer the client owns its own position, so this is the only place
-- a teleport takes effect; the server can only authorize it.
function Teleport.ApplyLocal(player, x, y, z)
    if not player then return false, "player_required" end
    x, y, z = Destination.Normalize(x, y, z)
    if not x then return false, "invalid_destination" end

    -- A teleport in the middle of a timed action leaves the action resolving
    -- against a stale position. The engine clears its own state when it
    -- delivers a teleport packet; do the same for the Lua action queue.
    if ISTimedActionQueue and type(ISTimedActionQueue.clear) == "function" then
        pcall(ISTimedActionQueue.clear, player)
    end

    if type(player.teleportTo) ~= "function" then
        return false, "teleport_unavailable"
    end

    local ok, err = pcall(player.teleportTo, player, x, y, z)
    if not ok then
        return false, tostring(err)
    end
    return true
end

--- Server -> client push for a destination the caller has already authorized
-- itself. Safe for other core systems to use for players that are not their
-- own; it never authorizes, it only delivers.
function Teleport.PushToCoordinates(player, x, y, z)
    if not player then return false, "player_required" end
    x, y, z = Destination.Normalize(x, y, z)
    if not x then return false, "invalid_destination" end
    if type(sendServerCommand) ~= "function" then
        return false, "server_command_unavailable"
    end
    sendServerCommand(player, Core.COMMAND_MODULE, Teleport.COMMAND, {
        x = x,
        y = y,
        z = z,
    })
    return true
end

--- Teleports a player to absolute world coordinates.
--
-- Single-player applies immediately. A multiplayer client asks the server to
-- authorize, applies the approval when it arrives, and falls back to a
-- client-local apply if the server never answers (see
-- PsychopatzTeleportClient). A multiplayer server cannot move a remote
-- player's client by itself, so it pushes the destination instead.
--
-- options.exactZ     -- keep the requested level instead of preferring ground
-- options.bypassAuth -- trusted core systems that authorized on their own
function Teleport.ToCoordinates(player, x, y, z, options)
    options = options or {}
    if not player then return false, "player_required" end
    if not options.bypassAuth and not Teleport.CanUse(player) then
        return false, "not_authorized"
    end

    local targetX, targetY, targetZ, exact =
        Destination.Resolve(x, y, z, options.exactZ)
    if not targetX then return false, "invalid_destination" end

    local function apply()
        if Teleport.ApplyLocal(player, targetX, targetY, targetZ) then
            return true, "applied", targetX, targetY, targetZ, exact
        end
        return false, "teleport_unavailable"
    end

    -- A coop host is server and client in one process: it owns the player
    -- object and is already authoritative, so it applies directly, exactly as
    -- the base game does.
    if type(isCoopHost) == "function" and isCoopHost() then
        return apply()
    end

    -- A multiplayer client owns its own position but not the authority, so ask
    -- the server and apply the approval when it arrives.
    if type(isClient) == "function" and isClient() then
        if type(Teleport.RequestApproval) == "function"
            and Teleport.RequestApproval(player, targetX, targetY, targetZ)
        then
            return true, "requested", targetX, targetY, targetZ, exact
        end
        return apply()
    end

    -- A dedicated server cannot move a remote player's client by mutating its
    -- own copy, because position is client-authoritative. Deliver the
    -- destination and let that client apply it.
    if type(isServer) == "function" and isServer() then
        if Teleport.PushToCoordinates(player, targetX, targetY, targetZ) then
            return true, "pushed", targetX, targetY, targetZ, exact
        end
        return false, "teleport_unavailable"
    end

    -- Single-player.
    return apply()
end

return Teleport
