require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/World/PsychopatzTeleport"

local Core = PsychopatzCore
local Teleport = Core.Teleport

if Core._teleportServerInstalled then
    return Core
end
Core._teleportServerInstalled = true

-- Refusals are logged once per player so a client that spams requests cannot
-- flood the server console, but a genuine authorization problem is still
-- visible when it first happens.
local refusedOnce = {}

local function logRefusal(player, reason)
    local key = tostring(player)
    if refusedOnce[key] then return end
    refusedOnce[key] = true
    local name = player and player.getUsername and player:getUsername() or "?"
    print("[PsychopatzCore.Teleport] refused " .. tostring(name)
        .. ": " .. tostring(reason))
end

local function onClientCommand(module, command, player, args)
    if module ~= Core.COMMAND_MODULE then return end
    if command ~= Teleport.REQUEST_COMMAND then return end
    if not player then return end

    -- The server is the authority here. Never trust the requesting client's
    -- claim of access, and never trust the coordinates it sent.
    if not Teleport.CanUse(player) then
        logRefusal(player, "not_authorized")
        return
    end

    args = args or {}
    local x, y, z = Teleport.NormalizeCoordinates(args.x, args.y, args.z)
    if not x then
        logRefusal(player, "invalid_destination")
        return
    end
    if not Teleport.IsInsideWorld(x, y) then
        logRefusal(player, "outside_world")
        return
    end

    -- Echo the already-resolved level back so the client lands exactly where
    -- it decided; re-resolving here could pick a different floor.
    if type(sendServerCommand) ~= "function" then return end
    sendServerCommand(player, Core.COMMAND_MODULE, Teleport.COMMAND, {
        x = x,
        y = y,
        z = z,
        token = args.token,
    })
end

if Events and Events.OnClientCommand and Events.OnClientCommand.Add then
    Events.OnClientCommand.Add(onClientCommand)
end

return Core
