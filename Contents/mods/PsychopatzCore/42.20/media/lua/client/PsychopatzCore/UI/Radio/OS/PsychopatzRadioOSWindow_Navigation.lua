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

function Window:select()
    if self.page == "home" then return self:openSelectedApp() end
    if self.page == "contacts" then
        self:ensureContacts(false)
        self.selectedContact = self.contacts[self.contactIndex]
        self:setPage(self.selectedContact and "contact_detail" or "contacts")
        return self.selectedContact ~= nil
    end
    if self.page == "contact_detail" then return self:invokeSelectedContact() end
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
    if self.page == "settings" then
        self.statusText = Text.Get(
            "UI_PsychopatzCore_Radio_SettingsReadOnly", "SETTINGS READ ONLY")
        return true
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

function Window:pressControl(name)
    self._pressedControl = name
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
        elseif self.page == "custom" and self.activeApp
            and type(self.activeApp.onMove) == "function"
        then
            self:moveSelection(1)
        else
            self:select()
        end
    elseif name == "center" then
        self:select()
    end
    return true
end

return Window
