# Custom radio channels

`PsychopatzCore.CustomRadio` provides native Project Zomboid radio channels,
device presets, tuned-channel listeners, and event-driven broadcasts.

## Register a channel

Register channels from shared Lua so both the server and clients see the same
definition. Frequencies use Project Zomboid's integer representation: `144200`
is displayed as `144.2 MHz`.

```lua
require "PsychopatzCore/Radio/CustomChannels/PsychopatzCustomRadio"

PsychopatzCore.CustomRadio.RegisterChannel({
    id = "my_mod.events",
    guid = "MY-MOD-EVENTS-001",
    frequency = 144200,
    name = "Event Watch",
    nameKey = "UI_MyMod_EventWatch",
    category = "Amateur",
    autoPreset = true,
})
```

Core registers this with the native radio script manager. When a compatible
radio panel opens, `autoPreset` adds it to the vanilla preset list without
changing the current channel or replacing an existing preset.

## Add broadcast variety

Register message packs from server Lua. Packs with the highest matching
priority form the random pool. This lets specific packs such as `looter` win
over a generic mobile-group fallback.

```lua
PsychopatzCore.CustomRadio.RegisterMessagePack("my_mod.treasure", {
    channel = "my_mod.events",
    eventType = "treasure",
    priority = 50,
    matches = function(context)
        return context.danger ~= "extreme"
    end,
    messages = {
        { lines = {
            "<bzzt>",
            "Supply cache reported near {location}.",
            "<fzzt>",
        } },
        { lines = {
            "Anyone listening: check {location} before nightfall.",
        } },
    },
})
```

Any `{token}` is expanded from the event context. A line may also be a table
with `text`, `r`, `g`, `b`, `airTime`, and `effects` fields.

## Air an event

Call this from authoritative server code:

```lua
PsychopatzCore.CustomRadio.AirEvent("my_mod.events", "treasure", {
    location = "grid 42, 18",
    danger = "moderate",
})
```

The selected lines are played through a native `RadioBroadCast`. Existing
vanilla channels and their current broadcasts are never modified.

## React when a player is tuned in

Register listeners from client Lua:

```lua
PsychopatzCore.CustomRadio.RegisterListener(
    "my_mod.events",
    "my_mod.listener",
    function(context)
        -- context includes player, device, deviceData, channel, and timestamp.
        return true
    end
)
```

Core checks only active radios in local players' hands or attachment slots.
It does not scan NPCs or every inventory item.
