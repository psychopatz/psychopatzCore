local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Names = require "PsychopatzCore/Actors/PsychopatzActorNames"

local first = Names.ResolveNickname("Patrick", "identity-patrick")
equal(first, Names.ResolveNickname("Patrick", "identity-patrick"),
    "nickname resolution is deterministic")
truthy(first == "Pat" or first == "Paddy" or first == "Rick",
    "nickname stays within the forename alias set")
equal(Names.ResolveNickname("Patrick", "identity-patrick", {
    nickname = "Patch",
}), "Patch", "explicit nickname overrides generated alias")
equal(Names.ResolveNickname("Ben", "identity-ben"), "Ben",
    "short forename remains a valid nickname")

equal(Names.FormatDisplayName("Patrick Parker", "Pat"),
    "Patrick Parker (Pat)",
    "known nickname is appended to the full display name")
equal(Names.FormatDisplayName("Patrick", "Patrick"),
    "Patrick",
    "full-name duplicate nickname is not appended")

local parts = Names.ResolveParts({
    id = "npc-patrick",
    firstName = "Patrick",
    surname = "Parker",
}, { resolveNickname = true, includeNickname = true })
equal(parts.fullName, "Patrick Parker", "identity parts preserve full name")
equal(parts.displayName, "Patrick Parker (" .. parts.nickname .. ")",
    "identity parts expose the formatted display name")
local parsed = Names.ResolveParts({
    displayName = "Patrick Parker (Pat)",
}, { resolveNickname = true })
equal(parsed.fullName, "Patrick Parker",
    "formatted display names keep surname separate from nickname")
equal(parsed.nickname, "Pat",
    "formatted display names recover the nickname facet")

local generated = Names.Generate("identity-generated", false, "survivor", {
    saveSeed = "save-generated",
    namespace = "test.actor.names",
})
truthy(string.find(generated, "%S+ %S+"),
    "Core name generation supplies forename and surname")

local catalog = Names.CatalogInfo()
truthy(catalog.maleFirstCount > 0 and catalog.femaleFirstCount > 0
    and catalog.surnameCount > 0,
    "Core exposes a usable name catalog")

print("psychopatz_actor_names_smoke: PASS")
