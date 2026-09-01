-- Public facade for the reusable PsychopatzCore command hub.

require "PsychopatzCore/UI/PsychopatzCommandHubRegistry"
require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Actions = require "PsychopatzCore/UI/PsychopatzCommandHubActionsWindow"
local Window = require "PsychopatzCore/UI/PsychopatzCommandHubWindow"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Hub = UI.CommandHub or {}
UI.CommandHub = Hub
PsychopatzCore.CommandHub = Hub

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

Hub.Registry = UI.CommandHubRegistry
Hub.Options = UI.CommandHubOptions
Hub.Actions = Actions
Hub.Window = Window
Hub.Settings = Hub.Settings or {}
Hub.Settings.Window = require "PsychopatzCore/UI/PsychopatzCommandHubSettingsWindow"
Hub.observers = Hub.observers or {}
Hub.traceEnabled = Hub.traceEnabled ~= false

function Hub.SetTraceEnabled(enabled)
    Hub.traceEnabled = enabled == true
    return Hub.traceEnabled
end

function Hub.Trace(event, message)
    if Hub.traceEnabled == false then return false end
    print("[PsychopatzCore][CommandHub][TRACE] " .. tostring(event)
        .. (message and " | " .. tostring(message) or ""))
    return true
end

function Hub.RegisterButton(definition)
    return Hub.Registry.RegisterButton(definition)
end

Hub.Register = Hub.RegisterButton
Hub.RegisterCategory = Hub.Registry.RegisterCategory
Hub.RegisterAction = Hub.Registry.RegisterAction
Hub.UnregisterButton = Hub.Registry.UnregisterButton
Hub.UnregisterSource = Hub.Registry.UnregisterSource
Hub.Get = Hub.Registry.Get
Hub.GetChildren = Hub.Registry.GetChildren
Hub.SetOrder = Hub.Registry.SetCategoryOrder
Hub.RegisterWindow = Hub.Options.RegisterTarget
Hub.UnregisterWindow = Hub.Options.UnregisterTarget

function Hub.RegisterSettingsButton(definition)
    definition = type(definition) == "table" and definition or {}
    local button = {}
    for key, value in pairs(definition) do button[key] = value end
    button.id = button.id or "PsychopatzCore.settings"
    button.source = button.source or "PsychopatzCore"
    button.order = button.order or 900
    button.titleKey = button.titleKey
        or "UI_PsychopatzCore_CommandHub_Settings_Title"
    button.titleFallback = button.titleFallback or "Settings"
    button.onClick = button.onClick or function(_, host)
        return Hub.OpenSettings(host)
    end
    button.closeHub = false
    return Hub.RegisterButton(button)
end

function Hub.RegisterObserver(id, callback)
    local key = tostring(id or "")
    if key == "" or type(callback) ~= "function" then return false end
    Hub.observers[key] = callback
    return true
end

function Hub.UnregisterObserver(id)
    local key = tostring(id or "")
    if Hub.observers[key] == nil then return false end
    Hub.observers[key] = nil
    return true
end

function Hub.Notify(event, window)
    for _, callback in pairs(Hub.observers) do
        local ok, errorMessage = pcall(callback, event, window, Hub)
        if not ok then
            print("[PsychopatzCore][CommandHub] observer failed: "
                .. tostring(errorMessage))
        end
    end
end

function Hub.Open(options)
    options = options or {}
    Hub.Trace("open_requested", "existing=" .. tostring(Hub.instance ~= nil))
    local window = Hub.instance
    if not window then
        window = UI.NewWindow(Window, {
            title = tostring(options.title or tr(
                "UI_PsychopatzCore_CommandHub_Title", "COMMAND HUB")),
            resizable = options.resizable ~= false,
            persistenceKey = options.persistenceKey
                or "PsychopatzCore.CommandHub",
            responsiveSpec = options.responsiveSpec or {
                anchor = "top_left",
                offsetX = 18,
                offsetY = 70,
                width = 320,
                height = 230,
                minWidth = 220,
                minHeight = 150,
                maxWidth = 620,
                maxHeight = 820,
            },
        })
        window:initialise()
        window:instantiate()
        Hub.instance = window
        Hub.Options.RegisterTarget("PsychopatzCore.CommandHub.Host", window)
        Hub.Notify("opened", window)
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:syncButtons()
    window:fitToContent(false)
    Hub.Notify("shown", window)
    Hub.Trace("shown", "x=" .. tostring(window:getX())
        .. " y=" .. tostring(window:getY())
        .. " width=" .. tostring(window:getWidth())
        .. " height=" .. tostring(window:getHeight()))
    return window
end

function Hub.Close()
    Hub.Trace("close_requested", "existing=" .. tostring(Hub.instance ~= nil))
    if Hub.instance then Hub.instance:close() end
end

function Hub.OpenSettings(owner)
    local host = owner or Hub.instance
    Hub.Trace("settings_open_requested", "has_owner="
        .. tostring(owner ~= nil) .. " has_host=" .. tostring(host ~= nil))
    if not host then host = Hub.Open() end
    local window = Hub.Settings.instance
    if not window then
        window = UI.NewWindow(Hub.Settings.Window, {
            title = getText and getText(
                "UI_PsychopatzCore_CommandHub_Settings_Title")
                or "COMMAND HUB SETTINGS",
            resizable = true,
            persistenceKey = "PsychopatzCore.CommandHub.Settings",
            responsiveSpec = {
                width = 420, height = 360,
                minWidth = 360, minHeight = 330,
                maxWidth = 620, maxHeight = 560,
            },
        })
        window:initialise()
        window:instantiate()
        Hub.Settings.instance = window
    end
    window.owner = host
    Hub.Options.RegisterTarget("PsychopatzCore.CommandHub.Settings", window)
    window:populate()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    Hub.Trace("settings_shown", "x=" .. tostring(window:getX())
        .. " y=" .. tostring(window:getY())
        .. " width=" .. tostring(window:getWidth())
        .. " height=" .. tostring(window:getHeight()))
    return window
end

function Hub.Toggle(options)
    if Hub.instance and Hub.instance.getIsVisible
        and Hub.instance:getIsVisible()
    then
        Hub.Close()
        return false
    end
    return Hub.Open(options) ~= nil
end

function Hub.Sync()
    local window = Hub.instance
    if not window then return false end
    window:syncButtons()
    window:fitToContent(false)
    window:requestResponsiveLayout(true)
    if Actions.instance and Actions.instance.owner == window then
        Actions.SyncPosition(window)
    end
    return true
end

return Hub
