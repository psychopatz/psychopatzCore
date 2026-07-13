# PsychopatzCore

Shared Project Zomboid Build 42 library for Psychopatz mods.

The first release provides:

- owner-authorized special commands
- the Psychopatz admin control window and night-vision helper
- a registerable debug hub used by Dynamic Trading and Psychopatz NPC Core

Mods can add a launcher with `PsychopatzCore.DebugHub.RegisterTool(definition)`.

## Shared responsive UI

Client mods can build consistent, resolution-aware windows on the Core UI layer:

```lua
require "PsychopatzCore/UI/PsychopatzUI"

local UI = PsychopatzCore.UI
local bounds = UI.Layout.ResolveWindow({
    width = 900,
    height = 620,
    minWidth = 520,
    minHeight = 360,
})
```

Use `PsychopatzWindow` as the base class and implement `onResponsiveLayout()` to
place children whenever the window or game resolution changes. Shared helpers are
split by responsibility:

- `UI.Theme`: colors, typography choices, and spacing tokens
- `UI.Layout`: scale, safe window bounds, flow wrapping, splits, and clipping
- `UI.CreateButton`, `UI.CreateList`, and `UI.CreatePanel`: themed controls
- `PsychopatzWindow`: resizable, screen-safe shared window base

Controls should be created once in `createChildren()` and repositioned in
`onResponsiveLayout()`:

```lua
function MyWindow:onResponsiveLayout()
    local content = self:getContentRect({ top = 56, bottom = 48 })
    local columns = PsychopatzCore.UI.Layout.Split(content, {
        firstRatio = 0.4,
        breakpoint = 760,
    })
    PsychopatzCore.UI.Layout.SetBounds(self.leftList,
        columns.first.x, columns.first.y,
        columns.first.width, columns.first.height)
end
```
