-- Namespaced app/contact-provider registry for the reusable Core Radio OS.
-- Device skins and window lifetime live in PsychopatzRadioOSDevice so that
-- extensions cannot accidentally acquire ownership of physical radio state.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RadioOS = PsychopatzCore.RadioOS or {}

local OS = PsychopatzCore.RadioOS
local Model = OS.Model or require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSModel"
OS.Model = Model

local registry = OS._registry or {}
registry.apps = registry.apps or {}
registry.appOrder = registry.appOrder or {}
registry.providers = registry.providers or {}
registry.providerOrder = registry.providerOrder or {}
registry.skins = registry.skins or {}
registry.skinsByFullType = registry.skinsByFullType or {}
registry.windows = registry.windows or {}
registry.revision = tonumber(registry.revision) or 0
OS._registry = registry

local function log(message)
    print("[PsychopatzCore][RadioOS] " .. tostring(message))
end

local function validID(value)
    return type(value) == "string" and value ~= ""
end

local function shallowDefinition(definition)
    local result = {}
    for key, value in pairs(definition) do result[key] = value end
    return result
end

local function sortByOrder(left, right)
    local leftOrder = tonumber(left.order) or 1000
    local rightOrder = tonumber(right.order) or 1000
    if leftOrder == rightOrder then return left.id < right.id end
    return leftOrder < rightOrder
end

local function removeOrdered(order, id)
    for index = #order, 1, -1 do
        if order[index] == id then table.remove(order, index) end
    end
end

local function replaceDefinition(store, order, definition)
    local id = definition.id
    if not store[id] then order[#order + 1] = id end
    store[id] = shallowDefinition(definition)
    table.sort(order, function(leftID, rightID)
        return sortByOrder(store[leftID], store[rightID])
    end)
end

local function safePredicate(predicate, ...)
    if type(predicate) ~= "function" then return true end
    local ok, accepted = pcall(predicate, ...)
    return ok and accepted ~= false
end

function OS.RegisterApp(definition)
    if type(definition) ~= "table" or not validID(definition.id)
        or not validID(definition.ownerModID)
        or (not validID(definition.page)
            and type(definition.open) ~= "function")
    then
        log("ignored invalid app registration")
        return false, "invalid_definition"
    end
    replaceDefinition(registry.apps, registry.appOrder, definition)
    registry.revision = registry.revision + 1
    return true
end

function OS.UnregisterApp(id)
    if not registry.apps[id] then return false end
    registry.apps[id] = nil
    removeOrdered(registry.appOrder, id)
    registry.revision = registry.revision + 1
    return true
end

function OS.GetApp(id)
    return registry.apps[id]
end

function OS.ListApps(context)
    local result = {}
    for _, id in ipairs(registry.appOrder) do
        local app = registry.apps[id]
        if app and safePredicate(app.isAvailable, context) then
            result[#result + 1] = app
        end
    end
    return result
end

function OS.RegisterContactProvider(definition)
    if type(definition) ~= "table" or not validID(definition.id)
        or not validID(definition.ownerModID) or type(definition.list) ~= "function"
    then
        log("ignored invalid contact-provider registration")
        return false, "invalid_definition"
    end
    replaceDefinition(registry.providers, registry.providerOrder, definition)
    registry.revision = registry.revision + 1
    return true
end

function OS.UnregisterContactProvider(id)
    if not registry.providers[id] then return false end
    registry.providers[id] = nil
    removeOrdered(registry.providerOrder, id)
    registry.revision = registry.revision + 1
    return true
end

function OS.GetContactProvider(id)
    return registry.providers[id]
end

function OS.ListContactProviders(context)
    local result = {}
    for _, id in ipairs(registry.providerOrder) do
        local provider = registry.providers[id]
        if provider and safePredicate(provider.isAvailable, context) then
            result[#result + 1] = provider
        end
    end
    return result
end

function OS.EmitContactRefresh(providerID)
    local provider = registry.providers[providerID]
    if not provider then return false, "provider_not_found" end
    registry.revision = registry.revision + 1
    if type(provider.onRefresh) == "function" then
        local ok, result = pcall(provider.onRefresh, provider, registry.revision)
        if not ok then
            log("contact-provider refresh callback failed: " .. tostring(providerID))
            return false, "refresh_failed"
        end
        return result ~= false
    end
    return true
end

function OS.GetRegistryRevision()
    return registry.revision
end

function OS.ListContacts(providerID, context, page)
    local provider = registry.providers[providerID]
    if not provider then return nil, "provider_not_found" end
    if not safePredicate(provider.isAvailable, context) then
        return nil, "provider_unavailable"
    end
    page = type(page) == "table" and page or {}
    page.limit = math.max(1, math.min(Model.MAX_PAGE_SIZE,
        math.floor(tonumber(page.limit) or Model.MAX_PAGE_SIZE)))
    page.offset = math.max(0, math.floor(tonumber(page.offset) or 0))
    -- The page is the stable second argument for providers. Context follows
    -- it so simple providers can remain unaware of player/device internals.
    local ok, payload = pcall(provider.list, provider, page, context)
    if not ok then
        log("contact-provider list failed: " .. tostring(providerID))
        return nil, "provider_failed"
    end
    local normalized = Model.NormalizePage(providerID, payload, page)
    normalized.providerID = providerID
    return true, normalized
end

function OS.InvokeContact(providerID, context, contactID, actionID, snapshot)
    local provider = registry.providers[providerID]
    if not provider then return nil, "provider_not_found" end
    if not safePredicate(provider.isAvailable, context) then
        return nil, "provider_unavailable"
    end
    if type(provider.invoke) ~= "function" then
        return nil, "action_unsupported"
    end
    local id = tostring(contactID or "")
    local action = tostring(actionID or "")
    if id == "" or action == "" then return nil, "invalid_action" end
    local ok, result, reason = pcall(provider.invoke, provider, id, action,
        snapshot, context)
    if not ok then
        log("contact-provider invoke failed: " .. tostring(providerID))
        return nil, "provider_failed"
    end
    return result, reason
end

-- Load device/window ownership after the neutral registry exists. The require
-- is intentionally last so that the device module can reuse this table.
require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDevice"

return OS
