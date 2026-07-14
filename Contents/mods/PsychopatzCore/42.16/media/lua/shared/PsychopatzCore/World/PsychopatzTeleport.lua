require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore.Teleport = PsychopatzCore.Teleport or {}

local Core = PsychopatzCore
local Teleport = Core.Teleport

Teleport.COMMAND = Teleport.COMMAND or "TeleportApproved"

local function normalizeCoordinates(x, y, z)
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)
    if not x or not y or not z or x ~= x or y ~= y or z ~= z then
        return nil
    end
    return x, y, math.floor(z)
end

local function executeClientTeleport(player, x, y, z)
    if isClient and isClient() and SendCommandToServer then
        -- This is the same native command used by the base-game teleport UI.
        -- PZ owns chunk streaming and the multiplayer teleport bookkeeping.
        SendCommandToServer("/teleportto " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
        return true
    end

    if player and player.teleportTo then
        player:teleportTo(x, y, z)
        return true
    end
    return false
end

--- Teleports a player to absolute world coordinates.
-- Call this only after the consuming mod has authorized the destination.
-- On an MP server it sends an approval to that player's client, which then
-- uses PZ's native teleport command. In single-player it moves the player
-- directly.
function Teleport.ToCoordinates(player, x, y, z)
    x, y, z = normalizeCoordinates(x, y, z)
    if not x or not player then
        return false, "invalid_destination"
    end

    if isServer and isServer() then
        if not sendServerCommand then
            return false, "server_command_unavailable"
        end
        sendServerCommand(player, Core.COMMAND_MODULE, Teleport.COMMAND, {
            x = x,
            y = y,
            z = z,
        })
        return true
    end

    if executeClientTeleport(player, x, y, z) then
        return true
    end
    return false, "teleport_unavailable"
end

local function onServerCommand(module, command, args)
    if module ~= Core.COMMAND_MODULE or command ~= Teleport.COMMAND then
        return
    end

    args = args or {}
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local x, y, z = normalizeCoordinates(args.x, args.y, args.z)
    if player and x then
        executeClientTeleport(player, x, y, z)
    end
end

if not Core._teleportClientHandlerInstalled
    and Events and Events.OnServerCommand and Events.OnServerCommand.Add then
    Events.OnServerCommand.Add(onServerCommand)
    Core._teleportClientHandlerInstalled = true
end

return Teleport
