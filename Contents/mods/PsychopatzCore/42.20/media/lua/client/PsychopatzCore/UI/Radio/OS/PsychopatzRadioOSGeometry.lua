-- Player-local geometry persistence and screen bounds for the Radio OS.
--
-- The radio remains a frameless ISPanel, so it cannot inherit the generic
-- title-bar window persistence directly.  This module reuses the Core UI
-- settings store while keeping the radio's position and uniform scale keyed
-- by local player number (important for split-screen and MP clients).

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local Geometry = PsychopatzCore.RadioOS.Geometry or {}
PsychopatzCore.RadioOS.Geometry = Geometry

local store

local function settingsStore()
    if store then return store end
    local settings = PsychopatzCore.Settings
    if not settings or type(settings.Open) ~= "function" then
        pcall(require, "PsychopatzCore/Settings/PsychopatzSettings")
        settings = PsychopatzCore.Settings
    end
    if not settings or type(settings.Open) ~= "function" then
        return nil
    end
    local ok, result = pcall(settings.Open, "UI", {
        fileName = "PsychopatzCore_UI.txt",
        defaults = {},
    })
    if not ok or type(result) ~= "table" then return nil end
    store = result
    if not store.loaded and type(store.Load) == "function" then
        pcall(store.Load, store)
    end
    return store
end

local function playerKey(playerNum)
    return "PsychopatzCore.RadioOS.Player." .. tostring(tonumber(playerNum) or 0)
end

local function scaleKey(playerNum)
    return playerKey(playerNum) .. ".Scale"
end

local function screenSize()
    local width, height = 1280, 900
    if getCore then
        local core = getCore()
        if core then
            if core.getScreenWidth then
                width = tonumber(core:getScreenWidth()) or width
            end
            if core.getScreenHeight then
                height = tonumber(core:getScreenHeight()) or height
            end
        end
    end
    return math.max(1, width), math.max(1, height)
end

local function clamp(value, minimum, maximum)
    minimum = tonumber(minimum) or 0
    maximum = tonumber(maximum) or minimum
    if maximum < minimum then maximum = minimum end
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

function Geometry.GetScreenSize()
    return screenSize()
end

function Geometry.ClampScale(value, minimum, maximum)
    return clamp(value, minimum or 0.75, maximum or 2.25)
end

function Geometry.ClampPosition(x, y, width, height)
    local screenWidth, screenHeight = screenSize()
    local maxX = math.max(0, screenWidth - math.max(1, tonumber(width) or 1))
    local maxY = math.max(0, screenHeight - math.max(1, tonumber(height) or 1))
    return math.floor(clamp(x, 0, maxX) + 0.5),
        math.floor(clamp(y, 0, maxY) + 0.5)
end

function Geometry.Load(playerNum)
    local activeStore = settingsStore()
    if not activeStore then return nil, nil end
    local state
    if type(activeStore.GetWindowState) == "function" then
        state = activeStore:GetWindowState(playerKey(playerNum))
    end
    local savedScale
    if type(activeStore.Get) == "function" then
        savedScale = tonumber(activeStore:Get(scaleKey(playerNum), nil))
    end
    if not savedScale and state and tonumber(state.w) then
        savedScale = tonumber(state.w) / 256
    end
    return state, savedScale
end

function Geometry.Save(playerNum, state)
    local activeStore = settingsStore()
    if not activeStore or type(state) ~= "table" then return false end
    if type(activeStore.SetWindowState) ~= "function" then return false end
    local ok = activeStore:SetWindowState(playerKey(playerNum),
        state.x, state.y, state.w, state.h, false)
    if ok == false then return false end
    if type(activeStore.Set) == "function" then
        activeStore:Set(scaleKey(playerNum), tonumber(state.scale) or 1, false)
    end
    if type(activeStore.Save) == "function" then
        return activeStore:Save()
    end
    return true
end

function Geometry.Clear(playerNum)
    local activeStore = settingsStore()
    if not activeStore then return false end
    if type(activeStore.ClearWindowState) == "function" then
        activeStore:ClearWindowState(playerKey(playerNum), false)
    end
    if type(activeStore.Set) == "function" then
        activeStore:Set(scaleKey(playerNum), nil, false)
    end
    if type(activeStore.Save) == "function" then
        return activeStore:Save()
    end
    return true
end

return Geometry
