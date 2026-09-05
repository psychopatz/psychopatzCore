require "ISUI/ISLabel"
require "PsychopatzCore/UI/PsychopatzUI"
local InGameSettings = require "PsychopatzCore/UI/PsychopatzSettingsWindow"
local DebugSettings = require "PsychopatzCore/Debug/PsychopatzDebugSettings"

PsychopatzCore.DebugSettingsWindow = PsychopatzCore.DebugSettingsWindow or {}

local Controller = PsychopatzCore.DebugSettingsWindow
local Debug = PsychopatzCore.Debug
local SETTINGS_ID = "PsychopatzCore.DebugSettings"

local function currentPlayer()
    return getPlayer and getPlayer() or nil
end

local function canSendServerSetting()
    return isClient and isClient()
        and (not isServer or not isServer())
        and sendClientCommand ~= nil
end

local function sendConfiguredToServer(apply)
    if not canSendServerSetting() then return end
    local player = currentPlayer()
    if not player then return end
    for _, definition in ipairs(DebugSettings.GetDefinitions()) do
        sendClientCommand(player, PsychopatzCore.COMMAND_MODULE,
            DebugSettings.COMMAND, {
                id = definition.id,
                enabled = DebugSettings.GetConfigured(definition.id) == true,
            })
    end
    if apply then
        sendClientCommand(player, PsychopatzCore.COMMAND_MODULE,
            DebugSettings.APPLY_COMMAND, {})
    end
end

local function refreshControls(window)
    for _, row in ipairs(window and window.rows or {}) do
        if row.kind == "boolean" and row.definition.settingID then
            row.control:setSelected(1,
                DebugSettings.GetConfigured(row.definition.settingID) == true)
        end
    end
end

local function statusText()
    local status = DebugSettings.GetStatus()
    if status.pendingApply > 0 and status.pendingRestart > 0 then
        return "Pending: " .. tostring(status.pendingApply)
            .. " can apply now; " .. tostring(status.pendingRestart)
            .. " require restart."
    end
    if status.pendingApply > 0 then
        return "Pending: " .. tostring(status.pendingApply)
            .. " runtime change(s). Press Apply & Save."
    end
    if status.pendingRestart > 0 then
        return "Saved values are waiting for a restart."
    end
    return "Runtime values match the saved settings."
end

function Controller.UpdateStatus(window, message)
    local row = window and window.rows and window.rows[1]
    if row and row.label then row.label:setName(message or statusText()) end
end

local function saveSetting(definition, enabled)
    local ok, value = DebugSettings.Set(definition.id, enabled == true, false)
    if not ok and print then
        print("[PsychopatzCore.DebugSettings] stage_failed setting="
            .. tostring(definition.id) .. " reason=" .. tostring(value))
    end
    return ok
end

local function createNotice(_, panel)
    local label = ISLabel:new(0, 0, 20, statusText(),
        1, 1, 1, 1, UIFont.Small, true)
    label:initialise()
    label:instantiate()
    panel:addChild(label)
    return { kind = "custom", label = label, height = 42 }
end

local function saveForRestart(window)
    local ok, reason = DebugSettings.Save()
    if not ok then
        Controller.UpdateStatus(window, "Save failed: " .. tostring(reason))
        return
    end
    sendConfiguredToServer(false)
    Controller.UpdateStatus(window,
        "Saved. Runtime unchanged; restart to apply non-live settings.")
end

local function applyAndSave(window)
    local saved, reason = DebugSettings.Save()
    if not saved then
        Controller.UpdateStatus(window, "Save failed: " .. tostring(reason))
        return
    end
    local applied, report = DebugSettings.ApplyConfigured()
    sendConfiguredToServer(true)
    if not applied then
        local failure = report and report.failed and report.failed[1]
        Controller.UpdateStatus(window, "Apply failed: "
            .. tostring(failure and failure.reason or "unknown"))
        return
    end
    local pending = report and report.pendingRestart
        and #report.pendingRestart or 0
    if pending > 0 then
        Controller.UpdateStatus(window, "Applied live settings; "
            .. tostring(pending) .. " setting(s) require restart.")
    else
        Controller.UpdateStatus(window, "Applied and saved runtime settings.")
    end
end

local function reloadFileAndApply(window)
    local reloaded, reason = DebugSettings.Reload()
    if not reloaded then
        Controller.UpdateStatus(window, "Reload failed: " .. tostring(reason))
        return
    end
    refreshControls(window)
    local applied, report = DebugSettings.ApplyConfigured()
    sendConfiguredToServer(true)
    if not applied then
        local failure = report and report.failed and report.failed[1]
        Controller.UpdateStatus(window, "Apply failed: "
            .. tostring(failure and failure.reason or "unknown"))
        return
    end
    local source = reason == "file_not_found" and "defaults" or "file"
    local pending = report and report.pendingRestart
        and #report.pendingRestart or 0
    Controller.UpdateStatus(window, "Reloaded " .. source .. " and applied "
        .. tostring(#(report.applied or {})) .. " runtime setting(s)."
        .. (pending > 0 and " Restart required for " .. tostring(pending)
            .. "." or ""))
end

local function buildDefinition()
    local controls = {
        {
            type = "custom",
            id = "status",
            create = createNotice,
            layout = function(_, row, rect)
                row.label:setX(rect.x)
                row.label:setY(rect.y + 8)
                row.label:setWidth(rect.width)
            end,
        },
    }

    local definitions = DebugSettings.GetDefinitions()
    for _, definition in ipairs(definitions) do
        local registered = definition
        local mode = registered.runtimeMutable and "live" or "restart"
        local label = "[" .. tostring(registered.source) .. "] "
            .. tostring(registered.title) .. " (" .. mode .. ")"
        if registered.description ~= "" then
            label = label .. " - " .. registered.description
        end
        controls[#controls + 1] = {
            type = "boolean",
            id = "setting:" .. tostring(registered.id),
            settingID = registered.id,
            label = label,
            default = registered.defaultEnabled == true,
            get = function()
                return DebugSettings.GetConfigured(registered.id) == true
            end,
            set = function(value)
                return saveSetting(registered, value)
            end,
            onChange = function(_, window)
                Controller.UpdateStatus(window)
            end,
        }
    end

    controls[#controls + 1] = {
        type = "action",
        id = "save_for_restart",
        label = "Save for Restart",
        variant = "quiet",
        action = saveForRestart,
    }
    controls[#controls + 1] = {
        type = "action",
        id = "apply_and_save",
        label = "Apply & Save",
        variant = "success",
        action = applyAndSave,
    }
    controls[#controls + 1] = {
        type = "action",
        id = "reload_file_apply",
        label = "Reload File & Apply",
        variant = "primary",
        action = reloadFileAndApply,
    }

    local height = math.min(760, math.max(320, 240 + #definitions * 30))
    return {
        id = SETTINGS_ID,
        title = "Debug Settings",
        controls = controls,
        window = {
            persistenceNamespace = "Debug",
            persistenceKey = "DebugSettings",
            responsiveSpec = {
                width = 620, height = height,
                minWidth = 460, minHeight = 280,
                maxWidth = 900, maxHeight = 760,
            },
        },
    }
end

function Controller.Open()
    local player = currentPlayer()
    if not Debug or type(Debug.CanUse) ~= "function"
        or not Debug.CanUse(player)
    then
        return nil
    end

    -- Rebuild on open so mods registered after client initialization also
    -- appear without keeping a costly per-frame registry/UI refresh alive.
    local existing = InGameSettings.instances[SETTINGS_ID]
    if existing then
        existing:close()
        existing:removeFromUIManager()
        InGameSettings.instances[SETTINGS_ID] = nil
    end
    InGameSettings.Register(buildDefinition())
    local window = InGameSettings.Open(SETTINGS_ID)
    Controller.UpdateStatus(window)
    return window
end

function Controller.Close()
    local window = InGameSettings.instances[SETTINGS_ID]
    if window then window:close() end
end

return Controller
