-- Device skins, physical radio state and window lifecycle for Radio OS.
-- This module deliberately delegates validation to RadioDeviceState.

require "PsychopatzCore/Radio/PC_RadioDeviceState"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local OS = PsychopatzCore.RadioOS
local Manifest = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioManifest"
local Geometry = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSGeometry"
local RadioDeviceState = PsychopatzCore.RadioDeviceState
local registry = OS._registry or {
    skins = {},
    skinsByFullType = {},
    windows = {},
    revision = 0,
}
OS._registry = registry

local function log(message)
    print("[PsychopatzCore][RadioOS] " .. tostring(message))
end

local function validID(value)
    return type(value) == "string" and value ~= ""
end

local function shallowDefinition(definition)
    local result = {}
    for key, value in pairs(definition) do result[key] = value end
    return result
end

local function validRect(rect)
    return type(rect) == "table"
        and tonumber(rect.x) ~= nil and tonumber(rect.y) ~= nil
        and tonumber(rect.w) ~= nil and tonumber(rect.h) ~= nil
        and tonumber(rect.w) > 0 and tonumber(rect.h) > 0
end

local function validateSkin(skin)
    if type(skin) ~= "table" or not validID(skin.id)
        or not validID(skin.fullType) or not validID(skin.sprite)
        or not validRect(skin.screen) or type(skin.baseSize) ~= "table"
        or not validRect({ x = 0, y = 0,
            w = skin.baseSize.w, h = skin.baseSize.h })
    then
        return false
    end
    if type(skin.controls) ~= "table" then return false end
    for _, name in ipairs({ "left", "center", "right" }) do
        if not validRect(skin.controls[name]) then return false end
    end
    return true
end

function OS.RegisterDeviceSkin(definition)
    if not validateSkin(definition) then
        log("ignored invalid device-skin registration")
        return false, "invalid_definition"
    end
    local skin = shallowDefinition(definition)
    registry.skins[skin.id] = skin
    registry.skinsByFullType[skin.fullType] = skin.id
    registry.revision = registry.revision + 1
    return true
end

function OS.UnregisterDeviceSkin(id)
    local skin = registry.skins[id]
    if not skin then return false end
    registry.skins[id] = nil
    if registry.skinsByFullType[skin.fullType] == id then
        registry.skinsByFullType[skin.fullType] = nil
    end
    registry.revision = registry.revision + 1
    return true
end

function OS.GetDeviceSkin(fullTypeOrSkinID)
    local value = tostring(fullTypeOrSkinID or "")
    local id = registry.skinsByFullType[value] or value
    return registry.skins[id] or Manifest.GetSkin(value)
end

local function fullTypeOf(device)
    if not device then return nil end
    if type(device.getFullType) == "function" then
        local ok, value = pcall(device.getFullType, device)
        if ok and value then return tostring(value) end
    end
    return device.fullType and tostring(device.fullType) or nil
end

function OS.GetDeviceContext(playerNum, device)
    playerNum = tonumber(playerNum) or 0
    local player = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    if not device and player and RadioDeviceState then
        device = RadioDeviceState.FindPlayerDevice(player)
    end
    if not device then return nil, "device_not_found" end
    local fullType = fullTypeOf(device)
    local skin = OS.GetDeviceSkin(fullType)
    if not skin then return nil, "unsupported_device" end
    local data = RadioDeviceState and RadioDeviceState.GetDeviceData(device)
        or device
    local active = false
    local audible = false
    local reason = "state_unavailable"
    if RadioDeviceState and data then
        local valid, validationReason = RadioDeviceState.Validate(data)
        active = valid == true
        reason = validationReason or (active and "ready" or reason)
        audible = RadioDeviceState.IsAudible(data) == true
    end
    return {
        player = player,
        playerNum = playerNum,
        device = device,
        deviceData = data,
        fullType = fullType,
        skin = skin,
        active = active,
        audible = audible,
        reason = reason,
        revision = registry.revision,
    }
end

function OS.GetDefaultScale()
    local _, height = Geometry.GetScreenSize()
    return math.max(1, math.min(1.75, height * 0.78 / 432))
end

function OS.GetOpenWindow(playerNum)
    return registry.windows[tonumber(playerNum) or 0]
end

function OS.Open(playerNum, device, options)
    playerNum = tonumber(playerNum) or 0
    options = type(options) == "table" and options or {}
    local context, reason = OS.GetDeviceContext(playerNum, device)
    if not context then return nil, reason end
    local existing = registry.windows[playerNum]
    if existing and existing.getIsVisible and existing:getIsVisible() then
        if existing.bringToTop then existing:bringToTop() end
        return existing
    end
    context.hostWindow = options.hostWindow
    local Window = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow"
    local geometryIdentity = {
        family = context.skin.family or context.fullType,
        id = context.skin.id,
        fullType = context.fullType,
    }
    local geometryKey = Geometry.MakeKey(playerNum, geometryIdentity)
    local savedState, savedScale
    if options.persistGeometry ~= false then
        savedState, savedScale = Geometry.Load(playerNum, geometryIdentity)
    end
    local scale = tonumber(options.scale) or savedScale or OS.GetDefaultScale()
    scale = Geometry.ClampScale(scale, 0.75, 2.25)
    local width = context.skin.baseSize.w * scale
    local height = context.skin.baseSize.h * scale
    local screenWidth, screenHeight = Geometry.GetScreenSize()
    local x = savedState and tonumber(savedState.x)
        or (screenWidth - width) / 2
    local y = savedState and tonumber(savedState.y)
        or (screenHeight - height) / 2
    x, y = Geometry.ClampPosition(x, y, width, height)
    local window = Window:new(
        x, y, width, height, context, {
            scale = scale,
            owner = options.owner,
            hostWindow = options.hostWindow,
            geometryKey = geometryKey,
            geometryIdentity = geometryIdentity,
            persistGeometry = options.persistGeometry,
        })
    window:initialise()
    window:instantiate()
    window:clampToScreen()
    if window.addToUIManager then window:addToUIManager() end
    window:setVisible(true)
    registry.windows[playerNum] = window
    -- Radio OS replaces the native radio surface while open.  Keeping the
    -- host object alive lets close() restore the vanilla interface without
    -- leaving two interactive radio windows stacked on one another.
    if options.hostWindow and options.hostWindow.setVisible then
        options.hostWindow:setVisible(false)
    end
    return window
end

function OS.Close(playerNum)
    playerNum = tonumber(playerNum) or 0
    local window = registry.windows[playerNum]
    registry.windows[playerNum] = nil
    if window and window.close then window:close() end
    return window ~= nil
end

function OS._ForgetWindow(window)
    if not window then return end
    local playerNum = tonumber(window.playerNum) or 0
    if registry.windows[playerNum] == window then registry.windows[playerNum] = nil end
end

if not registry.defaultsLoaded then
    for id, skin in pairs(Manifest.skins or {}) do
        if validateSkin(skin) then
            registry.skins[id] = skin
            registry.skinsByFullType[skin.fullType] = id
        end
    end
    registry.defaultsLoaded = true
end

return OS
