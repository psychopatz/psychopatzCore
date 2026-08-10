# Reusable character traits

`PsychopatzCore.Traits` centralizes Build 42 character-trait registration,
mutual exclusions, zero-point character-creation visibility, and authoritative
trait reads. Feature mods own their trait data and register it as a catalog.

```lua
require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore.Traits.RegisterCatalog("MyMod.StartingTraits", {
    {
        id = "MyMod_Example",
        resource = "mymod:example",
        cost = 2,
        uiName = "UI_MyMod_Trait_Example",
        uiDescription = "UI_MyMod_Trait_Example_Description",
    },
}, {})
```

On the authority side, inspect the synchronized traits with:

```lua
local selected, reason = PsychopatzCore.Traits.ReadPlayer(
    player,
    "MyMod.StartingTraits"
)
```

`selected` is `nil` with `traits_not_ready` while an online player is still
synchronizing. Retry later instead of recording an empty selection. Once it is
ready, the result is a set keyed by the catalog's stable trait IDs.

Positive and negative point traits use the vanilla character-creation lists.
The Core client adapter only supplements Build 42's omission of zero-point
traits, while leaving vanilla selection, point accounting, and exclusions in
control.
