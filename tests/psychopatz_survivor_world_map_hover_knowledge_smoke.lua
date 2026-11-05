local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local requestCount = 0
local targetCount = 0
local visibleCount = 0

local Client = {
    GetActorKnowledge = function(actorID)
        if tostring(actorID) == "actor:hover:unknown" then
            return {
                actorID = actorID,
                state = "unknown",
                nameKnown = false,
            }
        end
        return {
            actorID = actorID,
            state = "known",
            nameKnown = true,
        }
    end,
    RequestActorKnowledge = function(actorID)
        requestCount = requestCount + 1
        assert(actorID == "actor:hover:unknown",
            "knowledge request used the wrong actor")
        return true, "queued"
    end,
    GetPortraitSpec = function(entry)
        return { actorID = entry.actorID, faceOnly = true }
    end,
}

package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
] = function()
    return Client
end

package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHoverCard"
] = function()
    return {
        new = function()
            return {
                height = 152,
                initialise = function() end,
                instantiate = function() end,
                setContext = function() end,
                setTarget = function()
                    targetCount = targetCount + 1
                    return true
                end,
                setCardPosition = function() end,
                setVisible = function(_, value)
                    if value == true then visibleCount = visibleCount + 1 end
                end,
            }
        end,
    }
end

PsychopatzCore = {}

local Hover = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"

local map = {
    width = 800,
    addChild = function(self, panel)
        self.child = panel
    end,
}

local unknown = {
    actorID = "actor:hover:unknown",
    label = "Unknown survivor",
}
assert(Hover.Update(map, unknown, 100, 100, {}) == false,
    "unknown actor map hover exposed a portrait card")
assert(requestCount == 1,
    "unknown actor map hover did not request bounded knowledge")
assert(targetCount == 0 and visibleCount == 0,
    "unknown actor map hover instantiated or displayed actor details")

local known = {
    actorID = "actor:hover:known",
    label = "Known survivor",
}
assert(Hover.Update(map, known, 100, 100, {}) == true,
    "known actor map hover did not display the shared portrait card")
assert(targetCount == 1 and visibleCount == 1,
    "known actor map hover did not bind the shared portrait card")

print("psychopatz_survivor_world_map_hover_knowledge_smoke: PASS")
