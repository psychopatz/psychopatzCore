-- Shared layout lifecycle for Core windows and injected UI modules.
--
-- A layout callback should only place controls. State-changing callbacks call
-- window:invalidateLayout(reason); the host performs the layout on the next
-- responsive pass and can optionally validate tracked child bounds.

require "PsychopatzCore/UI/Core/PsychopatzUILayout"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local LayoutHost = UI.LayoutHost or {}
UI.LayoutHost = LayoutHost

local function ensure(window)
    if not window then return nil end
    local host = window.psychopatzLayoutHost
    if not host then
        host = {
            dirty = true,
            revision = 0,
            tracked = {},
        }
        window.psychopatzLayoutHost = host
    end
    host.tracked = host.tracked or {}
    return host
end

local function geometry(window)
    local width = window.getWidth and window:getWidth() or window.width or 0
    local height = window.getHeight and window:getHeight() or window.height or 0
    local scale = tonumber(window.uiScale) or Layout.Scale()
    return width, height, scale
end

function LayoutHost.Install(window, options)
    local host = ensure(window)
    if not host then return nil end
    options = options or {}
    if options.onLayout ~= nil then host.onLayout = options.onLayout end
    if options.debug ~= nil then host.debug = options.debug == true end
    if options.strict ~= nil then host.strict = options.strict == true end
    return host
end

function LayoutHost.Get(window)
    return window and window.psychopatzLayoutHost or nil
end

function LayoutHost.Invalidate(window, reason)
    local host = ensure(window)
    if not host then return false end
    host.dirty = true
    host.revision = (tonumber(host.revision) or 0) + 1
    host.reason = tostring(reason or "changed")
    return host.revision
end

function LayoutHost.IsDirty(window)
    local host = ensure(window)
    return host and host.dirty == true or false
end

local function report(window, message, strict)
    local text = "[PsychopatzCore][Layout] " .. tostring(message)
    if strict then error(text) end
    print(text)
end

function LayoutHost.Track(window, id, element, options)
    local host = ensure(window)
    if not host or not element then return false end
    local key = tostring(id or "tracked")
    options = options or {}
    for _, item in ipairs(host.tracked) do
        if item.id == key then
            item.element = element
            item.allowOverflow = options.allowOverflow == true
            return true
        end
    end
    host.tracked[#host.tracked + 1] = {
        id = key,
        element = element,
        allowOverflow = options.allowOverflow == true,
    }
    return true
end

function LayoutHost.Validate(window)
    local host = ensure(window)
    if not host or host.debug ~= true then return true end
    local windowWidth, windowHeight = geometry(window)
    local valid = true
    for _, item in ipairs(host.tracked) do
        local element = item.element
        local visible = true
        if type(element.getIsVisible) == "function" then
            visible = element:getIsVisible() == true
        end
        if visible and not item.allowOverflow then
            local x = type(element.getX) == "function" and element:getX()
                or element.x or 0
            local y = type(element.getY) == "function" and element:getY()
                or element.y or 0
            local width = type(element.getWidth) == "function"
                and element:getWidth()
                or element.width or 0
            local height = type(element.getHeight) == "function"
                and element:getHeight()
                or element.height or 0
            if x < 0 or y < 0 or x + width > windowWidth
                or y + height > windowHeight
            then
                valid = false
                report(window, tostring(item.id) .. " is outside window bounds"
                    .. " x=" .. tostring(x) .. " y=" .. tostring(y)
                    .. " w=" .. tostring(width) .. " h=" .. tostring(height),
                    host.strict == true)
            end
        end
    end
    return valid
end

function LayoutHost.Perform(window, force)
    local host = ensure(window)
    if not host then return false end
    local width, height, scale = geometry(window)
    local unchanged = host.lastWidth == width and host.lastHeight == height
        and host.lastScale == scale
    if force ~= true and not host.dirty and unchanged then return false end

    local callback = host.onLayout or window.onResponsiveLayout
    local revision = host.revision
    if type(callback) == "function" then callback(window) end
    LayoutHost.Validate(window)

    -- Commit only after the callback and optional validation complete. If a
    -- layout callback fails, the host remains dirty so the failure is visible
    -- and the next responsive pass cannot silently freeze stale geometry. If
    -- the callback invalidated itself, preserve that newer invalidation.
    host.lastWidth, host.lastHeight, host.lastScale = width, height, scale
    host.lastReason = host.reason
    if host.revision == revision then
        host.dirty = false
        host.reason = nil
    end
    return true
end

return LayoutHost
