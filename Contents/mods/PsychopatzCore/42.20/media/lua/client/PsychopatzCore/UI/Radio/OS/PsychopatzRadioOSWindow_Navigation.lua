-- Page navigation and app/contact actions for the Radio OS window.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Text = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window

function Window:setPage(page)
    page = tostring(page or "home")
    if page ~= "home" and page ~= "contacts"
        and page ~= "contact_detail" and page ~= "settings"
        and page ~= "custom"
    then
        page = "home"
    end
    self.page = page
    self._pressedControl = nil
    if page == "settings" then
        self.settingsIndex = math.max(1, tonumber(self.settingsIndex) or 1)
    end
    if page == "contacts" then
        self:ensureContacts(true)
    elseif page == "contact_detail" then
        self:updatePortrait()
    elseif page ~= "custom" and self.portraitPanel then
        self.portraitPanel:setVisible(false)
    end
end

function Window:moveSelection(delta)
    if self.page == "home" then
        local count = #OS.ListApps(self.context)
        if count > 0 then
            self.homeIndex = ((self.homeIndex - 1 + delta) % count) + 1
        end
    elseif self.page == "contacts" then
        self:ensureContacts(false)
        if #self.contacts > 0 then
            self.contactIndex = ((self.contactIndex - 1 + delta)
                % #self.contacts) + 1
        end
    elseif self.page == "settings" then
        local count = #(self:settingsActions())
        if count > 0 then
            self.settingsIndex = ((self.settingsIndex - 1 + delta)
                % count) + 1
        end
    elseif self.page == "custom" and self.activeApp
        and type(self.activeApp.onMove) == "function"
    then
        local ok, result = pcall(self.activeApp.onMove,
            self.context, self, delta, self.activeApp)
        if not ok then
            self.statusText = Text.Get(
                "UI_PsychopatzCore_Radio_AppError", "APP ERROR")
            print("[PsychopatzCore][RadioOS] app move failed: "
                .. tostring(result))
        end
    end
end

function Window:openSelectedApp()
    local apps = OS.ListApps(self.context)
    local app = apps[self.homeIndex]
    if not app then return false end
    self.activeApp = app
    if type(app.open) == "function" then
        local ok, result = pcall(app.open, self.context, self, app)
        if not ok or result == false then
            self.statusText = Text.Get(
                "UI_PsychopatzCore_Radio_AppUnavailable", "APP UNAVAILABLE")
            if not ok then
                print("[PsychopatzCore][RadioOS] app open failed: "
                    .. tostring(result))
            end
            return false
        end
        if type(result) == "string" then
            self:setPage(result)
        elseif app.page then
            self:setPage(app.page)
        end
        return true
    end
    if app.page then
        self:setPage(app.page)
        return true
    end
    self.statusText = Text.Get(
        "UI_PsychopatzCore_Radio_AppUnavailable", "APP UNAVAILABLE")
    return false
end

function Window:invokeSelectedContact()
    local entry = self.selectedContact
    local action = entry and entry.actions and entry.actions[1] or nil
    if not entry or not action then
        self.statusText = Text.Get(
            "UI_PsychopatzCore_Radio_ActionUnavailable", "ACTION UNAVAILABLE")
        return false
    end
    local ok, reason = OS.InvokeContact(entry.providerID, self.context,
        entry.id, action.id, entry)
    self.statusText = ok
        and Text.Get("UI_PsychopatzCore_Radio_RequestSent", "REQUEST SENT")
        or Text.Format("UI_PsychopatzCore_Radio_Denied", "DENIED: %s",
            tostring(reason))
    return ok
end

function Window:activateSettingsAction(action)
    local id = type(action) == "table" and action.id or action
    local changed
    if id == "zoom_in" then
        changed = self:zoomBy(1)
    elseif id == "zoom_out" then
        changed = self:zoomBy(-1)
    elseif id == "reset" then
        changed = self:resetScale()
    elseif id == "fit" then
        changed = self:fitToScreen()
    else
        return false
    end
    self:saveGeometry(true)
    self.statusText = Text.Format("UI_PsychopatzCore_Radio_Scale",
        "SCALE %.1f", changed)
    return true
end

function Window:select()
    if self.page == "home" then return self:openSelectedApp() end
    if self.page == "contacts" then
        self:ensureContacts(false)
        self.selectedContact = self.contacts[self.contactIndex]
        self:setPage(self.selectedContact and "contact_detail" or "contacts")
        return self.selectedContact ~= nil
    end
    if self.page == "contact_detail" then return self:invokeSelectedContact() end
    if self.page == "settings" then
        local actions = self:settingsActions()
        local action = actions[self.settingsIndex or 1]
        return self:activateSettingsAction(action)
    end
    if self.page == "custom" and self.activeApp
        and type(self.activeApp.onSelect) == "function"
    then
        local ok, result = pcall(self.activeApp.onSelect,
            self.context, self, self.activeApp)
        if not ok then
            self.statusText = Text.Get(
                "UI_PsychopatzCore_Radio_AppError", "APP ERROR")
            print("[PsychopatzCore][RadioOS] app select failed: "
                .. tostring(result))
            return false
        end
        return result ~= false
    end
    return false
end

function Window:back()
    if self.page == "home" then
        self:close()
    elseif self.page == "contact_detail" then
        self:setPage("contacts")
    elseif self.page == "custom" and self.activeApp
        and type(self.activeApp.onBack) == "function"
    then
        local ok, result = pcall(self.activeApp.onBack,
            self.context, self, self.activeApp)
        if not ok then
            self.statusText = Text.Get(
                "UI_PsychopatzCore_Radio_AppError", "APP ERROR")
            print("[PsychopatzCore][RadioOS] app back failed: "
                .. tostring(result))
            self:setPage("home")
        elseif result ~= true then
            self:setPage("home")
        end
    else
        self:setPage("home")
    end
end

function Window:togglePower()
    local data = self.context and self.context.deviceData
    if not data or type(data.setIsTurnedOn) ~= "function"
        or type(data.getIsTurnedOn) ~= "function"
    then
        self.statusText = Text.Get(
            "UI_PsychopatzCore_Radio_ActionUnavailable", "POWER UNAVAILABLE")
        return false
    end
    local ok, current = pcall(data.getIsTurnedOn, data)
    if not ok then return false end
    local target = current ~= true
    ok = pcall(data.setIsTurnedOn, data, target)
    if not ok then return false end
    local changed, actual = pcall(data.getIsTurnedOn, data)
    if not changed or actual ~= target then
        self.statusText = Text.Get(
            "UI_PsychopatzCore_Radio_ActionUnavailable", "POWER UNAVAILABLE")
        return false
    end
    self.context.powered = actual == true
    self.context.active = PsychopatzCore.RadioDeviceState
        and PsychopatzCore.RadioDeviceState.IsActive(data) == true
        or false
    self.context.audible = PsychopatzCore.RadioDeviceState
        and PsychopatzCore.RadioDeviceState.IsAudible(data) == true
        or false
    self.statusText = nil
    return true
end

function Window:activateControl(name)
    name = tostring(name or "")
    if name == "power" then return self:togglePower() end
    if not (self.context and self.context.powered)
        and name ~= "back" and name ~= "home"
    then
        return true
    end
    if name == "left" then
        if self.page == "home" or self.page == "contacts" then
            self:moveSelection(-1)
        elseif self.page == "custom" and self.activeApp
            and type(self.activeApp.onMove) == "function"
        then
            self:moveSelection(-1)
        else
            self:back()
        end
    elseif name == "right" then
        if self.page == "home" or self.page == "contacts" then
            self:moveSelection(1)
        elseif self.page == "settings" then
            self:moveSelection(1)
        elseif self.page == "custom" and self.activeApp
            and type(self.activeApp.onMove) == "function"
        then
            self:moveSelection(1)
        else
            self:select()
        end
    elseif name == "up" then
        self:moveSelection(-1)
    elseif name == "down" then
        self:moveSelection(1)
    elseif name == "home" then
        self:setPage("home")
    elseif name == "ok" or name == "center" or name == "select" then
        self:select()
    end
    return true
end

function Window:pressControl(name)
    name = tostring(name or "")
    self._pressedControl = name
    if name == "ptt" then self._pttHeld = true end
    return true
end

function Window:releaseControl(name)
    name = tostring(name or self._pressedControl or "")
    if self._pressedControl ~= name then return false end
    if name == "ptt" then self._pttHeld = false end
    self._pressedControl = nil
    return self:activateControl(name)
end

function Window:triggerControl(name)
    self:pressControl(name)
    return self:releaseControl(name)
end

return Window
