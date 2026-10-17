-- Device skins, physical radio state and window lifecycle for Radio OS.
-- This module deliberately delegates validation to RadioDeviceState.

require "PsychopatzCore/Radio/PC_RadioDeviceState"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local OS = PsychopatzCore.RadioOS
local Manifest = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioRuntimeManifest"
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

local function diagnostics()
    return OS.Diagnostics
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
        or not validID(skin.fullType) or type(skin.canvas) ~= "table"
        or tonumber(skin.canvas.width) == nil
        or tonumber(skin.canvas.height) == nil
        or tonumber(skin.canvas.width) <= 0
        or tonumber(skin.canvas.height) <= 0
        or type(skin.chassis) ~= "table"
        or type(skin.components) ~= "table"
    then
        return false
    end
    for _, variant in ipairs({ "pristine", "worn" }) do
        local chassis = skin.chassis[variant]
        if type(chassis) ~= "table" or not validID(chassis.image) then
            return false
        end
    end
    if type(skin.lcd) ~= "table"
        or not validRect(skin.lcd.aperture)
        or not validRect(skin.lcd.content)
    then
        return false
    end
    for _, component in ipairs(skin.components) do
        if type(component) ~= "table" or not validID(component.id)
            or not validRect(component.hitbox)
            or type(component.states) ~= "table"
        then
            return false
        end
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

local function callMethod(target, method, ...)
    if not target or type(target[method]) ~= "function" then return nil end
    local ok, value = pcall(target[method], target, ...)
    return ok and value or nil
end

local function worldCustomItemFullType(device, data)
    -- IsoWaveSignal does not expose InventoryItem:getFullType(). The Java
    -- constructor creates its DeviceData from the sprite's CustomItem
    -- property, so read that same authoritative identity for placed radios.
    local parent = callMethod(data, "getParent") or device
    local sprite = callMethod(parent, "getSprite")
    local properties = callMethod(sprite, "getProperties")
    local customItem = callMethod(properties, "get", "CustomItem")
    if validID(customItem) then return tostring(customItem) end
    return nil
end

local function fullTypeOf(device)
    if not device then return nil end
    if type(device.getFullType) == "function" then
        local ok, value = pcall(device.getFullType, device)
        if ok and validID(value) then return tostring(value) end
    end
    if validID(device.fullType) then return tostring(device.fullType) end
    local data = callMethod(device, "getDeviceData")
    return worldCustomItemFullType(device, data)
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
    local powered = false
    local reason = "state_unavailable"
    if RadioDeviceState and data then
        local valid, validationReason = RadioDeviceState.Validate(data)
        active = valid == true
        reason = validationReason or (active and "ready" or reason)
        audible = RadioDeviceState.IsAudible(data) == true
        if data.getIsTurnedOn then
            local ok, value = pcall(data.getIsTurnedOn, data)
            powered = ok and value == true or false
        end
    end
    return {
        player = player,
        playerNum = playerNum,
        device = device,
        deviceData = data,
        fullType = fullType,
        skin = skin,
        supported = true,
        canOpen = data ~= nil,
        active = active,
        audible = audible,
        powered = powered,
        reason = reason,
        revision = registry.revision,
    }
end

function OS.GetDefaultScale(skin)
    local screenWidth, screenHeight = Geometry.GetScreenSize()
    local canvas = skin and skin.canvas or {}
    return Geometry.GetPreferredScale(screenWidth, screenHeight,
        canvas.width, canvas.height)
end

-- Development-only compositor probe.  It is deliberately not persisted and
-- has no normal-game UI toggle, so production gameplay stays unchanged.
function OS.SetCompositorDebug(enabled)
    OS._compositorDebug = enabled == true
    for _, window in pairs(registry.windows) do
        if window then window.debugCompositor = OS._compositorDebug end
    end
    return OS._compositorDebug
end

function OS.IsCompositorDebugEnabled()
    return OS._compositorDebug == true
end

function OS.GetOpenWindow(playerNum)
    return registry.windows[tonumber(playerNum) or 0]
end

function OS.Open(playerNum, device, options)
    playerNum = tonumber(playerNum) or 0
    options = type(options) == "table" and options or {}
    local context, reason = OS.GetDeviceContext(playerNum, device)
    if not context then return nil, reason end
    if context.canOpen ~= true then return nil, "device_data_unavailable" end
    local existing = registry.windows[playerNum]
    if existing and not existing._closed
        and existing.context
        and existing.context.fullType == context.fullType
    then
        existing.context = context
        if options.hostWindow ~= nil then
            existing.hostWindow = options.hostWindow
            existing.context.hostWindow = options.hostWindow
        else
            existing.context.hostWindow = existing.hostWindow
        end
        if options.owner ~= nil then
            existing.owner = options.owner
            existing.autoManaged = options.owner == "auto"
            existing.autoDevice = options.owner == "auto" and device or nil
        end
        if options.source ~= nil then existing.openSource = options.source end
        if options.hostWindow and options.hostWindow.setVisible then
            options.hostWindow:setVisible(false)
        end
        if options.immersive ~= false and existing.showImmersive then
            existing:showImmersive({ animate = options.animate == true })
        elseif existing.bringToTop then
            existing:bringToTop()
        end
        local activeDiagnostics = diagnostics()
        if activeDiagnostics and activeDiagnostics.RecordWindow then
            activeDiagnostics.RecordWindow("window.reuse", existing, {
                requestedOwner = options.owner,
                requestedSource = options.source,
                requestedImmersive = options.immersive ~= false,
            })
        end
        return existing
    end
    if existing then
        -- Do not leave an invisible/closed window retained by the per-player
        -- registry when the same radio is opened again.  That stale instance
        -- can keep its textures and host-window references alive indefinitely.
        if existing.close then
            existing:close()
        else
            OS._ForgetWindow(existing)
        end
    end
    context.hostWindow = options.hostWindow
    context.variant = tostring(options.variant or context.variant or "pristine")
    if context.variant ~= "worn" then context.variant = "pristine" end
    local Window = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow"
    local geometryIdentity = {
        family = context.skin.family or context.fullType,
        id = context.skin.id,
        fullType = context.fullType,
    }
    local geometryKey = Geometry.MakeKey(playerNum, geometryIdentity)
    local savedState, savedScale
    if options.persistGeometry ~= false then
        savedState, savedScale = Geometry.Load(playerNum, geometryIdentity,
            tonumber(context.skin.canvas.width))
    end
    local screenWidth, screenHeight = Geometry.GetScreenSize()
    local canvasWidth = tonumber(context.skin.canvas.width)
    local canvasHeight = tonumber(context.skin.canvas.height)
    local minimumScale, maximumScale = Geometry.GetScaleLimits(
        screenWidth, screenHeight, canvasWidth, canvasHeight)
    local scale = tonumber(options.scale) or savedScale
        or Geometry.GetPreferredScale(screenWidth, screenHeight,
            canvasWidth, canvasHeight)
    scale = Geometry.ClampScale(scale, minimumScale, maximumScale)
    -- Keep initial dimensions identical to Window:applyScale().  Persisted
    -- scale values are fractional, but ISPanel geometry is pixel-based; using
    -- raw products here changes visibleBodyBottom by a fraction on reopen and
    -- moves a saved dock position by one pixel.
    local width = math.max(1, math.floor(canvasWidth * scale + 0.5))
    local height = math.max(1, math.floor(canvasHeight * scale + 0.5))
    local dockX = tonumber(options.dockX)
        or (savedState and tonumber(savedState.dockX))
        or (savedState and savedState.x
            and Geometry.NormalizeDockX(savedState.x, width, screenWidth))
        or 0.5
    local dockBottomOffset = tonumber(options.dockBottomOffset)
        or (savedState and tonumber(savedState.dockBottomOffset))
        or 12
    local presentationVisibleFraction = tonumber(
        options.presentationVisibleFraction)
        or (savedState and tonumber(savedState.presentationVisibleFraction))
        or 0.75
    local immersive = options.immersive ~= false
    local x = savedState and tonumber(savedState.x)
        or (screenWidth - width) / 2
    local y = savedState and tonumber(savedState.y)
        or (screenHeight - height) / 2
    x, y = Geometry.ClampPosition(x, y, width, height)
    local window = Window:new(
        x, y, width, height, context, {
            scale = scale,
            variant = context.variant,
            owner = options.owner,
            source = options.source,
            autoDevice = device,
            hostWindow = options.hostWindow,
            geometryKey = geometryKey,
            geometryIdentity = geometryIdentity,
            persistGeometry = options.persistGeometry,
            minScale = minimumScale,
            maxScale = maximumScale,
            presentationMode = immersive and "immersive" or "editor",
            dockX = dockX,
            dockBottomOffset = dockBottomOffset,
            presentationVisibleFraction = presentationVisibleFraction,
            hidden = false,
            autoManaged = options.owner == "auto",
            debugCompositor = options.debugCompositor
                or OS._compositorDebug == true,
        })
    window:initialise()
    window:instantiate()
    if immersive and window.applyDockPosition then
        window:applyDockPosition()
    else
        window:clampToScreen()
    end
    if window.addToUIManager then window:addToUIManager() end
    window:setVisible(true)
    registry.windows[playerNum] = window
    if immersive and window.showImmersive then
        window:showImmersive({ animate = options.animate == true })
    end
    -- Radio OS replaces the native radio surface while open.  Keeping the
    -- host object alive lets close() restore the vanilla interface without
    -- leaving two interactive radio windows stacked on one another.
    if options.hostWindow and options.hostWindow.setVisible then
        options.hostWindow:setVisible(false)
    end
    log("window opened: fullType=" .. tostring(context.fullType)
        .. " powered=" .. tostring(context.powered)
        .. " scale=" .. tostring(scale))
    local activeDiagnostics = diagnostics()
    if activeDiagnostics and activeDiagnostics.RecordWindow then
        activeDiagnostics.RecordWindow("window.open", window, {
            requestedOwner = options.owner,
            requestedSource = options.source,
            requestedImmersive = immersive,
            requestedAnimate = options.animate == true,
        })
    end
    return window
end

function OS.Close(playerNum)
    playerNum = tonumber(playerNum) or 0
    local window = registry.windows[playerNum]
    registry.windows[playerNum] = nil
    local activeDiagnostics = diagnostics()
    if window and activeDiagnostics and activeDiagnostics.RecordWindow then
        activeDiagnostics.RecordWindow("window.close_request", window, {
            reason = "api",
        })
    end
    if window and window.close then window:close() end
    return window ~= nil
end

function OS._ForgetWindow(window)
    if not window then return end
    local playerNum = tonumber(window.playerNum) or 0
    if registry.windows[playerNum] == window then registry.windows[playerNum] = nil end
end

if not registry.defaultsLoaded then
    for _, skin in ipairs(Manifest.ListDevices and Manifest.ListDevices() or {}) do
        if validateSkin(skin) then
            registry.skins[skin.id] = skin
            registry.skinsByFullType[skin.fullType] = skin.id
        end
    end
    registry.defaultsLoaded = true
end

return OS
