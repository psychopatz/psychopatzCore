-- Generic bounded event/snapshot streams for external bridge consumers.
-- Mods own the packet payload shape; Core only provides ordering, bounded
-- retention, snapshots, and a resynchronization signal.
local Streams = { channels = {} }

local function valid(value, dotted)
    if type(value) ~= "string" or #value == 0 or #value > 96 then return false end
    if not dotted then return string.match(value, "^[%w_%-]+$") ~= nil end
    if string.sub(value, 1, 1) == "." or string.sub(value, -1) == "."
        or string.find(value, "..", 1, true) then return false end
    for part in string.gmatch(value, "[^.]+") do
        if not string.match(part, "^[%w_%-]+$") then return false end
    end
    return true
end

local function key(namespace, channel)
    return namespace .. ":" .. channel
end

local function notifyChanged()
    if Streams.onChanged then Streams.onChanged() end
end

function Streams.Register(namespace, channel, options)
    if not valid(namespace, true) then return false, "invalid_namespace" end
    if not valid(channel, false) then return false, "invalid_channel" end
    local id = key(namespace, channel)
    if Streams.channels[id] then return false, "duplicate_channel" end
    options = type(options) == "table" and options or {}
    local maxEvents = math.floor(tonumber(options.maxEvents) or 64)
    maxEvents = math.max(1, math.min(maxEvents, 256))
    Streams.channels[id] = {
        id = id, namespace = namespace, channel = channel,
        maxEvents = maxEvents, sequence = 0, snapshotRevision = 0,
        events = {}, snapshot = nil,
    }
    notifyChanged()
    return true
end

function Streams.Unregister(namespace, channel)
    local id = key(namespace, channel)
    if not Streams.channels[id] then return false end
    Streams.channels[id] = nil
    notifyChanged()
    return true
end

function Streams.SetSnapshot(namespace, channel, snapshot, revision)
    local stream = Streams.channels[key(namespace, channel)]
    if not stream then return false, "unknown_channel" end
    stream.snapshot = snapshot
    stream.snapshotRevision = math.max(
        stream.snapshotRevision + 1, math.floor(tonumber(revision) or 0)
    )
    return true, stream.snapshotRevision
end

function Streams.Publish(namespace, channel, packet)
    local stream = Streams.channels[key(namespace, channel)]
    if not stream then return false, "unknown_channel" end
    stream.sequence = stream.sequence + 1
    stream.events[#stream.events + 1] = {
        sequence = stream.sequence, packet = packet,
    }
    while #stream.events > stream.maxEvents do table.remove(stream.events, 1) end
    return true, stream.sequence
end

local function pollStream(stream, after, limit, includeSnapshot)
    after = math.max(0, math.floor(tonumber(after) or 0))
    limit = math.max(1, math.min(math.floor(tonumber(limit) or 32), stream.maxEvents))
    local first = stream.events[1]
    local gap = first ~= nil and after < first.sequence - 1
    local events = {}
    for index = 1, #stream.events do
        local event = stream.events[index]
        if event.sequence > after then
            events[#events + 1] = event
            if #events >= limit then break end
        end
    end
    local row = {
        channel = stream.channel, namespace = stream.namespace,
        after = after, sequence = stream.sequence, events = events,
        gap = gap, snapshot_revision = stream.snapshotRevision,
    }
    if includeSnapshot == true or gap then row.snapshot = stream.snapshot end
    return row
end

function Streams.Poll(arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local subscriptions = arguments.subscriptions
    if type(subscriptions) ~= "table" then return { streams = {} } end
    local output = {}
    for index = 1, math.min(#subscriptions, 32) do
        local subscription = subscriptions[index]
        if type(subscription) == "table" then
            local namespace, channel = subscription.namespace, subscription.channel
            local stream = Streams.channels[key(namespace or "", channel or "")]
            if stream then
                output[#output + 1] = pollStream(
                    stream, subscription.after, subscription.limit,
                    subscription.include_snapshot == true
                )
            else
                output[#output + 1] = {
                    namespace = namespace, channel = channel,
                    error = "unknown_channel",
                }
            end
        end
    end
    return { streams = output }
end

function Streams.Describe()
    local keys = {}
    for id, _ in pairs(Streams.channels) do keys[#keys + 1] = id end
    table.sort(keys)
    local output = {}
    for index = 1, #keys do
        local stream = Streams.channels[keys[index]]
        output[#output + 1] = {
            id = stream.id, namespace = stream.namespace, channel = stream.channel,
            max_events = stream.maxEvents, sequence = stream.sequence,
            snapshot_revision = stream.snapshotRevision,
        }
    end
    return output
end

function Streams.Reset()
    Streams.channels = {}
end

return Streams
