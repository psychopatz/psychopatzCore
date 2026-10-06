local Chat = PsychopatzConversationChat
local Internal = Chat.Internal
local Text = Internal.Text
local Typing = Internal.Typing
local traceTypingRender = Internal.traceTypingRender
local fontHeight = Internal.fontHeight
local drawFormattedLine = Internal.drawFormattedLine

function Internal.renderRow(part, layout, contentAlpha, lineH, headerHeight)
    local typingLayout
    local typingX
    local typingY
        local speaker = layout.message and layout.message.speaker or layout.speaker
        local player = speaker == "player"
        local x = player and (part.width - layout.width - 14) or 14
        local y = layout.y - (part.maximumScroll - (part.scrollOffset or 0))
        local color = player
            and { r = 0.055, g = 0.235, b = 0.19 }
            or { r = 0.125, g = 0.145, b = 0.135 }
        local accent = player
            and { r = 0.25, g = 0.92, b = 0.70 }
            or part:getAccentColor()
    if y + layout.height >= headerHeight and y <= part.height then
            if not layout.typing then
                part:drawRect(x + 3, y + 4, layout.width, layout.height,
                    contentAlpha * 0.38, 0, 0, 0)
                part:drawRect(x, y, layout.width, layout.height, contentAlpha * 0.92,
                    color.r, color.g, color.b)
                part:drawRectBorder(
                    x,
                    y,
                    layout.width,
                    layout.height,
                    contentAlpha * 0.44,
                    accent.r,
                    accent.g,
                    accent.b
                )
                local tailX = player and x + layout.width - 8 or x - 5
                part:drawRect(tailX, y + layout.height - 10, 8, 6,
                    contentAlpha * 0.9, color.r, color.g, color.b)
                local railX = player and x + layout.width - 3 or x
                part:drawRect(railX, y, 3, layout.height, contentAlpha * 0.92,
                    accent.r, accent.g, accent.b)
            end
            if layout.typing then
                typingLayout = layout
                typingX = x
                typingY = y
            end
            local npcName = part.owner
                and part.owner.spec
                and part.owner.spec.context
                and part.owner.spec.context.npcName
                or Text.Resolve({
                    key = "UI_PsychopatzConversation_NPC",
                    fallback = "NPC",
                })
            if not player and layout.message
                and layout.message.speakerName
            then
                npcName = layout.message.speakerName
            end
            local playerName = part.owner
                and part.owner.spec
                and part.owner.spec.context
                and (
                    part.owner.spec.context.playerName
                    or part.owner.spec.context.playerFullName
                )
            local speakerLabel = player
                and (playerName or Text.Resolve({
                        key = "UI_PsychopatzConversation_You",
                        fallback = "YOU",
                    }))
                or tostring(npcName)
            part:drawText(
                string.upper(speakerLabel),
                x + 10,
                y + 4,
                accent.r,
                accent.g,
                accent.b,
                contentAlpha * 0.9,
                UIFont.Small
            )
            if layout.typing then
                part:drawText(
                    Typing.GetText(),
                    x + 10,
                    y + 20,
                    0.74,
                    0.91,
                    0.82,
                    contentAlpha,
                    UIFont.Small
                )
            else
                local lineIndex
                for lineIndex = 1, #layout.lines do
                    drawFormattedLine(
                        part,
                        layout.lines[lineIndex],
                        x + 10,
                        y + 20 + (lineIndex - 1) * lineH,
                        { r = 0.93, g = 0.95, b = 0.92 },
                        accent,
                        contentAlpha,
                        type(layout.lines[lineIndex]) == "table"
                            and layout.lines[lineIndex].kind or nil
                    )
                end
            end
        return typingLayout, typingX, typingY
    end
    return nil, nil, nil
end

function Internal.renderRows(part, contentAlpha, lineH, headerHeight)
    local typingLayout
    local typingX
    local typingY
    for index = 1, #(part.messageLayout or {}) do
        local layout = part.messageLayout[index]
        local rowLayout, rowX, rowY = Internal.renderRow(
            part, layout, contentAlpha, lineH, headerHeight
        )
        if rowLayout then
            typingLayout = rowLayout
            typingX = rowX
            typingY = rowY
        end
    end
    return typingLayout, typingX, typingY
end

function Internal.renderScrollbar(part, contentAlpha, headerHeight)
    if part.maximumScroll > 0 then
        local trackY = headerHeight + 7
        local trackH = math.max(18, part.height - trackY - 8)
        local viewportH = math.max(1, part.height - headerHeight)
        local thumbH = math.max(18, trackH * (viewportH / part.contentHeight))
        local thumbY = trackY + (trackH - thumbH)
            * (1 - ((part.scrollOffset or 0) / part.maximumScroll))
        local accent = part:getAccentColor()
        part:drawRect(part.width - 7, trackY, 2, trackH,
            contentAlpha * 0.18, accent.r, accent.g, accent.b)
        part:drawRect(part.width - 8, thumbY, 4, thumbH,
            contentAlpha * 0.88, accent.r, accent.g, accent.b)
    end
end

function Internal.render(part)
    local contentAlpha = part:getContentOpacity()
    local lineH = fontHeight()
    if part.reveal <= 0 then
        if part.typingSpeaker then
            traceTypingRender(part, nil, nil, nil, false, contentAlpha, "reveal")
        end
        return
    end
    local headerHeight = part.headerHeight or 24
    part:setStencilRect(
        2,
        headerHeight + 2,
        part.width - 5,
        part.height - headerHeight - 5
    )
    local typingLayout, typingX, typingY = Internal.renderRows(
        part, contentAlpha, lineH, headerHeight
    )
    if part.typingSpeaker then
        local visible = typingLayout ~= nil
        traceTypingRender(
            part,
            typingLayout,
            typingX,
            typingY,
            visible,
            contentAlpha,
            visible and "visible" or "clipped"
        )
    end
    part:clearStencilRect()
    Internal.renderScrollbar(part, contentAlpha, headerHeight)
end

return Internal
