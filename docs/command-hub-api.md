# PsychopatzCore command hub

PsychopatzCore exposes a shared command catalog at
`PsychopatzCore.UI.CommandHub`. A client mod can register its root button and
children without importing Project Hoomans:

```lua
require "PsychopatzCore/UI/PsychopatzUI"
local Hub = require "PsychopatzCore/UI/PsychopatzCommandHub"

Hub.RegisterButton({
    id = "MyMod.tools",
    source = "MyMod",
    order = 40,
    titleKey = "UI_MyMod_Tools",
    titleFallback = "Tools",
})

Hub.RegisterButton({
    id = "MyMod.tools.repair",
    source = "MyMod",
    parentID = "MyMod.tools",
    order = 10,
    titleKey = "UI_MyMod_Repair",
    titleFallback = "Repair",
    onClick = function(button, host)
        -- Open the mod's own window or start its action here.
    end,
})

-- The normal entry point is the Core-owned host.
Hub.Open()
```

To expose the shared Core settings screen as a button, use
`Hub.RegisterSettingsButton({ order = 30 })`. The helper supplies the
standard settings callback and can still be overridden with a custom
`onClick`.

Root buttons are ordered with `Hub.SetOrder({ ... })`; all other roots fall
back to their numeric `order` and then their id. Child buttons use the same
ordering rule. `visible`, `enabled`, and `selected` may be booleans or
functions receiving `(definition, host)`.

Shared appearance helpers are available through `Hub.Options`, including
`GetOpacity`, `SetOpacityPercent`, `GetBranch`, `SetBranch`,
`ApplyRegisteredOpacity`, and `ApplyGeometry`. Mods that create child windows
can register them with `Hub.Options.RegisterTarget(id, window)` so the shared
settings are applied consistently. `Hub.OpenSettings(host)` opens the
reusable Core settings window with the position, dimensions, opacity slider,
and left/right branch controls.

Use a namespaced `id` and `source` for every contribution. A mod can remove
its own contribution during teardown with `Hub.UnregisterSource("MyMod")`.

Window-owning adapters can observe `opened`, `shown`, `prerender`, and
`closed` events with `Hub.RegisterObserver("MyMod.CommandHub", callback)`.
Use the `closed` event to hide or dispose any mod-specific child windows so
the shared host remains the single lifetime boundary.
