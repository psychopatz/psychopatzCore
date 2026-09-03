PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ZombieKillDetector =
    PsychopatzCore.ZombieKillDetector or {}

local Core = PsychopatzCore
local Detector = Core.ZombieKillDetector
local Internal = Detector.Internal or {}
local RuntimeRole = Core.RuntimeRole

Detector.Internal = Internal
Detector.VERSION = Detector.VERSION or 1
Detector.COMMAND = Detector.COMMAND or "ZombieKillReport"
Detector.COMMAND_MODULE = Detector.COMMAND_MODULE
    or Core.COMMAND_MODULE or "PsychopatzCore"
Detector.Consumers = Detector.Consumers or {}
Detector.ClientKillReports = Detector.ClientKillReports or {}
Detector.ProcessedThreatDeaths = Detector.ProcessedThreatDeaths or {}

local REPORT_TTL_MS = 15000
local DEATH_DEDUPE_TTL_MS = 15000

local function call(object, method, ...)
    if not object or not object[method] then
        return nil
    end
    local ok, value = pcall(object[method], object, ...)
    if ok then
        return value
    end
    return nil
end

local function nowMillis()
    if getTimeInMillis then
        return tonumber(getTimeInMillis()) or 0
    end
    if getTimestampMs then
        return tonumber(getTimestampMs()) or 0
    end
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return math.floor(
            (tonumber(getGameTime():getWorldAgeHours()) or 0) * 3600000
        )
    end
    return 0
end

local function runtimeIsClient()
    return RuntimeRole and RuntimeRole.IsClient
        and RuntimeRole.IsClient() == true
        or (isClient and isClient() or false)
end

local function runtimeIsServer()
    return RuntimeRole and RuntimeRole.IsServer
        and RuntimeRole.IsServer() == true
        or (isServer and isServer() or false)
end

local function isPureClient()
    if RuntimeRole and RuntimeRole.IsPureClient then
        return RuntimeRole.IsPureClient() == true
    end
    return runtimeIsClient() and not runtimeIsServer()
end

local function isAuthority()
    if RuntimeRole and RuntimeRole.AllowsServerCode then
        return RuntimeRole.AllowsServerCode() == true
    end
    return not isPureClient()
end

local function runtimeRole()
    if runtimeIsClient() and runtimeIsServer() then
        return "listen_server"
    end
    if runtimeIsClient() then
        return "pure_client"
    end
    if runtimeIsServer() then
        return "dedicated_server"
    end
    return "single_player"
end

local function isPlayer(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoPlayer")
    end
    return tostring(call(character, "getObjectName") or "") == "Player"
end

local function isZombie(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoZombie")
    end
    return tostring(call(character, "getObjectName") or "") == "Zombie"
end

local function isLocalPlayer(player)
    local playerNum
    local localPlayer
    if not isPlayer(player) then
        return false
    end
    if player.isLocalPlayer then
        local ok, result = pcall(player.isLocalPlayer, player)
        if ok and result == true then
            return true
        end
    end
    playerNum = call(player, "getPlayerNum")
    if playerNum ~= nil and getSpecificPlayer then
        localPlayer = getSpecificPlayer(playerNum)
        return localPlayer == player
    end
    return getPlayer and getPlayer() == player or false
end

local function playerKey(player)
    local onlineID
    local username
    if not isPlayer(player) then
        return nil
    end
    onlineID = tonumber(call(player, "getOnlineID"))
    if onlineID and onlineID >= 0 then
        return "online:" .. tostring(onlineID)
    end
    username = tostring(call(player, "getUsername") or "")
    if username ~= "" then
        return "user:" .. username
    end
    return tostring(player)
end

local function zombieOnlineID(zombie)
    local onlineID = tonumber(call(zombie, "getOnlineID"))
    if onlineID and onlineID >= 0 then
        return onlineID
    end
    return nil
end

local function threatIDFor(zombie)
    local onlineID
    if not zombie then
        return nil
    end
    onlineID = zombieOnlineID(zombie)
    if onlineID ~= nil then
        return tostring(onlineID)
    end
    return "local:" .. tostring(zombie)
end

local function findZombieByOnlineID(onlineID)
    local id
    local consumer
    local customFinder
    local ok
    local found
    local cell
    local zombies
    local i
    local zombie
    onlineID = tonumber(onlineID)
    if onlineID == nil then
        return nil
    end
    for id, consumer in pairs(Detector.Consumers) do
        customFinder = consumer and consumer.findZombieByOnlineID
        if type(customFinder) == "function" then
            ok, found = pcall(customFinder, onlineID)
            if ok and found then
                return found
            end
        end
    end
    if not getCell then
        return nil
    end
    cell = getCell()
    if not cell or not cell.getZombieList then
        return nil
    end
    zombies = cell:getZombieList()
    if not zombies then
        return nil
    end
    for i = zombies:size() - 1, 0, -1 do
        zombie = zombies:get(i)
        if zombieOnlineID(zombie) == onlineID then
            return zombie
        end
    end
    return nil
end

local function characterFields(prefix, character)
    local fields = {
        prefix .. "OnlineID="
            .. tostring(call(character, "getOnlineID") or "nil"),
        prefix .. "PersistentOutfitID="
            .. tostring(call(character, "getPersistentOutfitID") or "nil"),
    }
    if isPlayer(character) then
        fields[#fields + 1] = prefix .. "Username="
            .. tostring(call(character, "getUsername") or "nil")
    end
    return fields
end

local function audit(fields)
    print("[PsychopatzCore][ZombieKillDetector] " .. table.concat(fields, " "))
end

function Internal.Now()
    return nowMillis()
end

function Internal.Call(object, method, ...)
    return call(object, method, ...)
end

function Internal.IsClient()
    return runtimeIsClient()
end

function Internal.IsServer()
    return runtimeIsServer()
end

function Internal.IsPureClient()
    return isPureClient()
end

function Internal.IsAuthority()
    return isAuthority()
end

function Internal.RuntimeRole()
    return runtimeRole()
end

function Internal.IsPlayer(character)
    return isPlayer(character)
end

function Internal.IsZombie(character)
    return isZombie(character)
end

function Internal.IsLocalPlayer(player)
    return isLocalPlayer(player)
end

function Internal.PlayerKey(player)
    return playerKey(player)
end

function Internal.GetZombieOnlineID(zombie)
    return zombieOnlineID(zombie)
end

function Internal.FindZombieByOnlineID(onlineID)
    return findZombieByOnlineID(onlineID)
end

function Internal.ThreatIDFor(zombie)
    return threatIDFor(zombie)
end

function Internal.CharacterFields(prefix, character)
    return characterFields(prefix, character)
end

function Internal.Audit(fields)
    audit(fields)
end

function Internal.BuildContext(killer, zombie, source)
    return {
        source = source,
        runtime = runtimeRole(),
        threatID = threatIDFor(zombie),
        killerOnlineID = call(killer, "getOnlineID"),
        killerUsername = call(killer, "getUsername"),
        zombieOnlineID = call(zombie, "getOnlineID"),
        bodyInstanceID = call(zombie, "getPersistentOutfitID"),
        nativeZombieKills = call(killer, "getZombieKills"),
        zombieX = call(zombie, "getX"),
        zombieY = call(zombie, "getY"),
        zombieZ = call(zombie, "getZ"),
    }
end

function Internal.Prune(now)
    local key
    local timestamp
    now = tonumber(now) or nowMillis()
    for key, timestamp in pairs(Detector.ClientKillReports) do
        if now - (tonumber(timestamp) or 0) >= REPORT_TTL_MS then
            Detector.ClientKillReports[key] = nil
        end
    end
    for key, timestamp in pairs(Detector.ProcessedThreatDeaths) do
        if now - (tonumber(timestamp) or 0) >= DEATH_DEDUPE_TTL_MS then
            Detector.ProcessedThreatDeaths[key] = nil
        end
    end
end

function Internal.Notify(callbackName, killer, zombie, context)
    local id
    local consumer
    local callback
    local ok
    local result
    local reason
    local accepted = false
    local firstResult
    local firstReason
    local called = false
    for id, consumer in pairs(Detector.Consumers) do
        callback = consumer and consumer[callbackName]
        if type(callback) == "function" then
            called = true
            ok, result, reason = pcall(callback, killer, zombie, context)
            if not ok then
                audit({
                    "event=consumer_callback",
                    "callback=" .. callbackName,
                    "consumer=" .. tostring(id),
                    "result=false",
                    "reason=callback_error",
                })
            else
                if firstResult == nil and result ~= nil then
                    firstResult = result
                end
                if firstReason == nil and reason ~= nil then
                    firstReason = reason
                end
                if result == true then
                    accepted = true
                end
            end
        end
    end
    if not called and firstReason == nil then
        firstReason = "no_consumer"
    end
    return accepted, firstResult, firstReason
end

function Detector.RegisterConsumer(id, options)
    local key = tostring(id or "")
    local consumer
    local field
    if key == "" or type(options) ~= "table" then
        return false, "invalid_consumer"
    end
    consumer = Detector.Consumers[key] or {}
    for field, value in pairs(options) do
        consumer[field] = value
    end
    Detector.Consumers[key] = consumer
    if Detector.Internal.Install then
        Detector.Internal.Install()
    end
    audit({
        "event=consumer_registration",
        "consumer=" .. key,
        "runtime=" .. runtimeRole(),
        "result=true",
    })
    return true
end

function Detector.UnregisterConsumer(id)
    local key = tostring(id or "")
    if Detector.Consumers[key] == nil then
        return false
    end
    Detector.Consumers[key] = nil
    return true
end

function Detector.GetNativeZombieKills(player)
    return tonumber(call(player, "getZombieKills")) or 0
end

Detector.Internal.REPORT_TTL_MS = REPORT_TTL_MS
Detector.Internal.DEATH_DEDUPE_TTL_MS = DEATH_DEDUPE_TTL_MS

return Detector
