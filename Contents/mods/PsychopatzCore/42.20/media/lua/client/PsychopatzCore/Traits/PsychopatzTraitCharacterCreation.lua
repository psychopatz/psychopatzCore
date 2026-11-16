require "OptionScreens/CharacterCreationProfession"

if not PsychopatzCore or not PsychopatzCore.Traits then
    require "PsychopatzCore/00_PsychopatzCore_Init"
end

local Traits = PsychopatzCore.Traits
local Extension = PsychopatzCore.CharacterCreationExtension
    or {}
PsychopatzCore.CharacterCreationExtension = Extension

Extension.VERSION = 1
Extension.MAX_PROVIDERS = 16
Extension.MAX_SELECTED_TRAITS = 64
Extension.EVENT_SCREEN_CREATED = "screen_created"
Extension.EVENT_TRAIT_SET_CHANGED = "trait_set_changed"
Extension.EVENT_SCREEN_SHOWN = "screen_shown"
Extension.EVENT_SCREEN_HIDDEN = "screen_hidden"
Extension.EVENT_BUILD_LOADED = "build_loaded"
Extension.EVENT_BUILD_RESET = "build_reset"
Extension.EVENT_RANDOMIZED = "randomized"
Extension.Providers = Extension.Providers or {}
Extension.ProviderOrder = Extension.ProviderOrder or {}

local EVENT_NAMES = {
    [Extension.EVENT_SCREEN_CREATED] = true,
    [Extension.EVENT_TRAIT_SET_CHANGED] = true,
    [Extension.EVENT_SCREEN_SHOWN] = true,
    [Extension.EVENT_SCREEN_HIDDEN] = true,
    [Extension.EVENT_BUILD_LOADED] = true,
    [Extension.EVENT_BUILD_RESET] = true,
    [Extension.EVENT_RANDOMIZED] = true,
}

local function text(value)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" then return nil end
    return value
end

local function copySelectedTraitIDs(source)
    local output = {}
    local seen = {}
    local index
    local item
    local definition
    local traitType
    local traitID
    local list = source and source.listboxTraitSelected
    local items = list and list.items
    if type(items) ~= "table" then return output end

    for index = 1, math.min(#items, Extension.MAX_SELECTED_TRAITS) do
        item = items[index]
        definition = item and item.item
        traitType = definition and type(definition.getType) == "function"
            and definition:getType() or nil
        traitID = traitType and type(traitType.getName) == "function"
            and text(traitType:getName()) or nil
        if traitID and not seen[traitID] then
            seen[traitID] = true
            output[#output + 1] = traitID
        end
    end
    return output
end

function Extension.ReadSelectedTraitIDs(screen)
    return copySelectedTraitIDs(screen)
end

function Extension.Register(providerID, provider)
    providerID = text(providerID)
    if not providerID then return false, "invalid_provider_id" end
    if type(provider) ~= "table"
        or type(provider.onEvent) ~= "function"
    then
        return false, "invalid_provider"
    end

    local existing = Extension.Providers[providerID]
    if existing then
        if existing == provider then return true, "already_registered" end
        return false, "provider_id_taken"
    end
    if #Extension.ProviderOrder >= Extension.MAX_PROVIDERS then
        return false, "provider_limit"
    end

    Extension.Providers[providerID] = provider
    Extension.ProviderOrder[#Extension.ProviderOrder + 1] = providerID
    return true, "registered"
end

function Extension.Unregister(providerID, provider)
    providerID = text(providerID)
    local existing = providerID and Extension.Providers[providerID] or nil
    if not existing then return false, "not_registered" end
    if provider and provider ~= existing then return false, "provider_mismatch" end

    Extension.Providers[providerID] = nil
    for index = 1, #Extension.ProviderOrder do
        if Extension.ProviderOrder[index] == providerID then
            table.remove(Extension.ProviderOrder, index)
            break
        end
    end
    return true, "unregistered"
end

function Extension.Notify(eventName, screen, details)
    if not EVENT_NAMES[eventName] then return false, "unknown_event" end

    local payload = {
        event = eventName,
        screen = screen,
        reason = details and text(details.reason) or eventName,
        selectedTraitIDs = copySelectedTraitIDs(screen),
    }
    local providerID
    local provider
    for index = 1, #Extension.ProviderOrder do
        providerID = Extension.ProviderOrder[index]
        provider = Extension.Providers[providerID]
        if provider then
            -- Provider callbacks are the explicit add-on boundary for this
            -- optional UI seam. They are validated at registration and run
            -- directly so callback failures remain visible to the host.
            provider.onEvent(screen, payload)
        end
    end
    return true, payload
end

local function available(screen, definition)
    return (not screen.isTraitEnabled or screen:isTraitEnabled(definition))
        and (not screen.isTraitExcluded or not screen:isTraitExcluded(definition))
end

function Traits.AppendZeroPointTraits(screen, list)
    if not list or not CharacterTraitDefinition
        or not CharacterTraitDefinition.getCharacterTraitDefinition
    then
        return 0
    end

    local added = 0
    local definitions = Traits.GetDefinitions()
    local spec
    local definition
    for index = 1, #definitions do
        spec = definitions[index]
        if spec.cost == 0 then
            definition = Traits.EngineTraits[spec.id]
                and CharacterTraitDefinition.getCharacterTraitDefinition(
                    Traits.EngineTraits[spec.id]
                ) or nil
            if definition and available(screen, definition) then
                if list.addUniqueItem then
                    list:addUniqueItem(
                        definition:getLabel(), definition,
                        definition:getDescription()
                    )
                elseif list.addItem then
                    list:addItem(
                        definition:getLabel(), definition,
                        definition:getDescription()
                    )
                end
                added = added + 1
            end
        end
    end
    return added
end

local function notifyAfter(methodName, eventName, reason)
    local original = CharacterCreationProfession[methodName]
    if type(original) ~= "function" then return end

    local marker = "_psychopatzCharacterCreationPatched_" .. methodName
    if CharacterCreationProfession[marker] then return end
    CharacterCreationProfession[marker] = true

    CharacterCreationProfession[methodName] = function(self, ...)
        local result = original(self, ...)
        local screen = self
        if not screen or not screen.listboxTraitSelected then
            screen = CharacterCreationProfession.instance
        end
        if screen then Extension.Notify(eventName, screen, { reason = reason }) end
        return result
    end
end

if CharacterCreationProfession then
    if not CharacterCreationProfession
        ._psychopatzCharacterCreationPatched_populateTraitList
    then
        CharacterCreationProfession
            ._psychopatzCharacterCreationPatched_populateTraitList = true
        local originalPopulate = CharacterCreationProfession.populateTraitList
        CharacterCreationProfession.populateTraitList = function(self, list)
            local result = originalPopulate(self, list)
            Traits.AppendZeroPointTraits(self, list)
            return result
        end
    end

    notifyAfter(
        "create", Extension.EVENT_SCREEN_CREATED, "create"
    )
    notifyAfter(
        "repopulateTraitLists", Extension.EVENT_TRAIT_SET_CHANGED,
        "repopulate"
    )
    notifyAfter(
        "onSelectProf", Extension.EVENT_TRAIT_SET_CHANGED, "profession"
    )

    local originalSetVisible = CharacterCreationProfession.setVisible
    if type(originalSetVisible) == "function"
        and not CharacterCreationProfession
            ._psychopatzCharacterCreationPatched_visibility
    then
        CharacterCreationProfession
            ._psychopatzCharacterCreationPatched_visibility = true
        CharacterCreationProfession.setVisible = function(self, visible, ...)
            local result = originalSetVisible(self, visible, ...)
            local screen = self or CharacterCreationProfession.instance
            if screen then
                Extension.Notify(
                    visible == true
                        and Extension.EVENT_SCREEN_SHOWN
                        or Extension.EVENT_SCREEN_HIDDEN,
                    screen,
                    { reason = "visible" }
                )
            end
            return result
        end
    end

    notifyAfter(
        "loadBuild", Extension.EVENT_BUILD_LOADED, "load_build"
    )
    notifyAfter(
        "resetBuild", Extension.EVENT_BUILD_RESET, "reset_build"
    )
    notifyAfter(
        "resetTraits", Extension.EVENT_BUILD_RESET, "reset_traits"
    )
    notifyAfter(
        "randomizeTraits", Extension.EVENT_RANDOMIZED, "randomize"
    )
end

return Traits
