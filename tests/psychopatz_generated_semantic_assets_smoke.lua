local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

local lexicon = require "PsychopatzCore/Semantics/Generated/Lexicon/Catalog"
assert(type(lexicon) == "table", "generated Core lexicon must load")
assert(type(lexicon.aliasesByConcept) == "table",
    "generated Core lexicon must expose aliasesByConcept")
assert(type(lexicon.verbFormsBySurface) == "table",
    "generated Core lexicon must expose verbFormsBySurface")
assert(type(lexicon.aliasesByConcept.FETCH) == "table",
    "generated Core lexicon must retain FETCH aliases")
assert(type(lexicon.verbFormsBySurface["following"]) == "table",
    "generated Core lexicon must retain reviewed morphology")

local modules = {
    "PsychopatzCore/Semantics/Generated/Conversation/Patterns/Common/GreetingWhatsUp",
    "PsychopatzCore/Semantics/Generated/Conversation/Patterns/Common/Identity",
    "PsychopatzCore/Semantics/Generated/Conversation/Patterns/Common/WeatherNeeds",
    "PsychopatzCore/Semantics/Generated/Conversation/Patterns/Common/WellbeingActivity",
}

for _, module in ipairs(modules) do
    local patterns = require(module)
    assert(type(patterns) == "table" and #patterns > 0,
        "generated Core parser pattern module must load: " .. module)
    for _, pattern in ipairs(patterns) do
        assert(type(pattern.id) == "string" and pattern.id ~= "",
            "generated Core parser pattern requires an ID")
        assert(type(pattern.match) == "table",
            "generated Core parser pattern requires match rules")
    end
end

print("psychopatz_generated_semantic_assets_smoke: ok")
