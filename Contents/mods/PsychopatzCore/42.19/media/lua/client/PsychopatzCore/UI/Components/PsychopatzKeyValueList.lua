require "PsychopatzCore/UI/Components/PsychopatzUIControls"

local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local DEFAULT_LABEL_COLOR = "textMuted"
local DEFAULT_VALUE_COLOR = "text"

local function resolveColor(spec, item, fallback)
    if type(spec) == "function" then
        spec = spec(item)
    end
    if type(spec) == "string" then
        return Theme.colors[spec] or fallback
    end
    if type(spec) == "table" then
        return spec
    end
    return fallback
end

local function drawKeyValueItem(list, y, entry, alternate)
    local options = list.psychopatzKeyValueOptions or {}
    local item = entry.item or {}
    local height = list.itemheight
    local width = list:getWidth()
    local labelX = tonumber(options.labelX) or 8
    local labelWidth = tonumber(options.labelWidth)
    local labelWidthRatio = tonumber(options.labelWidthRatio)
    local valueX = options.valueX

    if type(valueX) == "function" then
        valueX = valueX(list, width, item)
    end
    if valueX == nil and options.valueXMax then
        valueX = math.min(
            tonumber(options.valueXMax) or width,
            math.floor(width * (tonumber(options.valueXRatio) or 0.34))
        )
    end
    if valueX == nil then
        if labelWidth == nil then
            labelWidth = math.floor(width * (labelWidthRatio or 0.34))
        elseif labelWidthRatio then
            labelWidth = math.min(
                labelWidth,
                math.floor(width * labelWidthRatio)
            )
        end
        valueX = labelX + labelWidth + (tonumber(options.valueXOffset) or 0)
    end

    local rightPadding = tonumber(options.valueRightPadding) or 12
    local valueWidth = math.max(
        tonumber(options.valueMinimumWidth) or 30,
        width - valueX - rightPadding
    )
    local labelColor = resolveColor(
        options.labelColor or DEFAULT_LABEL_COLOR,
        item,
        Theme.colors.textMuted
    )
    local valueSpec = item.tone or options.valueColor or DEFAULT_VALUE_COLOR
    if item.warning == true then
        valueSpec = options.warningColor or valueSpec
    end
    local valueColor = resolveColor(valueSpec, item, Theme.colors.text)
    local label = tostring(item.label or "")
    local value = tostring(item.value or "")
    if options.ellipsize ~= false then
        value = Layout.Ellipsize(value, options.font or UIFont.Small, valueWidth)
    end

    if alternate then
        if options.alternateColor then
            local alternateColor = resolveColor(
                options.alternateColor,
                item,
                Theme.colors.surfaceRaised
            )
            list:drawRect(
                0,
                y,
                width,
                height,
                tonumber(options.alternateAlpha) or 0.38,
                alternateColor.r,
                alternateColor.g,
                alternateColor.b
            )
        elseif options.drawSelection ~= false then
            UI.DrawListSelection(list, y, height, false, true)
        end
    end

    local labelY = tonumber(options.labelY) or 6
    local valueY = tonumber(options.valueY) or labelY
    local font = options.font or UIFont.Small
    list:drawText(
        label,
        labelX,
        y + labelY,
        labelColor.r,
        labelColor.g,
        labelColor.b,
        labelColor.a or 1,
        font
    )
    list:drawText(
        value,
        valueX,
        y + valueY,
        valueColor.r,
        valueColor.g,
        valueColor.b,
        valueColor.a or 1,
        font
    )
    return y + height
end

function UI.CreateKeyValueList(parent, options)
    options = options or {}
    local list = UI.CreateList(parent, {
        itemHeight = options.itemHeight or Layout.Pixels(28),
        drawBorder = options.drawBorder,
        doDrawItem = drawKeyValueItem,
    })
    list.psychopatzKeyValueOptions = options
    return list
end

function UI.AddKeyValue(list, label, value, options)
    if type(options) ~= "table" then
        options = { warning = options == true }
    end
    local display = value
    if display == nil or display == "" then display = "-" end
    local item = {}
    for key, option in pairs(options) do
        item[key] = option
    end
    item.label = tostring(label or "")
    item.value = tostring(display)
    item.warning = item.warning == true
    list:addItem(item.label, item)
    return item
end

return UI
