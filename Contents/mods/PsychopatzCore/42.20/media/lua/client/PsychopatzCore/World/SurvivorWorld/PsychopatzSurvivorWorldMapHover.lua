-- Provider-neutral SurvivorWorld actor portrait hover host.
-- Adopters supply only a canonical actor projection and marker screen point.

local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local PortraitCard

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorldMapHover =
    PsychopatzCore.SurvivorWorldMapHover or {}

local Hover = PsychopatzCore.SurvivorWorldMapHover

Hover.SIZE = 128
Hover.NAME_HEIGHT = 24
Hover.GAP = 8
Hover.DELAY_MS = 90
Hover.KNOWLEDGE_CACHE_MS = 250
Hover.Providers = Hover.Providers or {}

local function normalizeOwner(owner)
    owner = tostring(owner or "")
    return owner ~= "" and owner or nil
end

local function clearCandidateState(map)
    map._psychopatzSurvivorWorldHoverCandidateID = nil
    map._psychopatzSurvivorWorldHoverCandidateAt = nil
    map._psychopatzSurvivorWorldHoverKnowledgeRequestedID = nil
    map._psychopatzSurvivorWorldHoverKnowledgeID = nil
    map._psychopatzSurvivorWorldHoverKnowledgeAt = nil
    map._psychopatzSurvivorWorldHoverKnowledge = nil
end

local function nowMs()
    if type(getTimestampMs) == "function" then
        local value = getTimestampMs()
        if tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        local value = getTimeInMillis()
        if tonumber(value) then return tonumber(value) end
    end
    return 0
end

local function visible(panel, value)
    if not panel then return end
    if type(panel.setVisible) == "function" then
        panel:setVisible(value == true)
    else
        panel.visible = value == true
    end
end

local function claimOwner(map, owner)
    owner = normalizeOwner(owner)
    if not owner or map._psychopatzSurvivorWorldHoverOwner == owner then
        return owner
    end

    visible(map.psychopatzSurvivorWorldHover, false)
    map._psychopatzSurvivorWorldHoverOwner = owner
    map._psychopatzSurvivorWorldHoverActorID = nil
    map._psychopatzSurvivorWorldHoverEntry = nil
    clearCandidateState(map)
    return owner
end

local function portraitCard()
    if PortraitCard then return PortraitCard end
    local ok, value = pcall(
        require,
        "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHoverCard"
    )
    if ok and type(value) == "table" then
        PortraitCard = value
    end
    return PortraitCard
end

local function actorIDFor(entry)
    if type(entry) ~= "table" then return nil end
    local actorID = entry.actorID or entry.id or entry.npcId
    actorID = tostring(actorID or "")
    return actorID ~= "" and actorID or nil
end

local function providerFor(entry)
    local providerID = entry and (
        entry.knowledgeProvider or entry.hoverProvider or entry.provider
    ) or nil
    return Hover.Providers[tostring(providerID or "")]
end

function Hover.RegisterProvider(providerID, adapter)
    providerID = tostring(providerID or "")
    if providerID == "" or type(adapter) ~= "table" then
        return false, "invalid_map_hover_provider"
    end
    if type(adapter.getPortraitSpec) ~= "function"
        and type(adapter.getContext) ~= "function"
    then
        return false, "map_hover_provider_has_no_presentation"
    end
    Hover.Providers[providerID] = adapter
    return true, providerID
end

function Hover.UnregisterProvider(providerID)
    providerID = tostring(providerID or "")
    if providerID == "" or Hover.Providers[providerID] == nil then
        return false
    end
    Hover.Providers[providerID] = nil
    return true
end

local function actorKnowledge(map, entry, actorID)
    if type(Client.GetActorKnowledge) ~= "function" then return nil end
    local now = nowMs()
    if map
        and map._psychopatzSurvivorWorldHoverKnowledgeID == actorID
        and now > 0
        and now - (tonumber(
            map._psychopatzSurvivorWorldHoverKnowledgeAt
        ) or 0)
            < Hover.KNOWLEDGE_CACHE_MS
    then
        return map._psychopatzSurvivorWorldHoverKnowledge
    end
    local providerID = entry and (
        entry.knowledgeProvider or entry.provider
    ) or nil
    local ok, value = pcall(
        Client.GetActorKnowledge,
        actorID,
        {
            provider = providerID,
            source = "map_hover",
            entry = entry,
        }
    )
    if ok and type(value) == "table" then
        if map then
            map._psychopatzSurvivorWorldHoverKnowledgeID = actorID
            map._psychopatzSurvivorWorldHoverKnowledgeAt = now
            map._psychopatzSurvivorWorldHoverKnowledge = value
        end
        return value
    end
    return nil
end

local function requestKnowledge(map, entry, actorID)
    if map._psychopatzSurvivorWorldHoverKnowledgeRequestedID == actorID then
        return
    end
    map._psychopatzSurvivorWorldHoverKnowledgeRequestedID = actorID
    if type(Client.RequestActorKnowledge) == "function" then
        pcall(
            Client.RequestActorKnowledge,
            actorID,
            {
                provider = entry and (
                    entry.knowledgeProvider or entry.provider
                ) or nil,
                source = "map_hover",
                entry = entry,
            }
        )
    end
end

local function identityReady(map, entry, actorID)
    -- Knowledge is player-specific and can arrive before the next actor
    -- projection. Neither stale marker flags nor debug geometry override it.
    local knowledge = actorKnowledge(map, entry, actorID)
    if knowledge then
        local state = string.lower(tostring(knowledge.state or ""))
        if knowledge.nameKnown == true
            or knowledge.nameKnown == nil and state == "known"
        then
            return true
        end
    end
    requestKnowledge(map, entry, actorID)
    return false
end

local function portraitSpec(entry, adapter)
    if adapter and type(adapter.getPortraitSpec) == "function" then
        local ok, value = pcall(adapter.getPortraitSpec, entry)
        if ok and type(value) == "table" then return value end
    end
    return Client.GetPortraitSpec(entry)
end

local function hoverContext(entry, marker, adapter)
    if adapter and type(adapter.getContext) == "function" then
        local ok, value = pcall(adapter.getContext, entry, marker)
        if ok and type(value) == "table" then return value end
    end
    return nil
end

function Hover.Ensure(map)
    if not map then return nil end
    if map.psychopatzSurvivorWorldHover then
        return map.psychopatzSurvivorWorldHover
    end
    local panelType = portraitCard()
    if not panelType or not panelType.new
        or type(map.addChild) ~= "function"
    then
        return nil
    end
    local panel = panelType:new(
        0,
        0,
        Hover.SIZE,
        {
            nameHeight = Hover.NAME_HEIGHT,
            badgeSize = 24,
            badgeInset = 5,
        }
    )
    if panel.initialise then panel:initialise() end
    if panel.instantiate then panel:instantiate() end
    visible(panel, false)
    map:addChild(panel)
    map.psychopatzSurvivorWorldHover = panel
    return panel
end

function Hover.Hide(map, resetCandidate, owner)
    if not map then return false end

    owner = normalizeOwner(owner)
    local currentOwner = map._psychopatzSurvivorWorldHoverOwner
    if owner and currentOwner and currentOwner ~= owner then
        return false
    end

    visible(map.psychopatzSurvivorWorldHover, false)
    map._psychopatzSurvivorWorldHoverActorID = nil
    map._psychopatzSurvivorWorldHoverEntry = nil
    if resetCandidate ~= false then
        clearCandidateState(map)
        map._psychopatzSurvivorWorldHoverOwner = nil
    end
    return true
end

function Hover.Update(map, entry, markerX, markerY, marker, owner)
    local actorID = actorIDFor(entry)
    owner = normalizeOwner(owner)
    if not map or not actorID then
        Hover.Hide(map, nil, owner)
        return false
    end
    claimOwner(map, owner)
    local adapter = providerFor(entry)
    if not identityReady(map, entry, actorID) then
        Hover.Hide(map, false, owner)
        return false
    end
    local spec = portraitSpec(entry, adapter)
    if not spec then
        Hover.Hide(map, nil, owner)
        return false
    end

    actorID = tostring(actorID)
    local now = nowMs()
    if map._psychopatzSurvivorWorldHoverCandidateID
        ~= actorID
    then
        map._psychopatzSurvivorWorldHoverCandidateID =
            actorID
        map._psychopatzSurvivorWorldHoverCandidateAt = now
        Hover.Hide(map, false, owner)
        if now > 0 and Hover.DELAY_MS > 0 then
            return false
        end
    end
    if now > 0
        and now
            - (tonumber(
                map._psychopatzSurvivorWorldHoverCandidateAt
            ) or now)
            < Hover.DELAY_MS
    then
        return false
    end

    local panel = Hover.Ensure(map)
    if not panel then return false end
    if panel.setContext then
        panel:setContext(entry, marker, hoverContext(entry, marker, adapter))
    end
    if map._psychopatzSurvivorWorldHoverActorID ~= actorID
        or map._psychopatzSurvivorWorldHoverEntry ~= entry
    then
        if panel:setTarget(nil, spec, true) ~= true then
            Hover.Hide(map, false, owner)
            return false
        end
        map._psychopatzSurvivorWorldHoverActorID = actorID
        map._psychopatzSurvivorWorldHoverEntry = entry
    end

    local size = Hover.SIZE
    local totalHeight = tonumber(panel.height)
        or size + Hover.NAME_HEIGHT
    local width = tonumber(map.width)
        or (map.getWidth and map:getWidth())
        or size
    local x = math.max(
        4,
        math.min(
            width - size - 4,
            (tonumber(markerX) or 0) - size / 2
        )
    )
    local y = math.max(
        4,
        (tonumber(markerY) or 0) - totalHeight - Hover.GAP
    )
    if panel.setCardPosition then
        panel:setCardPosition(x, y)
    else
        panel.x = x
        panel.y = y
    end
    visible(panel, true)
    return true
end

return Hover
