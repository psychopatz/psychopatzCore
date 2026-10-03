local Core = PsychopatzCore
local UI = Core.UI
local Layout = UI.Layout
local Translation = Core.Translation

local GeometryStore = Core.Settings.Open("UI", {
    fileName = "PsychopatzCore_UI.txt",
    defaults = {},
})

local Geometry = {}

function Geometry.CoreText(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

function Geometry.CopySpec(options, width, height)
    local source = options.responsiveSpec or {}
    local spec = {}
    for key, value in pairs(source) do spec[key] = value end
    spec.width = spec.width or width
    spec.height = spec.height or height
    spec.minWidth = spec.minWidth or math.min(width, 520)
    spec.minHeight = spec.minHeight or math.min(height, 360)
    if options.anchor ~= nil then spec.anchor = options.anchor end
    if options.offsetX ~= nil then spec.offsetX = options.offsetX end
    if options.offsetY ~= nil then spec.offsetY = options.offsetY end
    return spec
end

function Geometry.Signature(window)
    -- ISUIElement geometry getters instantiate the control when javaObject is
    -- absent. A base constructor must not instantiate a derived window before
    -- the derived constructor has initialized its own fields.
    if window.javaObject == nil then
        return table.concat({
            math.floor(tonumber(window.x) or 0),
            math.floor(tonumber(window.y) or 0),
            math.floor(tonumber(window.width) or 0),
            math.floor(tonumber(window.height) or 0),
            tostring(window.pin == true),
            tostring(window.isCollapsed == true),
        }, ":")
    end
    return table.concat({
        math.floor(tonumber(window:getX()) or 0),
        math.floor(tonumber(window:getY()) or 0),
        math.floor(tonumber(window:getWidth()) or 0),
        math.floor(tonumber(window:getHeight()) or 0),
        tostring(window.pin == true),
        tostring(window.isCollapsed == true),
    }, ":")
end

function Geometry.NowMillis()
    return getTimeInMillis and getTimeInMillis() or 0
end

function Geometry.Trace(window, event)
    if not window or window.geometryTrace ~= true then return end
    local hub = UI.CommandHub
    if not hub or type(hub.Trace) ~= "function" then return end
    hub.Trace("window_geometry_" .. tostring(event),
        "key=" .. tostring(window.persistenceKey)
        .. " x=" .. tostring(window:getX())
        .. " y=" .. tostring(window:getY())
        .. " w=" .. tostring(window:getWidth())
        .. " h=" .. tostring(window:getHeight()))
end

Geometry.DefaultAdapter = {
    load = function(key)
        if not GeometryStore.loaded then GeometryStore:Load() end
        return GeometryStore:GetWindowState(key)
    end,
    save = function(key, state)
        return GeometryStore:SetWindowState(key, state.x, state.y, state.w, state.h, true, {
            pin = state.pin,
            collapsed = state.collapsed,
            widgetDetached = state.widgetDetached,
        })
    end,
    clear = function(key)
        return GeometryStore:ClearWindowState(key, true)
    end,
}

return Geometry
