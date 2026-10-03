local Choices = PsychopatzConversationChoices
local Internal = Choices.Internal
local fontHeight = Internal.fontHeight

function Internal.renderChoice(part, index, contentAlpha, accent, headerHeight)
        local choice = part.choices[index]
        local layout = part.choiceLayout[index]
        local y = layout.y - (part.maximumScroll - (part.scrollOffset or 0))
        local enabled = choice.enabled ~= false
            and part.owner
            and part.owner:isConversationInteractive()
        local hovered = index == part.hoveredChoice
        local left = part.padding
        local width = part.width - part.padding * 2
    if y + layout.height >= headerHeight and y <= part.height then
        part:drawRect(
            left + 3,
            y + 3,
            width,
            layout.height,
            contentAlpha * 0.34,
            0,
            0,
            0
        )
        part:drawRect(
            left,
            y,
            width,
            layout.height,
            contentAlpha * (hovered and 0.9 or 0.63),
            enabled and accent.r * (hovered and 0.30 or 0.15) or 0.10,
            enabled and accent.g * (hovered and 0.30 or 0.15) or 0.10,
            enabled and accent.b * (hovered and 0.30 or 0.15) or 0.10
        )
        part:drawRectBorder(
            left,
            y,
            width,
            layout.height,
            contentAlpha * (enabled and (hovered and 0.95 or 0.52) or 0.22),
            enabled and accent.r or 0.40,
            enabled and accent.g or 0.40,
            enabled and accent.b or 0.40
        )
        part:drawRect(
            left,
            y,
            hovered and 5 or 2,
            layout.height,
            contentAlpha * (enabled and 0.92 or 0.24),
            accent.r,
            accent.g,
            accent.b
        )
        local badgeSize = 24
        local badgeX = left + 9
        local badgeY = y + math.floor((layout.height - badgeSize) / 2)
        part:drawRect(badgeX, badgeY, badgeSize, badgeSize,
            contentAlpha * (hovered and 0.72 or 0.30),
            accent.r * 0.30,
            accent.g * 0.30,
            accent.b * 0.30)
        part:drawRectBorder(badgeX, badgeY, badgeSize, badgeSize,
            contentAlpha * (enabled and 0.75 or 0.25),
            accent.r, accent.g, accent.b)
        part:drawTextCentre(
            tostring(index),
            badgeX + badgeSize / 2,
            badgeY + 4,
            enabled and math.min(1, accent.r + 0.28) or 0.45,
            enabled and math.min(1, accent.g + 0.28) or 0.45,
            enabled and math.min(1, accent.b + 0.28) or 0.45,
            contentAlpha,
            UIFont.Small
        )
        if hovered and enabled then
            part:drawText(
                ">",
                left + width - 18,
                y + math.floor((layout.height - fontHeight()) / 2),
                math.min(1, accent.r + 0.25),
                math.min(1, accent.g + 0.25),
                math.min(1, accent.b + 0.25),
                contentAlpha,
                UIFont.Small
            )
        end
        local lineIndex
        for lineIndex = 1, #layout.lines do
            part:drawText(
                layout.lines[lineIndex],
                left + 42,
                y + 8 + (lineIndex - 1) * fontHeight(),
                enabled and 0.92 or 0.48,
                enabled and 0.96 or 0.48,
                enabled and 0.90 or 0.48,
                contentAlpha,
                UIFont.Small
            )
        end
    end
end

function Internal.renderChoices(part, contentAlpha, accent, headerHeight)
    for index = 1, #part.choices do
        Internal.renderChoice(part, index, contentAlpha, accent, headerHeight)
    end
end

function Internal.renderScrollbar(part, contentAlpha, accent, headerHeight)
    if part.maximumScroll > 0 then
        local trackY = headerHeight + 7
        local trackH = math.max(18, part.height - trackY - 8)
        local viewportH = math.max(1, part.height - headerHeight)
        local thumbH = math.max(18, trackH * (viewportH / part.contentHeight))
        local thumbY = trackY + (trackH - thumbH)
            * (1 - ((part.scrollOffset or 0) / part.maximumScroll))
        part:drawRect(part.width - 7, trackY, 2, trackH,
            contentAlpha * 0.18, accent.r, accent.g, accent.b)
        part:drawRect(part.width - 8, thumbY, 4, thumbH,
            contentAlpha * 0.88, accent.r, accent.g, accent.b)
    end
end

return Internal
