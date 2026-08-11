local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. ROOT .. "shared/?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

dofile(ROOT .. "shared/PsychopatzCore/00_PsychopatzCore_Init.lua")

local Frequencies = PsychopatzCore.RadioFrequencies
local first = Frequencies.AllocateUnique(
    { "faction_a", "faction_b", "faction_c" },
    { namespace = "test", minimum = 90, maximum = 91, step = 0.1 }
)
equal(first.faction_a ~= first.faction_b, true,
    "different factions receive unique frequencies")
equal(first.faction_b ~= first.faction_c, true,
    "allocator avoids collisions")

local second = Frequencies.AllocateUnique(
    { "faction_a", "faction_b", "faction_c", "faction_d" },
    {
        namespace = "test",
        minimum = 90,
        maximum = 91,
        step = 0.1,
        existing = first,
    }
)
equal(second.faction_a, first.faction_a,
    "existing assignments remain stable as channels are added")
equal(second.faction_b, first.faction_b,
    "stable assignment is independent of later registrations")

Frequencies.RegisterProvider("test.provider", {
    listChannels = function()
        return {
            { id = "a", frequency = first.faction_a, name = "Alpha" },
            { id = "b", frequency = first.faction_b, name = "Bravo" },
        }
    end,
    pollEvents = function()
        return {
            {
                id = "event:a", frequency = first.faction_a,
                channelName = "Alpha", text = "Test transmission",
            },
        }
    end,
})

equal(#Frequencies.ListChannels({}), 2,
    "providers expose independently ordered channels")
equal(Frequencies.PollEvents({})[1].text, "Test transmission",
    "broadcast events are additive provider payloads")

print("psychopatz_radio_frequencies_smoke: ok")
