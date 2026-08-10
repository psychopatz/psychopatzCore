require "OptionScreens/CharacterCreationProfession"
if not PsychopatzCore or not PsychopatzCore.Traits then
    require "PsychopatzCore/00_PsychopatzCore_Init"
end

local Traits = PsychopatzCore.Traits

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
    local index
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
                    list:addUniqueItem(definition:getLabel(), definition,
                        definition:getDescription())
                elseif list.addItem then
                    list:addItem(definition:getLabel(), definition,
                        definition:getDescription())
                end
                added = added + 1
            end
        end
    end
    return added
end

if CharacterCreationProfession
    and CharacterCreationProfession.populateTraitList
    and not CharacterCreationProfession._psychopatzZeroPointTraitsPatched
then
    CharacterCreationProfession._psychopatzZeroPointTraitsPatched = true
    local original = CharacterCreationProfession.populateTraitList
    function CharacterCreationProfession:populateTraitList(list)
        local result = original(self, list)
        Traits.AppendZeroPointTraits(self, list)
        return result
    end
end

return Traits
