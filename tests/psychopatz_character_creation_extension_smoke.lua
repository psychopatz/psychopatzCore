local T = require "tests/support/test"
T.addPackagePaths()

local ROOT =
    T.path("runtime_client", "PsychopatzCore/")

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertTrue(value, label)
    if not value then error(label or "expected true") end
end

local function traitDefinition(id)
    return {
        getType = function()
            return { getName = function() return id end }
        end,
    }
end

CharacterCreationProfession = {
    populateTraitList = function(self, list)
        self.populationCalls = (self.populationCalls or 0) + 1
        list.items = {}
        return "populated"
    end,
    create = function(self)
        self.created = true
        return "created"
    end,
    repopulateTraitLists = function(self)
        self.repopulateCalls = (self.repopulateCalls or 0) + 1
        return "repopulated"
    end,
    onSelectProf = function(self, profession)
        self.profession = profession
        return "profession"
    end,
    setVisible = function(self, visible)
        self.visible = visible
        return "visible"
    end,
    loadBuild = function(self)
        self.loaded = true
        return "loaded"
    end,
    resetBuild = function(self)
        self.reset = "build"
        return "reset-build"
    end,
    resetTraits = function(self)
        self.reset = "traits"
        return "reset-traits"
    end,
    randomizeTraits = function(self)
        self.randomized = true
        return "randomized"
    end,
}
package.preload["OptionScreens/CharacterCreationProfession"] =
    function() return CharacterCreationProfession end

PsychopatzCore = { Traits = {} }
PsychopatzCore.Traits.GetDefinitions = function() return {} end
PsychopatzCore.Traits.EngineTraits = {}
T = nil

dofile(ROOT .. "Traits/PsychopatzTraitCharacterCreation.lua")
local Extension = PsychopatzCore.CharacterCreationExtension
assertTrue(Extension ~= nil, "extension registry exists")
assertEqual(Extension.VERSION, 1, "extension version")

local events = {}
local provider = {
    onEvent = function(screen, payload)
        events[#events + 1] = {
            kind = payload.event,
            reason = payload.reason,
            screen = screen,
            selected = payload.selectedTraitIDs,
        }
    end,
}
local ok, reason = Extension.Register("test.provider", provider)
assertTrue(ok, "provider registered: " .. tostring(reason))
local sameOK, sameReason = Extension.Register("test.provider", provider)
assertTrue(sameOK, "provider registration idempotent: " .. tostring(sameReason))
local rejected = Extension.Register("test.provider", { onEvent = function() end })
assertEqual(rejected, false, "provider ID collision rejected")

local screen = setmetatable({
    listboxTraitSelected = {
        items = {
            { item = traitDefinition("pnc:pnc_hasbrother") },
            { item = traitDefinition("pnc:pnc_hasbrother") },
            { item = traitDefinition("pnc:pnc_hasfriend") },
        },
    },
}, { __index = CharacterCreationProfession })

local selected = Extension.ReadSelectedTraitIDs(screen)
assertEqual(#selected, 2, "selected trait IDs are deduplicated")
assertEqual(selected[1], "pnc:pnc_hasbrother", "first selected trait")
assertEqual(selected[2], "pnc:pnc_hasfriend", "second selected trait")

assertEqual(screen:repopulateTraitLists(), "repopulated",
    "normal screen uses extension wrapper")
assertEqual(screen:onSelectProf("occupation"), "profession",
    "profession change uses extension wrapper")
assertEqual(screen:create(), "created", "screen creation uses extension wrapper")
assertEqual(screen:setVisible(true), "visible", "show uses extension wrapper")
assertEqual(screen:setVisible(false), "visible", "hide uses extension wrapper")
assertEqual(CharacterCreationProfession.loadBuild(screen, {}), "loaded",
    "build load uses extension wrapper")
assertEqual(screen:resetBuild(), "reset-build", "build reset uses wrapper")
assertEqual(screen:resetTraits(), "reset-traits", "trait reset uses wrapper")
assertEqual(screen:randomizeTraits(), "randomized",
    "randomize uses extension wrapper")

local CoopCharacterCreationProfession = setmetatable({
    __index = CharacterCreationProfession,
}, { __index = CharacterCreationProfession })
local coopScreen = setmetatable({
    listboxTraitSelected = { items = {
        { item = traitDefinition("pnc:pnc_hassister") },
    } },
}, { __index = CoopCharacterCreationProfession })
local beforeCoop = #events
coopScreen:repopulateTraitLists()
assertEqual(#events, beforeCoop + 1,
    "co-op inherited screen uses the same extension path")
assertEqual(events[#events].screen, coopScreen,
    "co-op event carries the co-op screen")
assertEqual(events[#events].selected[1], "pnc:pnc_hassister",
    "co-op event reads actual selected traits")

local kinds = {}
for index = 1, #events do kinds[events[index].kind] = true end
assertTrue(kinds[Extension.EVENT_TRAIT_SET_CHANGED],
    "trait-set event emitted")
assertTrue(kinds[Extension.EVENT_SCREEN_CREATED],
    "created event emitted")
assertTrue(kinds[Extension.EVENT_SCREEN_SHOWN],
    "shown event emitted")
assertTrue(kinds[Extension.EVENT_SCREEN_HIDDEN],
    "hidden event emitted")
assertTrue(kinds[Extension.EVENT_BUILD_LOADED],
    "load event emitted")
assertTrue(kinds[Extension.EVENT_BUILD_RESET],
    "reset event emitted")
assertTrue(kinds[Extension.EVENT_RANDOMIZED],
    "randomize event emitted")

print("psychopatz_character_creation_extension_smoke: ok")
