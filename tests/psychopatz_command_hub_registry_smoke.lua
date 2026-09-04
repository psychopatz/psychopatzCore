local ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    .. "PsychopatzCore/UI/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PsychopatzCore = { UI = {} }
local Registry = dofile(ROOT .. "PsychopatzCommandHubRegistry.lua")

local clicked
Registry.RegisterButton({
    id = "Example.dashboard",
    source = "ExampleMod",
    order = 20,
    titleFallback = "Dashboard",
})
Registry.RegisterButton({
    id = "Example.tools",
    source = "ExampleMod",
    order = 10,
    titleFallback = "Tools",
})
Registry.RegisterButton({
    id = "Example.tools.lumber",
    source = "ExampleMod",
    parentID = "Example.tools",
    order = 20,
    titleFallback = "Lumber",
    onClick = function() clicked = true end,
})
Registry.RegisterButton({
    id = "Example.tools.fishing",
    source = "ExampleMod",
    parentID = "Example.tools",
    order = 10,
    titleFallback = "Fishing",
})

Registry.SetOrder({ "Example.tools", "Example.dashboard" })
equal(Registry.All()[1].id, "Example.tools", "manual root order")
equal(Registry.All()[2].id, "Example.dashboard", "manual root order")
equal(Registry.GetChildren("Example.tools")[1].id,
    "Example.tools.fishing", "child order")
equal(Registry.GetChildren("Example.tools")[2].id,
    "Example.tools.lumber", "child order")
equal(Registry.GetAction("Example.tools", "Example.tools.lumber").onClick ~= nil,
    true, "child action lookup")
equal(Registry.UnregisterSource("ExampleMod"), 4,
    "source cleanup removes roots and descendants")
equal(Registry.Get("Example.tools"), nil, "source cleanup")

Registry.RegisterButton({ id = "Mixed.parent", source = "Owner" })
Registry.RegisterButton({
    id = "Mixed.child", source = "Other", parentID = "Mixed.parent",
})
equal(Registry.UnregisterSource("Owner"), 1,
    "owner cleanup count")
equal(Registry.Get("Mixed.child").parentID, nil,
    "foreign child was not promoted during owner cleanup")

print("psychopatz_command_hub_registry_smoke: ok")
