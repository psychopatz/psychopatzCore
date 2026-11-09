local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = CLIENT .. "?.lua;" .. package.path

PsychopatzCore = {}
local Diagnostics = require
    "PsychopatzCore/UI/Map/PsychopatzMapMarkerDiagnostics"

assert(Diagnostics.RegisterSource("test:marker", {
    kind = "actor",
    priority = 10,
    list = function()
        return {
            {
                actorID = "actor:materialized",
                provider = "DTHoomans",
                providerState = "materialized",
                bodyID = "body:1",
                position = { x = 10, y = 20, z = 0 },
            },
            {
                id = "actor:abstract",
                provider = "DTAbstract",
                providerState = "abstract",
                position = { x = 30, y = 40, z = 0 },
            },
        }
    end,
}), "marker diagnostic source registration failed")

assert(Diagnostics.SetEnabled(true), "marker diagnostics did not enable")
local rows = Diagnostics.List()
assert(#rows == 2, "marker diagnostics did not aggregate provider rows")
assert(rows[1].source == "test:marker", "marker source was not normalized")
local summary = Diagnostics.Summarize(rows)
assert(summary.total == 2, "marker diagnostic summary count changed")
assert(summary.byKind.actor == 2, "marker diagnostic kind count changed")
assert(summary.byPresence.materialized == 1,
    "materialized marker presence was not retained")
assert(summary.byPresence.abstract == 1,
    "abstract marker presence was not retained")
assert(Diagnostics.UnregisterSource("test:marker"),
    "marker diagnostic source did not unregister")

print("psychopatz_map_marker_diagnostics_smoke: PASS")
