-- Direct LCD hit-testing and app action dispatch for the Radio OS window.
-- Physical softkeys and keyboard/joypad navigation remain in Navigation/Input;
-- this module only maps visible screen rows to the same commands.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Text = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"
local Window = OS.Window

function Window:hitScreenAction(x, y)
    if self.page == "home" and self.homeRowAt then
        return self:homeRowAt(x, y)
    elseif self.page == "contacts" and self.contactRowAt then
        return self:contactRowAt(x, y)
    elseif self.page == "contact_detail" and self.contactDetailActionAt then
        return self:contactDetailActionAt(x, y)
    elseif self.page == "custom" and self.activeApp
        and type(self.activeApp.hitTest) == "function"
    then
        local ok, result = pcall(self.activeApp.hitTest,
            self.context, self, x, y, self:screenRect(), self.activeApp)
        if not ok then
            self.statusText = Text.Get(
                "UI_PsychopatzCore_Radio_AppError", "APP ERROR")
            print("[PsychopatzCore][RadioOS] app hit-test failed: "
                .. tostring(result))
            return nil
        end
        if result then return { kind = "custom", value = result } end
    end
    return nil
end

function Window:activateScreenAction(action)
    if type(action) ~= "table" then return false end
    if action.kind == "home" then
        self.homeIndex = tonumber(action.index) or self.homeIndex
        return self:openSelectedApp()
    elseif action.kind == "contact" then
        self.contactIndex = tonumber(action.index) or self.contactIndex
        self:ensureContacts(false)
        self.selectedContact = self.contacts[self.contactIndex]
        self:setPage(self.selectedContact and "contact_detail" or "contacts")
        return self.selectedContact ~= nil
    elseif action.kind == "contact_action" then
        return self:invokeSelectedContact()
    elseif action.kind == "custom" and self.activeApp then
        local value = action.value
        if type(self.activeApp.onScreenClick) == "function" then
            local ok, result = pcall(self.activeApp.onScreenClick,
                self.context, self, value, self.activeApp)
            if not ok then
                self.statusText = Text.Get(
                    "UI_PsychopatzCore_Radio_AppError", "APP ERROR")
                print("[PsychopatzCore][RadioOS] app screen click failed: "
                    .. tostring(result))
                return false
            end
            return result ~= false
        end
        return self:select()
    end
    return false
end

return Window
