--[[
    PsychopatzCore: ISEntityUI nil-sprite guard (Build 42.22+)

    Vanilla ``client/Entity/ISEntityUI.lua`` line 342 evaluates:

        if requiresPower[_entity:getSprite():getName()] then

    without nil-checking ``_entity:getSprite()``.  When the player right-clicks
    a tile containing an ``IsoFire`` (which renders via attached animation
    sprites and intentionally keeps ``sprite == null``, including lit campfires
    and world fires), ``ISContextEntity.createMenu`` passes that ``IsoFire`` to
    ``ISEntityUI.CanOpenWindowFor`` and crashes with:

        attempted index: getName of non-table: null

    This guard returns ``false`` before vanilla dereferences a nil sprite and
    delegates all other entities directly to vanilla ``CanOpenWindowFor``.
]]

pcall(require, "Entity/ISEntityUI")

PsychopatzCore = PsychopatzCore or {}

local Guard = PsychopatzCore.EntityUISpriteGuard or {}
PsychopatzCore.EntityUISpriteGuard = Guard

local function hasNilSprite(entity)
    if entity == nil then return true end
    local getter = entity.getSprite
    if type(getter) ~= "function" then return false end
    local ok, sprite = pcall(getter, entity)
    return (not ok) or sprite == nil
end

function Guard.Install()
    if type(ISEntityUI) ~= "table"
        or type(ISEntityUI.CanOpenWindowFor) ~= "function"
    then
        return false
    end
    if ISEntityUI._psychopatzSpriteGuardInstalled then
        Guard.installed = true
        return true
    end
    local vanillaCanOpenWindowFor = ISEntityUI.CanOpenWindowFor
    ISEntityUI._psychopatzSpriteGuardInstalled = true
    ISEntityUI.CanOpenWindowFor = function(player, entity)
        if hasNilSprite(entity) then
            return false
        end
        return vanillaCanOpenWindowFor(player, entity)
    end
    Guard.installed = true
    return true
end

local function retryInstall()
    if not Guard.Install() then return end
    if Events then
        if Events.OnGameStart and type(Events.OnGameStart.Remove) == "function" then
            Events.OnGameStart.Remove(retryInstall)
        end
        if Events.OnTick and type(Events.OnTick.Remove) == "function" then
            Events.OnTick.Remove(retryInstall)
        end
    end
end

if not Guard.Install() and Events then
    if Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
        Events.OnGameStart.Add(retryInstall)
    end
    if Events.OnTick and type(Events.OnTick.Add) == "function" then
        Events.OnTick.Add(retryInstall)
    end
end

return Guard
