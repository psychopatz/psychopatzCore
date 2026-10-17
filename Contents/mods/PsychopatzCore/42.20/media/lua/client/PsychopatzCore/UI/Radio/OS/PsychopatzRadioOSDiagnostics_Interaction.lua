-- Bounded Radio OS geometry and pointer evidence.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Diagnostics = OS.Diagnostics

local function number(value, fallback)
    return tonumber(value) or fallback or 0
end

local function methodValue(target, method, field)
    if not target then return nil end
    if type(target[method]) == "function" then
        local ok, value = pcall(target[method], target)
        if ok then return value end
    end
    return field and target[field] or nil
end

local function screenSize()
    if type(getCore) ~= "function" then return 0, 0 end
    local ok, gameCore = pcall(getCore)
    if not ok or not gameCore then return 0, 0 end
    local width, height = 0, 0
    if type(gameCore.getScreenWidth) == "function" then
        local called, value = pcall(gameCore.getScreenWidth, gameCore)
        if called then width = number(value) end
    end
    if type(gameCore.getScreenHeight) == "function" then
        local called, value = pcall(gameCore.getScreenHeight, gameCore)
        if called then height = number(value) end
    end
    return width, height
end

local function tableCount(values)
    local count = 0
    for key, value in pairs(values or {}) do
        if key ~= nil and value ~= nil then count = count + 1 end
    end
    return count
end

local function activeWindowCount()
    local registry = OS._registry
    if not registry then return 0 end
    local count = 0
    for _, window in pairs(registry.windows or {}) do
        if window and window._closed ~= true then count = count + 1 end
    end
    return count
end

local function windowID(window)
    if not window then return nil end
    if not window._radioOSDiagnosticWindowID then
        Diagnostics.windowSequence = Diagnostics.windowSequence + 1
        window._radioOSDiagnosticWindowID = Diagnostics.windowSequence
    end
    return window._radioOSDiagnosticWindowID
end

local function windowSnapshot(window)
    if not window then return { window = "nil" } end

    local x = number(methodValue(window, "getX", "x"))
    local y = number(methodValue(window, "getY", "y"))
    local width = number(methodValue(window, "getWidth", "width"))
    local height = number(methodValue(window, "getHeight", "height"))
    local screenWidth, screenHeight = screenSize()
    local captureState = methodValue(window, "isCapture", "captured")
    local data = {
        windowID = windowID(window),
        fullType = window.context and window.context.fullType or nil,
        playerNum = window.playerNum,
        owner = window.owner,
        source = window.openSource,
        mode = window.presentationMode,
        state = window.presentationState,
        closed = window._closed == true,
        visible = methodValue(window, "getIsVisible", "visible") ~= false,
        layoutEditing = window._layoutEditing == true,
        x = x, y = y, width = width, height = height,
        screenWidth = screenWidth, screenHeight = screenHeight,
        dockX = window.dockX,
        bottomOffset = window.dockBottomOffset,
        visibleFraction = window.presentationVisibleFraction,
        layoutEditorGrip = type(window.layoutEditorGrip) == "function"
            and number(window:layoutEditorGrip()) or nil,
        artSurfaceClipped = false,
        lcdStencilSupported = type(window.setStencilRect) == "function",
        engineInputClipDisabled = window._radioOSEngineClipDisabled == true,
        viewportVisibleHeight = window._presentationVisibleHeight,
        engineClipHeight = window.maxDrawHeight,
        textureCount = tableCount(window._textures),
        registryWindowCount = activeWindowCount(),
        debugCompositor = window.debugCompositor == true,
        pointerDown = window._pointerDown == true,
        dragging = window._dragging == true,
        resizing = window._resizing == true,
        captured = captureState == true,
        pointerControl = window._pointerControl,
    }

    if window.hostWindow then
        data.hostWindowPresent = true
        data.hostWindowVisible = methodValue(window.hostWindow,
            "getIsVisible", "visible") ~= false
    else
        data.hostWindowPresent = false
    end

    if type(window.visibleBodyBottom) == "function" then
        local ok, value = pcall(window.visibleBodyBottom, window)
        if ok then data.visibleBodyBottom = number(value) end
    end
    if type(window.dockPosition) == "function" then
        local ok, _, dockY = pcall(window.dockPosition, window)
        if ok then data.dockY = number(dockY) end
    end
    if type(window.hiddenPositionY) == "function" then
        local ok, hiddenY = pcall(window.hiddenPositionY, window)
        if ok then data.hiddenY = number(hiddenY) end
    end
    if type(window.layoutEditorBounds) == "function" then
        local ok, maxX, maxY = pcall(window.layoutEditorBounds, window)
        if ok then
            data.layoutEditorMaxX = number(maxX)
            data.layoutEditorMaxY = number(maxY)
        end
    end
    if type(window.getMaxDrawHeight) == "function" then
        local ok, value = pcall(window.getMaxDrawHeight, window)
        if ok then data.engineClipHeight = value end
    end
    return data
end

function Diagnostics.RecordWindow(event, window, extra, options)
    if not Diagnostics.IsPresentationEnabled() then return false end
    local data = windowSnapshot(window)
    for key, value in pairs(type(extra) == "table" and extra or {}) do
        data[key] = value
    end
    options = type(options) == "table" and options or {}
    return Diagnostics.RecordPresentation(event, data, options)
end

function Diagnostics.RecordViewport(window, requestedHeight, reason)
    if not Diagnostics.IsPresentationEnabled() then return false end
    local previous = window and window._radioOSDiagnosticViewportHeight
    if previous == requestedHeight then return false end
    if window then window._radioOSDiagnosticViewportHeight = requestedHeight end
    return Diagnostics.RecordWindow("presentation.viewport", window, {
        viewportVisibleHeight = requestedHeight,
        reason = reason,
    }, { print = false })
end

-- Compatibility alias for older diagnostic callers.  It reports viewport
-- visibility only; it never enables a rendering or input clip.
Diagnostics.RecordClip = Diagnostics.RecordViewport

function Diagnostics.BeginDrag(window, x, y, branch)
    if not Diagnostics.IsPresentationEnabled() then return end
    if window then
        window._radioOSDiagnosticDrag = {
            moves = 0,
            lastSampleAt = nil,
            branch = branch,
            startX = x,
            startY = y,
        }
    end
    Diagnostics.RecordWindow("pointer.drag_start", window, {
        branch = branch,
        localX = x,
        localY = y,
    })
end

function Diagnostics.TrackDrag(window, deltaX, deltaY)
    if not Diagnostics.IsPresentationEnabled() or not window then return end
    local drag = window._radioOSDiagnosticDrag
    if not drag then return end
    drag.moves = (drag.moves or 0) + 1
    drag.lastDeltaX = deltaX
    drag.lastDeltaY = deltaY
    local current = type(getTimeInMillis) == "function"
        and tonumber(getTimeInMillis()) or nil
    local due = not drag.lastSampleAt
        or not current or current - drag.lastSampleAt >= 150
        or drag.moves % 8 == 0
    if not due then return end
    drag.lastSampleAt = current
    Diagnostics.RecordWindow("pointer.drag_sample", window, {
        moves = drag.moves,
        deltaX = deltaX,
        deltaY = deltaY,
        progress = window._dragProgress,
        distanceY = window._dragDistanceY,
    }, { print = false })
end

function Diagnostics.EndDrag(window, decision, progress)
    if not Diagnostics.IsPresentationEnabled() then return end
    Diagnostics.RecordWindow("pointer.drag_end", window, {
        decision = decision,
        progress = progress,
        threshold = 0.42,
    })
    if window then window._radioOSDiagnosticDrag = nil end
end

function Diagnostics.RecordPointer(window, event, data)
    if not Diagnostics.IsPresentationEnabled() then return false end
    return Diagnostics.RecordWindow("pointer." .. tostring(event), window, data)
end

function Diagnostics.GetSnapshot(window)
    if not Diagnostics.IsPresentationEnabled()
        and not Diagnostics.IsPerformanceEnabled()
    then
        return nil
    end
    local output = windowSnapshot(window)
    output.presentationDiagnostics = Diagnostics.IsPresentationEnabled()
    output.performanceDiagnostics = Diagnostics.IsPerformanceEnabled()
    output.eventCount = #Diagnostics.events
    if Diagnostics.IsPerformanceEnabled()
        and type(Diagnostics.GetPerformanceSnapshot) == "function"
    then
        local performance = Diagnostics.GetPerformanceSnapshot(window)
        for key, value in pairs(performance or {}) do
            output[key] = value
        end
    end
    return output
end

function Diagnostics.Dump(window)
    if not Diagnostics.IsPresentationEnabled()
        and not Diagnostics.IsPerformanceEnabled()
    then
        return nil, "disabled"
    end
    local snapshot = Diagnostics.GetSnapshot(window)
    if Diagnostics.IsPresentationEnabled() then
        Diagnostics.RecordPresentation("snapshot", snapshot)
    else
        Diagnostics.RecordPerformance("snapshot", snapshot)
    end
    return snapshot
end

return Diagnostics
