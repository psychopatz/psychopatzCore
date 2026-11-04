local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

local actors = {
    {
        actorID = "actor:map:a",
        label = "Ada",
        position = { x = 100, y = 200, z = 0 },
        journey = {
            route = {
                points = {
                    { x = 100, y = 200, z = 0 },
                    { x = 300, y = 400, z = 0 },
                },
            },
        },
    },
    {
        actorID = "actor:map:b",
        label = "Ben",
        position = { x = 500, y = 600, z = 0 },
    },
}

local selected
local highlighted
local tracked
local refreshes = 0
local Client
Client = {
    Selection = { selectedActorID = nil },
    RequestActorsIfDue = function(interval)
        assert(interval == 500, "actor map refresh cadence changed")
        refreshes = refreshes + 1
        return true
    end,
    ListActors = function()
        return actors
    end,
    SetSelected = function(actorID)
        selected = actorID
        Client.Selection.selectedActorID = actorID
        return Client.Selection
    end,
    SetHighlighted = function(actorID)
        highlighted = actorID
        return true
    end,
    SetTracked = function(actorID)
        tracked = actorID
        return true
    end,
    GetTracked = function()
        if tracked == actors[1].actorID then return actors[1] end
        if tracked == actors[2].actorID then return actors[2] end
        return nil
    end,
}
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
] = function() return Client end

local hoverUpdates = 0
local hoverHides = 0
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"
] = function()
    return {
        Update = function(_, entry)
            hoverUpdates = hoverUpdates + 1
            assert(entry.actorID == "actor:map:a",
                "hover used wrong canonical actor")
            return true
        end,
        Hide = function()
            hoverHides = hoverHides + 1
            return true
        end,
    }
end

local registered = {
    overlays = {},
    events = {},
    contexts = {},
}
local Host = {
    Overlays = {
        Register = function(id, definition)
            registered.overlays[id] = definition
            return true
        end,
    },
    Events = {
        Register = function(id, definition)
            registered.events[id] = definition
            return true
        end,
    },
    Contexts = {
        Register = function(id, definition)
            registered.contexts[id] = definition
            return true
        end,
    },
}
package.preload[
    "PsychopatzCore/UI/Map/PsychopatzMapHost"
] = function() return Host end

PsychopatzCore = {}
UIFont = { Small = {} }

local ActorMap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"

local markers = ActorMap.BuildMarkers()
assert(#markers == 2,
    "Core actor map did not expose every canonical actor")
assert(markers[1].actorID == "actor:map:a",
    "actor map ordering/identity changed")

assert(ActorMap.RegisterDecorator("test", {
    priority = 10,
    decorate = function(entry, style)
        if entry.actorID == "actor:map:a" then
            style.label = "Ada [Trader]"
            style.size = 11
            style.icon = { id = "trader", glyph = "T" }
            style.badge = {
                factionID = "faction:map:test",
                glyph = "F",
                color = { r = 0.8, g = 0.4, b = 0.2, a = 1 },
            }
        end
        return style
    end,
}), "actor map decorator registration failed")

markers = ActorMap.BuildMarkers()
assert(markers[1].label == "Ada [Trader]",
    "actor map decorator did not enrich presentation")
assert(markers[1].size == 11,
    "actor map decorator size was ignored")
assert(markers[1].icon and markers[1].icon.glyph == "T",
    "actor map decorator icon contract was ignored")
assert(markers[1].badge and markers[1].badge.factionID
        == "faction:map:test",
    "actor map decorator faction badge contract was ignored")
assert(#markers == 2,
    "one canonical actor produced more than one actor marker")

local rects = {}
local lines = {}
local texts = {}
local map = {
    width = 1000,
    height = 1000,
    mouseX = 10,
    mouseY = 20,
    getMouseX = function(self) return self.mouseX end,
    getMouseY = function(self) return self.mouseY end,
    mapAPI = {
        worldToUIX = function(_, x) return x / 10 end,
        worldToUIY = function(_, _, y) return y / 10 end,
    },
    javaObject = {
        DrawLine = function(_, _, x1, y1, x2, y2)
            lines[#lines + 1] = { x1, y1, x2, y2 }
        end,
    },
    drawRect = function(_, x, y, w, h)
        rects[#rects + 1] = { x = x, y = y, w = w, h = h }
    end,
    drawRectBorder = function() end,
    drawTextCentre = function(_, text)
        texts[#texts + 1] = text
    end,
}

local overlay = assert(
    registered.overlays["PsychopatzCore:SurvivorWorldActors"],
    "Core actor map overlay not registered"
)
overlay.render(map)
assert(#rects == 2,
    "Core actor map did not render one dot per canonical actor")
assert(highlighted == "actor:map:a",
    "Core actor hover did not publish canonical identity")
assert(hoverUpdates == 1,
    "Core actor hover portrait was not invoked")

local event = assert(
    registered.events["PsychopatzCore:SurvivorWorldActors"],
    "Core actor map events not registered"
)
assert(event.onMouseDown(map, 10, 20) == true,
    "Core actor marker was not selectable")
assert(selected == "actor:map:a",
    "Core actor selection lost actor identity")

map.mouseX = 0
map.mouseY = 0
overlay.render(map)
assert(#lines >= 1,
    "selected actor did not render canonical journey route")
local foundLabel = false
for _, text in ipairs(texts) do
    if text == "Ada [Trader]" then foundLabel = true end
end
assert(foundLabel,
    "selected actor did not render decorated label")

local contextDef = assert(
    registered.contexts["PsychopatzCore:SurvivorWorldActors"],
    "Core actor tracking context not registered"
)
assert(contextDef.available(map, 10, 20) == true,
    "Core actor context could not hit marker")
local options = {}
local context = {
    addOption = function(_, title, _, callback)
        options[#options + 1] = {
            title = title,
            callback = callback,
        }
    end,
}
assert(contextDef.augment(map, context, 10, 20) == true,
    "Core actor context did not add tracking")
assert(#options == 1,
    "Core actor context should own one tracking action")
options[1].callback()
assert(tracked == "actor:map:a",
    "Core actor tracking lost actor identity")

event.onClose(map)
assert(selected == nil, "map close did not clear selection")
assert(highlighted == nil, "map close did not clear highlight")
assert(tracked == "actor:map:a",
    "map close unexpectedly cleared persistent tracking")
assert(hoverHides >= 1, "map close did not hide hover")
assert(refreshes >= 1, "Core actor map never refreshed projections")

print("psychopatz_survivor_world_actor_map_smoke: PASS")
