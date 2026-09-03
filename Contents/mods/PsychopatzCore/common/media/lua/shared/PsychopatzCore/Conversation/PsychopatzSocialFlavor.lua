-- Shared, deterministic flavor registry.
--
-- Definitions are data only.  The client arbitration module decides whether a
-- line is allowed to be presented; this module only selects an appropriate
-- localized/fallback variant for a bounded context.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.SocialFlavor = PsychopatzCore.SocialFlavor or {}

local Flavor = PsychopatzCore.SocialFlavor
Flavor.VERSION = 1
Flavor.Definitions = Flavor.Definitions or {}

local function clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function valueMatches(actual, expected)
    if type(expected) ~= "table" then
        return tostring(actual or "") == tostring(expected or "")
    end
    for _, value in ipairs(expected) do
        if tostring(actual or "") == tostring(value or "") then
            return true
        end
    end
    return false
end

local function matches(context, conditions)
    if type(conditions) ~= "table" then return true, 0 end
    local count = 0
    for key, expected in pairs(conditions) do
        local actual = context[key]
        if key == "npcType" and actual == nil then
            actual = context.socialRole
        elseif key == "socialRole" and actual == nil then
            actual = context.npcType
        end
        if not valueMatches(actual, expected) then return false, 0 end
        count = count + 1
    end
    return true, count
end

local function stableHash(value)
    local hash = 5381
    value = tostring(value or "")
    for index = 1, #value do
        hash = (hash * 33 + string.byte(value, index)) % 2147483647
    end
    return hash
end

local function lineValue(line)
    if type(line) == "string" then
        return { fallback = line }
    end
    if type(line) ~= "table" then return { fallback = "" } end
    return line
end

local function translate(line)
    line = lineValue(line)
    local key = clean(line.key, nil)
    local fallback = clean(line.fallback or line.text, key or "")
    if key and getText then
        local ok, translated = pcall(getText, key)
        translated = ok and clean(translated, nil) or nil
        if translated and translated ~= key then return translated end
    end
    return fallback
end

local function format(text, context)
    context = type(context) == "table" and context or {}
    text = tostring(text or "")
    return string.gsub(text, "{([%w_]+)}", function(token)
        local value = context[token]
        if value == nil and token == "role" then
            value = context.socialRole or context.npcType
        end
        return value == nil and "{" .. token .. "}" or tostring(value)
    end)
end

local function speakerLines(definition, speaker)
    local lines = definition and definition[speaker]
    if type(lines) ~= "table" then
        lines = definition and definition.npc
    end
    return type(lines) == "table" and lines or {}
end

local function chooseVariant(definition, context)
    local selected = definition and definition.default or definition or {}
    local selectedScore = -1
    local variants = definition and definition.variants or {}
    if type(variants) ~= "table" then return selected end
    for _, variant in ipairs(variants) do
        if type(variant) == "table" then
            local matched, score = matches(context, variant.when)
            if matched and score > selectedScore then
                selected = variant
                selectedScore = score
            end
        end
    end
    return selected
end

function Flavor.Register(flavorID, definition)
    flavorID = clean(flavorID, nil)
    if not flavorID or type(definition) ~= "table" then return false end
    Flavor.Definitions[flavorID] = definition
    return true
end

function Flavor.Get(flavorID)
    return Flavor.Definitions[clean(flavorID, "")]
end

function Flavor.ResolveDetailed(flavorID, speaker, seed, context)
    local definition = Flavor.Get(flavorID)
    if not definition then return nil end
    speaker = clean(speaker, "npc")
    context = type(context) == "table" and context or {}
    local variant = chooseVariant(definition, context)
    local lines = speakerLines(variant, speaker)
    if #lines == 0 and variant ~= definition then
        lines = speakerLines(definition, speaker)
    end
    if #lines == 0 then return nil end
    local index = (stableHash(flavorID .. ":" .. tostring(seed or ""))
        % #lines) + 1
    local line = lineValue(lines[index])
    local resolved = format(translate(line), context)
    if resolved == "" then return nil end
    return {
        text = resolved,
        flavorID = flavorID,
        variantID = variant.id,
        lineIndex = index,
    }
end

function Flavor.Resolve(flavorID, speaker, seed, context)
    local result = Flavor.ResolveDetailed(flavorID, speaker, seed, context)
    return result and result.text or nil
end

return Flavor
