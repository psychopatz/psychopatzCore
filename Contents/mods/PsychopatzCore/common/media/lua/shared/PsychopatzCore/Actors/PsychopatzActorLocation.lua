local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Location = {}

Location.SCHEMA_VERSION = 1
Location.MAX_ANCHORS = 64

local function number(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then return fallback end
    return value
end

local function point(value, fallback)
    value = type(value) == "table" and value or {}
    fallback = type(fallback) == "table" and fallback or {}
    return {
        x = number(value.x, number(fallback.x, 0)),
        y = number(value.y, number(fallback.y, 0)),
        z = number(value.z, number(fallback.z, 0)),
    }
end

function Location.NormalizePoint(value, fallback)
    return point(value, fallback)
end

function Location.NewAnchor(spec, fallbackID)
    spec = type(spec) == "table" and spec or {}
    local anchorID = Util.text(spec.anchorID or spec.id or fallbackID, nil)
    if not anchorID then return nil, "anchor_id_required" end
    local metadata = Util.clone(spec.metadata or {})
    if not Util.isSerializable(metadata) then
        return nil, "anchor_metadata_invalid"
    end
    return {
        schemaVersion = Location.SCHEMA_VERSION,
        anchorID = anchorID,
        kind = Util.text(spec.kind, "point"),
        point = point(spec.point or spec.position or spec),
        metadata = metadata,
        revision = math.max(0, Util.integer(spec.revision, 0)),
    }
end

function Location.NewState(source)
    source = type(source) == "table" and source or {}
    local anchors = {}
    local count = 0
    for key, value in pairs(source.anchors or {}) do
        if count >= Location.MAX_ANCHORS then
            return nil, "anchor_limit_exceeded"
        end
        local anchor, reason = Location.NewAnchor(value, key)
        if not anchor then return nil, reason end
        if anchors[anchor.anchorID] then
            return nil, "duplicate_anchor_id"
        end
        anchors[anchor.anchorID] = anchor
        count = count + 1
    end
    local active = Util.text(source.activeAnchorID, nil)
    if active and not anchors[active] then return nil, "active_anchor_missing" end
    return {
        schemaVersion = Location.SCHEMA_VERSION,
        position = point(source.position or source.point or source),
        anchors = anchors,
        activeAnchorID = active,
        revision = math.max(0, Util.integer(source.revision, 0)),
    }
end

function Location.Validate(state)
    if type(state) ~= "table"
        or Util.integer(state.schemaVersion, 0) ~= Location.SCHEMA_VERSION
        or type(state.position) ~= "table"
        or type(state.anchors) ~= "table"
    then return false, "location_schema_mismatch" end
    local count = 0
    for key, anchor in pairs(state.anchors) do
        count = count + 1
        if count > Location.MAX_ANCHORS
            or type(anchor) ~= "table"
            or key ~= anchor.anchorID
            or Util.integer(anchor.schemaVersion, 0) ~= Location.SCHEMA_VERSION
            or type(anchor.point) ~= "table"
            or type(anchor.metadata) ~= "table"
            or not Util.isSerializable(anchor)
        then return false, "anchor_invalid" end
    end
    if state.activeAnchorID ~= nil
        and state.anchors[state.activeAnchorID] == nil
    then return false, "active_anchor_missing" end
    return true
end

function Location.SetPosition(state, value, expectedRevision)
    if type(state) ~= "table" then return nil, "location_required" end
    if expectedRevision ~= nil
        and tonumber(expectedRevision) ~= tonumber(state.revision)
    then return nil, "revision_conflict" end
    local nextState = Util.clone(state)
    nextState.position = point(value, state.position)
    nextState.activeAnchorID = nil
    nextState.revision = (tonumber(state.revision) or 0) + 1
    return nextState
end

function Location.RegisterAnchor(state, spec, expectedRevision)
    if type(state) ~= "table" then return nil, "location_required" end
    if expectedRevision ~= nil
        and tonumber(expectedRevision) ~= tonumber(state.revision)
    then return nil, "revision_conflict" end
    local anchor, reason = Location.NewAnchor(spec)
    if not anchor then return nil, reason end
    if not state.anchors[anchor.anchorID] then
        local count = 0
        for _ in pairs(state.anchors) do count = count + 1 end
        if count >= Location.MAX_ANCHORS then
            return nil, "anchor_limit_exceeded"
        end
    end
    local nextState = Util.clone(state)
    nextState.anchors[anchor.anchorID] = anchor
    nextState.revision = (tonumber(state.revision) or 0) + 1
    return nextState
end

function Location.Resolve(state, anchorID)
    if type(state) ~= "table" then return nil, "location_required" end
    local anchor = state.anchors and state.anchors[anchorID]
    if not anchor then return nil, "anchor_not_found" end
    return Util.clone(anchor)
end

return Location
