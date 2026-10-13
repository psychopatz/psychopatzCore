-- Small reusable client-side search index for catalog-style UI.
--
-- The index owns normalization and query caching. Feature code owns the source
-- records, source revision, and any domain-specific predicate such as category
-- or favorite filtering.

local SearchIndex = {}

local function normalize(value)
    local text = string.lower(tostring(value or ""))
    text = text:gsub("[%c%p]", " ")
    text = text:gsub("%s+", " ")
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function appendField(parts, value)
    if type(value) == "table" then
        for _, nested in ipairs(value) do
            appendField(parts, nested)
        end
    elseif value ~= nil then
        parts[#parts + 1] = tostring(value)
    end
end

local function queryTokens(query)
    local tokens = {}
    for token in string.gmatch(normalize(query), "%S+") do
        tokens[#tokens + 1] = token
    end
    return tokens
end

local function matches(text, tokens)
    for _, token in ipairs(tokens) do
        if string.find(text, token, 1, true) == nil then
            return false
        end
    end
    return true
end

local function sourceChanged(index, source, revision)
    if index.source ~= source then return true end
    if revision ~= nil and index.revision ~= revision then return true end
    return false
end

function SearchIndex.Normalize(value)
    return normalize(value)
end

function SearchIndex.New(options)
    options = options or {}
    local index = {
        source = nil,
        revision = nil,
        entries = {},
        queryCache = {},
        queryCacheOrder = {},
        maxCachedQueries = math.max(1, tonumber(options.maxCachedQueries) or 32),
        key = options.key,
        fields = options.fields,
    }

    function index:SetSource(source, revision)
        source = type(source) == "table" and source or {}
        if not sourceChanged(self, source, revision) then return false end

        self.source = source
        self.revision = revision
        self.entries = {}
        self.queryCache = {}
        self.queryCacheOrder = {}

        for position, value in ipairs(source) do
            local parts = {}
            if type(self.fields) == "function" then
                appendField(parts, self.fields(value, position))
            else
                appendField(parts, value)
            end
            local key = type(self.key) == "function"
                and self.key(value, position) or position
            self.entries[#self.entries + 1] = {
                value = value,
                key = tostring(key or position),
                text = normalize(table.concat(parts, " ")),
                position = position,
            }
        end
        return true
    end

    function index:Query(query, predicate)
        local normalized = normalize(query)
        local tokens = queryTokens(normalized)
        local candidates = self.queryCache[normalized]
        if not candidates then
            candidates = {}
            for _, entry in ipairs(self.entries) do
                if matches(entry.text, tokens) then
                    candidates[#candidates + 1] = entry
                end
            end
            self.queryCache[normalized] = candidates
            self.queryCacheOrder[#self.queryCacheOrder + 1] = normalized
            if #self.queryCacheOrder > self.maxCachedQueries then
                local oldest = table.remove(self.queryCacheOrder, 1)
                self.queryCache[oldest] = nil
            end
        end

        local output = {}
        for _, entry in ipairs(candidates) do
            if not predicate or predicate(entry.value, entry.position) then
                output[#output + 1] = entry.value
            end
        end
        return output
    end

    function index:Count()
        return #self.entries
    end

    return index
end

return SearchIndex
