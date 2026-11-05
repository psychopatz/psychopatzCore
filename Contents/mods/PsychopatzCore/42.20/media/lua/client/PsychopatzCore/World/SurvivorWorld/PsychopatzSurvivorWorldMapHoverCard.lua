-- Provider-neutral map hover card for a canonical SurvivorWorld actor.
-- Adopters provide metadata; Core owns the portrait/card presentation.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorldMapHoverCard =
    PsychopatzCore.SurvivorWorldMapHoverCard or {}

local Card = ISPanel:derive("PsychopatzSurvivorWorldMapHoverCard")
local PortraitPanel = PsychopatzCore.UI
    and PsychopatzCore.UI.PortraitPanel

Card.FaceZoom = 18
Card.FaceYOffset = -0.85
Card.DebugBackground = false

local FACTION_COLOR = { r = 0.82, g = 0.61, b = 0.16 }
local ROLE_COLOR = { r = 0.16, g = 0.55, b = 0.78 }
local PRESENCE_COLORS = {
    LIVE = { r = 0.24, g = 0.86, b = 0.38 },
    ABSTRACT = { r = 1.00, g = 0.68, b = 0.18 },
    CORPSE = { r = 0.65, g = 0.65, b = 0.65 },
    UNKNOWN = { r = 0.70, g = 0.70, b = 0.70 },
}

local function firstGlyph(value, fallback)
    local text = tostring(value or "")
    if text == "" then return fallback end
    return string.upper(string.sub(text, 1, 1))
end

local function normalizePresence(value)
    local presence = string.upper(tostring(value or "UNKNOWN"))
    if presence == "MATERIALIZED" or presence == "PHYSICAL" then
        return "LIVE"
    end
    if presence == "ABSTRACT" or presence == "LIVE"
        or presence == "CORPSE"
    then
        return presence
    end
    return "UNKNOWN"
end

function Card:initialise()
    ISPanel.initialise(self)
    self.background = false
end

function Card:createChildren()
    ISPanel.createChildren(self)
    if self.portrait or not PortraitPanel or not PortraitPanel.new then
        return
    end
    self.portrait = PortraitPanel:new(
        0,
        0,
        self.portraitSize,
        self.portraitSize,
        {
            zoom = self.portraitZoom,
            xOffset = 0,
            yOffset = self.portraitYOffset,
            direction = IsoDirections and IsoDirections.S,
            animSetName = false,
            stateName = "idle",
            animate = false,
            faceOnly = true,
            includeCurrentClothing = true,
            clothingMode = "current",
            showBackground = self.debugBackground,
            showBorder = false,
            padding = 0,
        }
    )
    self.portrait:initialise()
    self.portrait:instantiate()
    self:addChild(self.portrait)
end

function Card:setTarget(character, spec)
    spec = spec or character
    if not self.portrait or not self.portrait.setTarget then return false end
    return self.portrait:setTarget(nil, spec) == true
end

function Card:setContext(entry, marker, suppliedMetadata)
    local metadata = type(suppliedMetadata) == "table"
        and suppliedMetadata
        or type(marker) == "table"
            and type(marker.hoverMetadata) == "table"
            and marker.hoverMetadata or {}
    local factionSource = metadata.factionPresentation
        or metadata.organizationalFaction
        or entry and (entry.factionPresentation
            or entry.organizationalFaction
            or entry.affiliation)
        or nil
    local name = metadata.name or metadata.displayName
        or entry and (
            entry.label or entry.displayName or entry.name or entry.actorID
                or entry.id or entry.npcId
        )
        or "Survivor"
    local faction = metadata.factionName
        or factionSource and (factionSource.name or factionSource.id)
        or entry and entry.factionName or ""
    local role = metadata.role or metadata.factionRole
        or factionSource and (factionSource.role or factionSource.rank)
        or entry and (entry.role or entry.roleTag) or ""
    local presence = normalizePresence(
        metadata.presence or metadata.providerState
            or entry and entry.providerState
    )
    local factionBadge = metadata.factionBadge or metadata.badge
        or factionSource and (factionSource.badge or factionSource.emblem)
    local actorIcon = metadata.actorIcon or metadata.icon
    local factionGlyph = factionBadge and factionBadge.glyph
        or metadata.factionGlyph or faction
    local roleGlyph = actorIcon and actorIcon.glyph
        or metadata.roleGlyph or role or "?"
    if self.contextName == name
        and self.contextFaction == faction
        and self.contextRole == role
        and self.contextPresence == presence
        and self.contextFactionGlyph == factionGlyph
        and self.contextRoleGlyph == roleGlyph
    then
        return
    end
    self.contextName = tostring(name)
    self.contextFaction = tostring(faction)
    self.contextRole = tostring(role)
    self.contextPresence = presence
    self.contextPresenceColor = PRESENCE_COLORS[presence]
        or PRESENCE_COLORS.UNKNOWN
    self.contextFactionGlyph = firstGlyph(factionGlyph, "?")
    self.contextRoleGlyph = firstGlyph(roleGlyph, "?")
end

function Card:drawPresenceBadge()
    local presence = self.contextPresence
    if not presence then return end
    local color = self.contextPresenceColor or PRESENCE_COLORS.UNKNOWN
    local width = presence == "ABSTRACT" and 84 or 68
    local height = 18
    local x = 4
    local y = 4
    self:drawRect(x + 2, y + 2, width, height, 0.55, 0, 0, 0)
    self:drawRect(x, y, width, height, 0.94,
        color.r, color.g, color.b)
    if self.drawRectBorder then
        self:drawRectBorder(x, y, width, height, 1,
            0.04, 0.04, 0.04)
    end
    self:drawTextCentre(
        presence,
        x + width / 2,
        y + 2,
        0.04, 0.04, 0.04, 1,
        UIFont.Small
    )
end

function Card:setCardPosition(x, y)
    if self.setX then self:setX(x) else self.x = x end
    if self.setY then self:setY(y) else self.y = y end
end

function Card:drawBadge(x, color, glyph)
    local y = self.portraitSize - self.badgeSize - self.badgeInset
    self:drawRect(x + 2, y + 2, self.badgeSize, self.badgeSize,
        0.55, 0, 0, 0)
    self:drawRect(x, y, self.badgeSize, self.badgeSize, 0.96,
        color.r, color.g, color.b)
    if self.drawRectBorder then
        self:drawRectBorder(x, y, self.badgeSize, self.badgeSize, 1,
            0.05, 0.05, 0.05)
    end
    self:drawTextCentre(
        glyph or "?",
        x + self.badgeSize / 2,
        y + 3,
        1, 1, 1, 1,
        UIFont.Small
    )
end

function Card:render()
    ISPanel.render(self)
    self:drawPresenceBadge()
    local nameY = self.portraitSize
    self:drawRect(0, nameY, self.width, self.nameHeight,
        0.91, 0.035, 0.035, 0.035)
    self:drawRect(0, nameY, self.width, 2, 0.95,
        FACTION_COLOR.r, FACTION_COLOR.g, FACTION_COLOR.b)
    self:drawTextCentre(
        self.contextName or "Survivor",
        self.width / 2,
        nameY + 5,
        1, 1, 1, 1,
        UIFont.Small
    )
    self:drawBadge(self.badgeInset, FACTION_COLOR,
        self.contextFactionGlyph)
    self:drawBadge(
        self.width - self.badgeSize - self.badgeInset,
        ROLE_COLOR,
        self.contextRoleGlyph
    )
end

function Card:new(x, y, portraitSize, options)
    local size = math.max(1, tonumber(portraitSize) or 128)
    local values = options or {}
    local nameHeight = math.max(18, tonumber(values.nameHeight) or 24)
    local o = ISPanel:new(x, y, size, size + nameHeight)
    setmetatable(o, self)
    self.__index = self
    o.portraitSize = size
    o.nameHeight = nameHeight
    o.badgeSize = math.max(18, tonumber(values.badgeSize) or 24)
    o.badgeInset = math.max(2, tonumber(values.badgeInset) or 5)
    o.portraitZoom = tonumber(values.portraitZoom)
        or tonumber(self.FaceZoom) or 18
    o.portraitYOffset = tonumber(values.portraitYOffset)
        or tonumber(self.FaceYOffset) or -0.85
    o.debugBackground = values.debugBackground == true
        or self.DebugBackground == true
    o.contextPresence = "UNKNOWN"
    o.contextFactionGlyph = "?"
    o.contextRoleGlyph = "?"
    return o
end

PsychopatzCore.SurvivorWorldMapHoverCard = Card
return Card
