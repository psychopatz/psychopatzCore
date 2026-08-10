local ROOT =
    "Contents/mods/PsychopatzCore/42.19/media/lua/shared/PsychopatzCore/Traits/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local engineTraits = {}
local definitions = {}
CharacterTrait = {
    get = function(location) return engineTraits[location] end,
    register = function(resource)
        local trait = {
            resource = resource,
            toString = function(self) return self.resource end,
        }
        engineTraits[resource] = trait
        return trait
    end,
}
ResourceLocation = { of = function(value) return value end }
CharacterTraitDefinition = {
    getCharacterTraitDefinition = function(trait)
        return definitions[trait]
    end,
    addCharacterTraitDefinition = function(trait, name, cost, description)
        definitions[trait] = {
            name = name,
            cost = cost,
            description = description,
            exclusions = {},
        }
        return definitions[trait]
    end,
    setMutualExclusive = function(left, right)
        definitions[left].exclusions[right] = true
        definitions[right].exclusions[left] = true
    end,
}
Events = { OnGameBoot = { Add = function() end } }
getText = function(key) return "Localized " .. tostring(key) end

PsychopatzCore = {}
dofile(ROOT .. "PsychopatzTraitRegistry.lua")
local Traits = PsychopatzCore.Traits
local ok = Traits.RegisterCatalog("Example", {
    { id = "Example_A", resource = "example:a", cost = 2,
        uiName = "UI_A", uiDescription = "UI_A_Description" },
    { id = "Example_B", resource = "example:b", cost = 0,
        uiName = "UI_B", uiDescription = "UI_B_Description" },
}, { { "Example_A", "Example_B" } })
assertEqual(ok, true, "catalog registration")
assertEqual(#Traits.GetDefinitions("Example"), 2, "catalog definitions")
assertEqual(definitions[Traits.EngineTraits.Example_A].cost, 2,
    "vanilla cost retained")
assertEqual(definitions[Traits.EngineTraits.Example_A].name,
    "Localized UI_A", "trait label localized before engine registration")
assertEqual(definitions[Traits.EngineTraits.Example_A]
    .exclusions[Traits.EngineTraits.Example_B], true,
    "mutual exclusion registered")

local known = {
    values = { Traits.EngineTraits.Example_A },
    size = function(self) return #self.values end,
    get = function(self, index) return self.values[index + 1] end,
}
local player = {
    getCharacterTraits = function()
        return { getKnownTraits = function() return known end }
    end,
}
local selected, reason = Traits.ReadPlayer(player, "Example")
assertEqual(reason, "ready", "player traits synchronized")
assertEqual(selected.Example_A, true, "selected trait read")
assertEqual(Traits.PlayerHas(player, "example:a", "Example"), true,
    "resource alias read")

print("psychopatz_traits_smoke: ok")
