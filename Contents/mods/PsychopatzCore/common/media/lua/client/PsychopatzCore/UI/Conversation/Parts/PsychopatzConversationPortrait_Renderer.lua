local Portrait = PsychopatzConversationPortrait
local Internal = Portrait.Internal
local Conversation = Internal.Conversation

function Internal.renderScreenEffects(part, contentAlpha, screenVariant)
    if screenVariant == "none" or contentAlpha <= 0.001 then return end
    local scanAlpha = screenVariant == "crt"
        and contentAlpha * 0.055 or contentAlpha * 0.025
    local scanY
    for scanY = 3, part.height - 4, 5 do
        part:drawRect(
            3,
            scanY,
            part.width - 7,
            1,
            scanAlpha,
            0.03,
            0.08,
            0.065
        )
    end
end

function Internal.renderNameplate(part, contentAlpha, accent, bright, context)
    if contentAlpha <= 0.001 then return end
    local plateHeight = math.max(48, math.min(62, part.height * 0.18))
    local plateY = part.height - plateHeight - 3
    -- The nameplate is part of the portrait feed content. Keeping
    -- its fill and accent with CONTENT lets the entire plate vanish
    -- without hiding the panel frame or affecting its layout.
    part:drawRect(
        3,
        plateY - 18,
        part.width - 7,
        18,
        contentAlpha * 0.35,
        0,
        0,
        0
    )
    part:drawRect(
        3,
        plateY,
        part.width - 7,
        plateHeight,
        contentAlpha * 0.91,
        0.012,
        0.030,
        0.025
    )
    part:drawRect(
        3,
        plateY,
        part.width - 7,
        2,
        contentAlpha * 0.92,
        accent.r,
        accent.g,
        accent.b
    )
    part:drawRect(13, plateY + 13, 7, 7,
        contentAlpha, accent.r, accent.g, accent.b)
    part:drawText(
        string.upper(tostring(context.npcName or "NPC")),
        27,
        plateY + 8,
        bright.r,
        bright.g,
        bright.b,
        contentAlpha,
        UIFont.Small
    )
    local factionName = tostring(context.factionName or "")
    local factionRole = tostring(context.factionRole or "")
    if factionName ~= "" then
        local affiliation = string.upper(factionName)
        if factionRole ~= "" then
            affiliation = affiliation .. " / " .. string.upper(factionRole)
        end
        part:drawText(
            affiliation,
            13,
            plateY + 28,
            bright.r,
            bright.g,
            bright.b,
            contentAlpha * 0.92,
            UIFont.Small
        )
    end
end

function Internal.renderFrame(part, panelAlpha, accent)
    if panelAlpha <= 0.001 then return end
    part:drawRectBorder(2, 2, part.width - 5, part.height - 5,
        panelAlpha * 0.75, accent.r, accent.g, accent.b)
end

function Internal.renderEditOverlay(part)
    if not part.editMode then return end
    part:drawRectBorder(
        0,
        0,
        part.width,
        part.height,
        0.98,
        0.30,
        0.82,
        1.0
    )
    part:drawRect(
        part.width - 14,
        part.height - 14,
        14,
        14,
        0.92,
        0.30,
        0.82,
        1.0
    )
end

function Internal.render(part)
    if (part.reveal or 0) <= 0.18 then return end

    part:clearStencilRect()
    local contentAlpha = part:getContentOpacity()
    local panelAlpha = part:getBackgroundOpacity()
    local accent = part:getAccentColor()
    local bright = Conversation.Theme.Brighten(accent, 0.34)
    local context = part.owner
        and part.owner.spec
        and part.owner.spec.context
        or {}
    Internal.renderScreenEffects(
        part,
        contentAlpha,
        part:getScreenVariant()
    )
    Internal.renderNameplate(part, contentAlpha, accent, bright, context)
    Internal.renderFrame(part, panelAlpha, accent)
    Internal.renderEditOverlay(part)
end

return Internal
