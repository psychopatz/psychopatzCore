local Radio = PsychopatzCore.CustomRadio

Radio.MessagePacks = Radio.MessagePacks or {}

local function copyLine(value)
    if type(value) == "table" then
        return {
            text = tostring(value.text or ""),
            r = tonumber(value.r) or 0.75,
            g = tonumber(value.g) or 0.82,
            b = tonumber(value.b) or 0.72,
            airTime = tonumber(value.airTime),
            effects = value.effects and tostring(value.effects) or nil,
        }
    end
    return { text = tostring(value or ""), r = 0.75, g = 0.82, b = 0.72 }
end

local function expand(text, context)
    return (tostring(text or ""):gsub("{([%w_]+)}", function(key)
        local value = context and context[key]
        return value == nil and "?" or tostring(value)
    end))
end

local function randomIndex(count, context)
    if count <= 1 then return 1 end
    if context and type(context.random) == "function" then
        return math.max(1, math.min(count,
            math.floor(tonumber(context.random(count)) or 1)))
    end
    if ZombRand then return ZombRand(count) + 1 end
    return math.random(count)
end

function Radio.RegisterMessagePack(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.messages) ~= "table"
    then return false end
    definition.id = id
    definition.priority = tonumber(definition.priority) or 0
    Radio.MessagePacks[id] = definition
    return true
end

function Radio.UnregisterMessagePack(id)
    id = tostring(id or "")
    if id == "" or Radio.MessagePacks[id] == nil then return false end
    Radio.MessagePacks[id] = nil
    return true
end

function Radio.SelectMessage(channel, eventType, context)
    local eligible = {}
    local priority
    for _, pack in pairs(Radio.MessagePacks) do
        local packEvent = tostring(pack.eventType or "*")
        local matches = pack.channel == channel
            and (packEvent == "*"
                or packEvent == tostring(eventType or "*"))
        if matches and type(pack.matches) == "function" then
            local ok, result = pcall(pack.matches, context or {})
            matches = ok and result == true
        end
        if matches and (priority == nil or pack.priority >= priority) then
            if priority == nil or pack.priority > priority then eligible = {} end
            priority = pack.priority
            eligible[#eligible + 1] = pack
        end
    end
    if #eligible == 0 then return nil end
    local pack = eligible[randomIndex(#eligible, context)]
    local source = pack.messages[randomIndex(#pack.messages, context)]
    if type(source) == "function" then source = source(context or {}) end
    local lines = type(source) == "table" and source.lines or source
    if type(lines) ~= "table" then lines = { lines } end
    local output = {}
    for _, value in ipairs(lines) do
        local line = copyLine(value)
        line.text = expand(line.text, context)
        if line.text ~= "" then output[#output + 1] = line end
    end
    return {
        packID = pack.id,
        lines = output,
        metadata = type(source) == "table" and source.metadata or nil,
    }
end

return Radio
