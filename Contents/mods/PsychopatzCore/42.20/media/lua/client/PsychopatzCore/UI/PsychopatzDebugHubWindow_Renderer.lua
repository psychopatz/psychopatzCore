require "PsychopatzCore/UI/PsychopatzUI"

local Renderer = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Translation = PsychopatzCore.Translation

function Renderer.Translate(key, fallback)
    return Translation and Translation.GetKey
        and Translation.GetKey(key, fallback)
        or fallback or key
end

function Renderer.Format(key, fallback, args)
    return Translation and Translation.FormatKey
        and Translation.FormatKey(key, fallback, args)
        or fallback or key
end

function Renderer.IsAvailable(definition)
    local ok, available = pcall(definition.available)
    return ok and not not available
end

local function drawGroupItem(list, y, entry, alternate)
    local item = entry.item
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    local indicator = item.expanded and "[-] " or "[+] "
    local count = Renderer.Format("UI_PsychopatzDebugHub_ToolCount", "%s tools",
        { tostring(item.count or 0) })
    local countWidth = Theme.TextWidth(UIFont.Small, count)
    local sourceWidth = math.max(40, list:getWidth() - countWidth - 36)
    local source = Layout.Ellipsize(indicator .. tostring(item.source or ""),
        UIFont.Medium, sourceWidth)
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    list:drawRect(0, y, list:getWidth(), list.itemheight, 0.22,
        Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b)
    list:drawText(source, 12, y + 10,
        text.r, text.g, text.b, text.a, UIFont.Medium)
    list:drawText(count, list:getWidth() - countWidth - 12,
        y + 12, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

local function drawToolItem(list, y, entry, alternate)
    local item = entry.item
    local selected = list.selected == entry.index
    local height = list.itemheight
    UI.DrawListSelection(list, y, height, selected, alternate)
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    local statusColor = item.available and "success" or "danger"
    local status = item.available
        and Renderer.Translate("UI_PsychopatzDebugHub_Available", "Available")
        or Renderer.Translate("UI_PsychopatzDebugHub_Unavailable", "Unavailable")
    local badgeWidth = UI.DrawBadge(list, status, list:getWidth() - 12,
        y + 7, statusColor)
    local title = Layout.Ellipsize(item.title, UIFont.Medium,
        math.max(40, list:getWidth() - badgeWidth - 34))
    list:drawText(title, 12, y + 7, text.r, text.g, text.b, text.a, UIFont.Medium)
    local availableWidth = math.max(40, list:getWidth() - 30)
    local description = Layout.Ellipsize(item.description, UIFont.Small, availableWidth)
    list:drawText(description, 12, y + 31, muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + height
end

function Renderer.DrawItem(list, y, entry, alternate)
    if entry.item and entry.item.kind == "group" then
        return drawGroupItem(list, y, entry, alternate)
    end
    return drawToolItem(list, y, entry, alternate)
end

return Renderer
