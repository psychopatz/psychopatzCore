require "PsychopatzCore/00_PsychopatzCore_Init"

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"
local Registry = require "PsychopatzCore/WorldLoot/PsychopatzWorldLootSourceRegistry"
local Metrics = require "PsychopatzCore/WorldLoot/PsychopatzWorldLootMetrics"
require "PsychopatzCore/WorldLoot/PsychopatzWorldLootAdapters"

local WorldLoot = PsychopatzCore.WorldLoot
WorldLoot.Runtime = WorldLoot.Runtime or {
    sessions = {}, order = {}, nextSessionId = 1,
}
WorldLoot.MAX_RUNTIME_SESSIONS = 64
WorldLoot.MAX_RADIUS = 50
WorldLoot.DEFAULT_RADIUS = 12
WorldLoot.DEFAULT_MAX_CANDIDATES = 512
WorldLoot.DEFAULT_MAX_ITEMS_PER_SOURCE = 256

local function now()
    return getTimeInMillis and tonumber(getTimeInMillis()) or 0
end

local function authorityAllowed(options)
    return options and options.skipAuthorityCheck == true
        or RuntimeRole.AllowsServerCode()
end

local function copyDescriptor(value)
    local output = {}
    for key, field in pairs(value or {}) do
        if type(field) == "string" or type(field) == "number"
            or type(field) == "boolean"
        then output[key] = field end
    end
    return output
end

local function removeSession(sessionId)
    local session = WorldLoot.Runtime.sessions[sessionId]
    if not session then return false end
    WorldLoot.Runtime.sessions[sessionId] = nil
    for index = #WorldLoot.Runtime.order, 1, -1 do
        if WorldLoot.Runtime.order[index] == sessionId then
            table.remove(WorldLoot.Runtime.order, index)
            break
        end
    end
    Metrics.SetGauge("ActiveSessions", #WorldLoot.Runtime.order)
    return true
end

local function newSession(options)
    while #WorldLoot.Runtime.order >= WorldLoot.MAX_RUNTIME_SESSIONS do
        removeSession(WorldLoot.Runtime.order[1])
        Metrics.Increment("SessionEvictions")
    end
    local id = "wl:" .. tostring(WorldLoot.Runtime.nextSessionId)
    WorldLoot.Runtime.nextSessionId = WorldLoot.Runtime.nextSessionId + 1
    local session = {
        id = id, createdAt = now(), revision = 1,
        ownerToken = options and options.ownerToken ~= nil
            and tostring(options.ownerToken) or nil,
        sources = {}, sourceOrder = {}, reservations = {},
        nextReservationId = 1,
    }
    WorldLoot.Runtime.sessions[id] = session
    WorldLoot.Runtime.order[#WorldLoot.Runtime.order + 1] = id
    Metrics.SetGauge("ActiveSessions", #WorldLoot.Runtime.order)
    return session
end

local function resolveSource(sourceToken)
    sourceToken = tostring(sourceToken or "")
    local sessionId = string.match(sourceToken, "^(wl:%d+):s:%d+$")
    local session = sessionId and WorldLoot.Runtime.sessions[sessionId] or nil
    local source = session and session.sources[sourceToken] or nil
    return session, source
end

local function normalizePolicy(policy)
    policy = type(policy) == "table" and policy or {}
    return {
        containers = policy.containers == true,
        floorItems = policy.floorItems == true or policy.floor == true,
        corpses = policy.corpses == true,
    }
end

function WorldLoot.RegisterSourceAdapter(adapter)
    return Registry.Register(adapter)
end

function WorldLoot.FindSources(options)
    local startedAt = now()
    options = type(options) == "table" and options or {}
    if not authorityAllowed(options) then return nil, "server_authority_required" end
    local x = math.floor(tonumber(options.x) or 0)
    local y = math.floor(tonumber(options.y) or 0)
    local z = math.floor(tonumber(options.z) or 0)
    local radius = math.max(0, math.min(WorldLoot.MAX_RADIUS,
        math.floor(tonumber(options.radius) or WorldLoot.DEFAULT_RADIUS)))
    local maximum = math.max(1, math.floor(tonumber(options.maxCandidates)
        or WorldLoot.DEFAULT_MAX_CANDIDATES))
    local policy = normalizePolicy(options.sourceTypes or options.sourcePolicy)
    local adapters = Registry.List(policy)
    if #adapters < 1 then return nil, "source_policy_empty" end
    local cell = options.cell or (getCell and getCell())
    if not cell or not cell.getGridSquare then return nil, "world_unavailable" end
    local session = newSession(options)
    local descriptors = {}
    local seen = {}
    local counts = { container = 0, floor = 0, corpse = 0 }
    local truncated = false
    local radiusSq = radius * radius
    local function emit(runtimeSource, descriptor, dedupKey)
        if #descriptors >= maximum then truncated = true; return false end
        dedupKey = tostring(dedupKey or "")
        if dedupKey == "" or seen[dedupKey] then return true end
        seen[dedupKey] = true
        local token = session.id .. ":s:" .. tostring(#session.sourceOrder + 1)
        descriptor = copyDescriptor(descriptor)
        descriptor.sourceToken = token
        descriptor.approximateDistanceSq =
            (tonumber(descriptor.x) - x) * (tonumber(descriptor.x) - x)
            + (tonumber(descriptor.y) - y) * (tonumber(descriptor.y) - y)
        runtimeSource.descriptor = descriptor
        runtimeSource.adapter = Registry.Get(descriptor.sourceType)
        runtimeSource.items = {}
        runtimeSource.itemTokens = {}
        runtimeSource.nextItemId = 1
        session.sources[token] = runtimeSource
        session.sourceOrder[#session.sourceOrder + 1] = token
        descriptors[#descriptors + 1] = descriptor
        counts[descriptor.sourceType] = (counts[descriptor.sourceType] or 0) + 1
        Metrics.Increment("Candidates"
            .. string.upper(string.sub(descriptor.sourceType, 1, 1))
            .. string.sub(descriptor.sourceType, 2))
        return true
    end
    Metrics.Increment("Searches")
    for offsetY = -radius, radius do
        for offsetX = -radius, radius do
            if offsetX * offsetX + offsetY * offsetY <= radiusSq then
                local square = cell:getGridSquare(x + offsetX, y + offsetY, z)
                Metrics.Increment("SquaresVisited")
                if square then
                    for index = 1, #adapters do
                        adapters[index].Discover(square, options, emit)
                        if truncated then break end
                    end
                end
            end
            if truncated then break end
        end
        if truncated then break end
    end
    table.sort(descriptors, function(left, right)
        if left.approximateDistanceSq ~= right.approximateDistanceSq then
            return left.approximateDistanceSq < right.approximateDistanceSq
        end
        return left.sourceToken < right.sourceToken
    end)
    session.truncated = truncated
    session.counts = counts
    Metrics.Increment("SourcesDiscovered", #descriptors)
    if truncated then Metrics.Increment("CandidateCapHits") end
    Metrics.ObserveMilliseconds("Search", now() - startedAt)
    return {
        sessionId = session.id,
        revision = session.revision,
        sources = descriptors,
        counts = copyDescriptor(counts),
        truncated = truncated,
        sourcePolicy = policy,
    }
end

function WorldLoot.ResolveSource(sourceToken)
    local _, source = resolveSource(sourceToken)
    if not source then return nil, "source_token_invalid" end
    if not source.adapter.IsValid(source) then return nil, "source_invalid" end
    return copyDescriptor(source.descriptor)
end

function WorldLoot.GetSourceLocation(sourceToken)
    local _, source = resolveSource(sourceToken)
    if not source then return nil, "source_token_invalid" end
    return source.adapter.GetLocation(source)
end

function WorldLoot.IsSourceValid(sourceToken)
    local _, source = resolveSource(sourceToken)
    return source ~= nil and source.adapter.IsValid(source) == true
end

local function itemIdentity(item)
    local id = item and item.getID and item:getID() or nil
    return id ~= nil and "id:" .. tostring(id) or "ref:" .. tostring(item)
end

function WorldLoot.ListItems(sourceToken, options)
    local startedAt = now()
    options = type(options) == "table" and options or {}
    local session, source = resolveSource(sourceToken)
    if not source then return nil, "source_token_invalid" end
    if not source.adapter.IsValid(source) then return nil, "source_invalid" end
    local maximum = math.max(1, math.floor(tonumber(options.maxItems)
        or WorldLoot.DEFAULT_MAX_ITEMS_PER_SOURCE))
    local items = source.adapter.ListItems(source, options) or {}
    local descriptors = {}
    for index = 1, math.min(#items, maximum) do
        local item = items[index]
        local identity = itemIdentity(item)
        local token = source.itemTokens[identity]
        if not token then
            token = sourceToken .. ":i:" .. tostring(source.nextItemId)
            source.nextItemId = source.nextItemId + 1
            source.itemTokens[identity] = token
        end
        source.items[token] = item
        descriptors[#descriptors + 1] = {
            itemToken = token,
            fullType = tostring(item and item.getFullType
                and item:getFullType() or item and item.fullType or ""),
            displayName = tostring(item and item.getDisplayName
                and item:getDisplayName() or item and item.getName
                and item:getName() or "Item"),
            quantity = 1,
            category = tostring(item and item.getCategory
                and item:getCategory() or "Item"),
        }
    end
    local truncated = #items > maximum
    if truncated then Metrics.Increment("ItemCapHits") end
    Metrics.Increment("ItemsExamined", #descriptors)
    Metrics.ObserveMilliseconds("ItemInspection", now() - startedAt)
    session.revision = session.revision + 1
    return descriptors, nil, {
        sessionId = session.id, revision = session.revision,
        truncated = truncated,
    }
end

local function resolveItem(sourceToken, itemToken)
    local session, source = resolveSource(sourceToken)
    if not source then return nil, nil, nil, "source_token_invalid" end
    itemToken = tostring(itemToken or "")
    local item = source.items[itemToken]
    if not item then return session, source, nil, "item_token_invalid" end
    local current = source.adapter.ListItems(source) or {}
    for index = 1, #current do
        if current[index] == item then return session, source, item end
    end
    return session, source, nil, "item_unavailable"
end

function WorldLoot.ReserveItem(sourceToken, itemToken, owner)
    local session, source, item, reason = resolveItem(sourceToken, itemToken)
    if not item then return nil, reason end
    itemToken = tostring(itemToken or "")
    local existing = session.reservations[itemToken]
    if existing then
        if tostring(existing.owner or "") == tostring(owner or "") then
            return existing
        end
        return nil, "item_reserved"
    end
    local reservation = {
        reservationToken = session.id .. ":r:"
            .. tostring(session.nextReservationId),
        sourceToken = tostring(sourceToken),
        itemToken = itemToken,
        owner = owner ~= nil and tostring(owner) or "",
    }
    session.nextReservationId = session.nextReservationId + 1
    session.reservations[itemToken] = reservation
    session.revision = session.revision + 1
    Metrics.Increment("Reservations")
    return copyDescriptor(reservation)
end

function WorldLoot.ReleaseReservation(reservationToken, reason)
    reservationToken = tostring(reservationToken or "")
    local sessionId = string.match(reservationToken, "^(wl:%d+):r:%d+$")
    local session = sessionId and WorldLoot.Runtime.sessions[sessionId] or nil
    if not session then return false, "reservation_not_found" end
    for itemToken, reservation in pairs(session.reservations) do
        if reservation.reservationToken == reservationToken then
            session.reservations[itemToken] = nil
            session.revision = session.revision + 1
            Metrics.Increment("ReservationsReleased")
            return true, reason
        end
    end
    return false, "reservation_not_found"
end

function WorldLoot.RemoveItem(sourceToken, itemSelector, quantity, context)
    context = type(context) == "table" and context or {}
    if not authorityAllowed(context) then return false, "server_authority_required" end
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if quantity ~= 1 then return false, "item_quantity_invalid" end
    local session, source, item, reason = resolveItem(sourceToken,
        type(itemSelector) == "table" and itemSelector.itemToken or itemSelector)
    if not item then return false, reason end
    local store
    store, reason = source.adapter.CreateStore(source, context)
    if not store then return false, reason or "source_store_unavailable" end
    local ok, removed = Inventory.withdraw(store, {
        predicate = function(candidate) return candidate == item end,
    }, 1, context)
    if not ok then Metrics.Increment("RemovalFailures"); return false, removed end
    source.items[tostring(type(itemSelector) == "table"
        and itemSelector.itemToken or itemSelector)] = nil
    session.revision = session.revision + 1
    Metrics.Increment("Removals")
    return true, removed
end

function WorldLoot.Transfer(arguments)
    local startedAt = now()
    arguments = type(arguments) == "table" and arguments or {}
    if not authorityAllowed(arguments) then return false, "server_authority_required" end
    local quantity = math.max(1, math.floor(tonumber(arguments.quantity) or 1))
    if quantity ~= 1 then return false, "item_quantity_invalid" end
    local session, source, item, reason = resolveItem(arguments.sourceToken,
        arguments.itemToken or arguments.itemSelector)
    if not item then Metrics.Increment("UnavailableTransfers"); return false, reason end
    local itemToken = tostring(arguments.itemToken or arguments.itemSelector or "")
    local reservation = session.reservations[itemToken]
    if reservation and reservation.reservationToken
        ~= tostring(arguments.reservationToken or "")
    then return false, "item_reserved" end
    local sourceStore
    sourceStore, reason = source.adapter.CreateStore(source, arguments)
    if not sourceStore then return false, reason or "source_store_unavailable" end
    local destination = arguments.destination
    local destinationStore = destination
    if not destinationStore or type(destinationStore.add) ~= "function" then
        destinationStore, reason = Inventory.wrapPhysicalInventory(destination, {
            recursive = false, syncOnMutation = true,
        })
    end
    if not destinationStore then return false, reason or "destination_unavailable" end
    Metrics.Increment("TransferRequests")
    local ok, result = Inventory.transfer(sourceStore, destinationStore, {
        predicate = function(candidate) return candidate == item end,
    }, 1, arguments)
    if not ok then
        Metrics.Increment("TransferFailures")
        Metrics.ObserveMilliseconds("Transfer", now() - startedAt)
        return false, result
    end
    source.items[itemToken] = nil
    session.reservations[itemToken] = nil
    session.revision = session.revision + 1
    Metrics.Increment("Transfers")
    Metrics.ObserveMilliseconds("Transfer", now() - startedAt)
    return true, result, { revision = session.revision }
end

function WorldLoot.ReleaseSession(sessionId)
    return removeSession(tostring(sessionId or ""))
end

function WorldLoot.GetDiagnostics()
    local snapshot = Metrics.Snapshot()
    snapshot.activeSessions = #WorldLoot.Runtime.order
    return snapshot
end

return WorldLoot
