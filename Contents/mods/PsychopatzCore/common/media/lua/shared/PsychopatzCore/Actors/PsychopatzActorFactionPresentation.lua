-- Provider-neutral faction presentation for canonical actor projections.
-- This deliberately contains no ProjectHoomans or adopter-specific art.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Presentation = {}
Presentation.SCHEMA_VERSION = 1
Presentation.MAX_ID_LENGTH = 192
Presentation.MAX_NAME_LENGTH = 128
Presentation.MAX_ARCHETYPE_LENGTH = 96
Presentation.MAX_SYMBOL_LENGTH = 96
Presentation.MAX_GLYPH_LENGTH = 4

local DEFAULT_GLYPHS = {
    trader = "T",
    merchant = "T",
    survivor = "S",
    guard = "G",
    looter = "L",
    raider = "R",
}

local DEFAULT_COLOR = {
    r = 0.82, g = 0.82, b = 0.88, a = 1,
}

local function bounded(value, limit)
    value = tostring(value or "")
    if value == "" then return nil end
    if #value > limit then value = string.sub(value, 1, limit) end
    return value
end

local function color(value)
    value = type(value) == "table" and value or DEFAULT_COLOR
    return {
        r = math.max(0, math.min(1, tonumber(value.r) or DEFAULT_COLOR.r)),
        g = math.max(0, math.min(1, tonumber(value.g) or DEFAULT_COLOR.g)),
        b = math.max(0, math.min(1, tonumber(value.b) or DEFAULT_COLOR.b)),
        a = math.max(0, math.min(1, tonumber(value.a) or DEFAULT_COLOR.a)),
    }
end

local function nestedInput(input)
    if type(input.factionPresentation) == "table" then
        return input.factionPresentation
    end
    if type(input.presentation) == "table" then
        return input.presentation
    end
    return {}
end

function Presentation.Build(input)
    input = type(input) == "table" and input or {}
    local nested = nestedInput(input)
    local factionID = bounded(
        nested.factionID or nested.factionId or nested.id
            or input.factionID or input.factionId,
        Presentation.MAX_ID_LENGTH
    )
    if not factionID then return nil end

    local archetypeID = bounded(
        nested.archetypeID or nested.archetypeId
            or input.factionArchetypeID or input.archetypeID,
        Presentation.MAX_ARCHETYPE_LENGTH
    ) or "survivor.generic"
    local displayName = bounded(
        nested.displayName or nested.name or input.factionName,
        Presentation.MAX_NAME_LENGTH
    ) or factionID
    local symbolID = bounded(
        nested.symbolID or nested.symbolId or nested.iconKey,
        Presentation.MAX_SYMBOL_LENGTH
    ) or archetypeID
    local glyph = bounded(
        nested.glyph or nested.symbol or input.factionGlyph,
        Presentation.MAX_GLYPH_LENGTH
    ) or DEFAULT_GLYPHS[string.lower(archetypeID)] or "F"

    local output = {
        schemaVersion = Presentation.SCHEMA_VERSION,
        factionID = factionID,
        displayName = displayName,
        archetypeID = archetypeID,
        symbolID = symbolID,
        glyph = glyph,
        iconKey = symbolID,
        color = color(nested.color or input.factionColor),
    }

    local badge = nested.badge or input.factionBadge
    if type(badge) == "table" then
        output.badge = {
            shape = bounded(badge.shape or badge.kind, 32) or "circle",
            glyph = bounded(badge.glyph, Presentation.MAX_GLYPH_LENGTH)
                or glyph,
            color = color(badge.color or output.color),
        }
    else
        output.badge = {
            shape = "circle",
            glyph = glyph,
            color = color(output.color),
        }
    end

    return output
end

function Presentation.Validate(value)
    if type(value) ~= "table"
        or not bounded(value.factionID, Presentation.MAX_ID_LENGTH)
        or not bounded(value.displayName, Presentation.MAX_NAME_LENGTH)
        or not bounded(value.archetypeID, Presentation.MAX_ARCHETYPE_LENGTH)
        or not bounded(value.glyph, Presentation.MAX_GLYPH_LENGTH)
    then
        return false, "faction_presentation_invalid"
    end
    if not Util.isSerializable(value) then
        return false, "faction_presentation_not_serializable"
    end
    return true
end

return Presentation
