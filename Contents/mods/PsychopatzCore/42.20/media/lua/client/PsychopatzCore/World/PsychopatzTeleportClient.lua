require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/World/PsychopatzTeleport"

local Core = PsychopatzCore
local Teleport = Core.Teleport

if Core._teleportClientInstalled then
    return Core
end
Core._teleportClientInstalled = true

Teleport.pending = Teleport.pending or {}
Teleport.pendingCount = Teleport.pendingCount or 0
Teleport.nextToken = Teleport.nextToken or 0

-- Frame-count safety net so a missing getTimestampMs() can never leak a
-- pending request forever.
local FALLBACK_TICKS = 180

local function nowMs()
    if type(getTimestampMs) ~= "function" then return nil end
    local ok, value = pcall(getTimestampMs)
    if ok and type(value) == "number" then return value end
    return nil
end

local function localPlayer()
    if type(getSpecificPlayer) == "function" then
        local player = getSpecificPlayer(0)
        if player then return player end
    end
    if type(getPlayer) == "function" then return getPlayer() end
    return nil
end

--- Brief on-screen feedback. Silently does nothing when the helper is absent.
function Teleport.Notify(player, message, isError)
    if not player or type(HaloTextHelper) ~= "table" then return end
    if type(HaloTextHelper.addTextWithArrow) ~= "function" then return end
    local getColour = isError and HaloTextHelper.getColorRed
        or HaloTextHelper.getColorGreen
    local colour
    if type(getColour) == "function" then colour = getColour() end
    pcall(HaloTextHelper.addTextWithArrow, player, tostring(message), true,
        colour)
end

local function dropPending(token)
    if Teleport.pending[token] == nil then return nil end
    local entry = Teleport.pending[token]
    Teleport.pending[token] = nil
    Teleport.pendingCount = Teleport.pendingCount - 1
    if Teleport.pendingCount < 0 then Teleport.pendingCount = 0 end
    return entry
end

--- Asks the server to authorize a destination. Returns false when no
-- transport is available so the caller can apply the teleport locally.
function Teleport.RequestApproval(player, x, y, z)
    if type(sendClientCommand) ~= "function" then return false end
    if not player then return false end

    Teleport.nextToken = Teleport.nextToken + 1
    local token = Teleport.nextToken
    local startedAt = nowMs()
    Teleport.pending[token] = {
        player = player,
        x = x,
        y = y,
        z = z,
        ticksLeft = FALLBACK_TICKS,
        expiresAt = startedAt and (startedAt + Teleport.APPROVAL_TIMEOUT_MS) or nil,
    }
    Teleport.pendingCount = Teleport.pendingCount + 1

    local ok = pcall(sendClientCommand, player, Core.COMMAND_MODULE,
        Teleport.REQUEST_COMMAND, { x = x, y = y, z = z, token = token })
    if not ok then
        dropPending(token)
        return false
    end
    return true
end

local function onServerCommand(module, command, args)
    if module ~= Core.COMMAND_MODULE then return end
    if command ~= Teleport.COMMAND then return end
    args = args or {}

    local x, y, z = Teleport.NormalizeCoordinates(args.x, args.y, args.z)
    if not x then return end

    local entry
    if args.token ~= nil then
        -- Reply to a request we made. A token that is not pending is either
        -- stale (the local fallback already fired) or forged; either way it
        -- must not move the player.
        entry = dropPending(args.token)
        if not entry then return end
    end

    local player = (entry and entry.player) or localPlayer()
    if not player then return end

    -- An unsolicited push has no local request behind it, so fall back to the
    -- local debug gate before honouring it.
    if not entry and not Teleport.CanUse(player) then return end

    local ok = Teleport.ApplyLocal(player, x, y, z)
    if ok then
        Teleport.Notify(player, "Teleport: " .. math.floor(x) .. ", "
            .. math.floor(y) .. " (z " .. math.floor(z) .. ")")
    end
end

local function onTick()
    if Teleport.pendingCount <= 0 then return end

    local now = nowMs()
    local expired
    for token, entry in pairs(Teleport.pending) do
        entry.ticksLeft = entry.ticksLeft - 1
        if entry.ticksLeft <= 0
            or (entry.expiresAt and now and now >= entry.expiresAt)
        then
            expired = expired or {}
            expired[#expired + 1] = token
        end
    end
    if not expired then return end

    local index = 1
    while index <= #expired do
        local entry = dropPending(expired[index])
        -- No approval came back: the server either does not run
        -- PsychopatzCore or refused this player. The local debug gate already
        -- allowed the request, so apply it here instead. The client owns its
        -- own position, so this still moves the player.
        if entry then
            local player = entry.player or localPlayer()
            if Teleport.ApplyLocal(player, entry.x, entry.y, entry.z) then
                Teleport.Notify(player, "Teleport: local fallback (server did "
                    .. "not authorize)")
            end
        end
        index = index + 1
    end
end

if Events and Events.OnServerCommand and Events.OnServerCommand.Add then
    Events.OnServerCommand.Add(onServerCommand)
end

if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(onTick)
end

return Core
