# PsychopatzCore preview framework

PsychopatzCore's preview framework is the shared client-side inspection surface
for Psychopatz mods. It separates four responsibilities:

1. A domain provider observes and describes its own data.
2. Core validates the immutable snapshot boundary.
3. Core builds one bounded render plan and owns the native frame hook.
4. The generic preview hub presents providers, frozen records, and settings.

The framework is diagnostic only. A preview can show what a client currently
sees, but it must not be treated as authority for multiplayer actions.

## Lifecycle and performance contract

Provider registration is cheap. It does not create a session, load the world
drawer, install an event callback, or scan the world.

The normal lifecycle is:

```lua
local Preview = require "PsychopatzCore/Preview/PC_Preview"

Preview.RegisterProvider({
    id = "my-mod.perception",
    source = "My Mod",
    title = "My perception",
    description = "Client-local inspection",
    refreshSnapshot = function(options)
        -- Scan only here, never from Render or OnPreUIDraw.
        return buildPrimitiveSnapshot(options)
    end,
    getSettings = function() return Settings.All() end,
    getSettingsRevision = function() return Settings.GetRevision() end,
    layers = {
        {
            id = "objects",
            kind = "object",
            settingKey = "showObjects",
            tag = "object",
            priority = 10,
        },
    },
})
```

The generic hub calls `refreshSnapshot` only when the user presses **Refresh
Snapshot**. Settings re-filter the existing frozen snapshot; they never start
another scan. The overlay can remain enabled after the window closes, using its
last snapshot. Disabling a provider removes its snapshot and releases Core's
single shared `OnPreUIDraw` callback when no other provider needs it.

Providers should keep their own scan bounded. Core additionally caps snapshots
at 4,096 objects and 256 zones, and caps the default render plan at 32 object
tiles, 8 zones, and 16 tooltip lines. A provider can lower or raise the render
caps within Core's safe limits through `maxRenderObjects` and
`maxRenderZones`.

## Snapshot boundary

`PC_PreviewSnapshot` accepts only primitive values. Numbers, strings, booleans,
and bounded plain tables are copied; functions, userdata, Java objects, and
metatables are discarded. Objects need `x`, `y`, and `z`. Zones may provide
those coordinates directly or expose `roomBounds`/`bounds`; Core derives a
center anchor for bounds-only zones.

A minimal ready snapshot is:

```lua
{
    version = 1,
    status = "READY",
    providerID = "my-mod.perception",
    origin = { x = 100, y = 200, z = 0 },
    objects = {
        {
            id = "object:1",
            x = 101, y = 200, z = 0,
            tags = { "object" },
            facts = { label = "example" },
        },
    },
    zones = {},
}
```

Do not retain `IsoObject`, `IsoGridSquare`, `IsoRoom`, or other runtime objects
inside a snapshot. Keep those references inside the explicit refresh callback
only, and convert the result to primitive data before returning it.

## Layers and provider callbacks

Layers are declarative metadata used by the generic hub and fallback renderer.
Each layer has an `id`, `kind` (`object`, `zone`, or `both`), a `tag`, optional
`settingKey`, `priority`, and color. Domain callbacks may override the generic
behavior:

- `objectVisible`, `objectPriority`, `objectColor`
- `zoneVisible`, `zonePriority`, `zoneColor`, `zoneLabel`
- `tooltipLines`
- `getOptionDefinitions`
- `objectRows`, `detailRows`, `summary`, `campPreviewRows`
- `translate` for provider-owned title, description, and layer keys

Presentation callbacks should return primitive row records such as
`{ label = "Room", value = "bedroom", tone = "success" }`. They must not
return live engine objects.

### Event-driven domain diagnostics

A provider may expose bounded diagnostics from event handlers, such as the
last client-side queue/rejection and the latest authoritative server result.
Store only primitive values at that boundary and attach a copied diagnostics
table during the provider's next explicit snapshot refresh. The generic hub
will then display the frozen result without polling, scanning, or installing a
new render hook. Closing the hub leaves the current overlay snapshot intact;
the diagnostic values remain frozen until the next refresh.

This is useful for explaining disagreements between a client preview and a
server decision, but it does not change authority. Result handlers may record
state; they must not trigger a world scan or mutate the active render plan.

## Adding a new domain

An extension such as plant perception should:

1. Add a client-local bounded observer in that mod.
2. Register a namespaced Core provider, for example
   `my-mod.plants`.
3. Return plant records with stable IDs, coordinates, tags, and primitive facts.
4. Define its layers, colors, settings, tooltip, and presentation callbacks.
5. Own its translation keys and expose a translator to Core.
6. Add a focused smoke test for registration, primitive copying, filtering,
   and hook lifecycle.

It should not add another world scanner to the shared renderer, install its own
`OnPreUIDraw` callback, or duplicate the preview window. The Hoomans perception
adapter in `ProjectHoomans` is the reference integration.

## Authority boundary

Client previews are observations and hints. Hoomans uses the same bounded
client-visible observation path for its perception snapshot and camp preview,
but the server remains authoritative when a camp task or other world action is
accepted. A `SAFE` client preview therefore means “the client found a matching
loaded room/campfire candidate,” not “the server has accepted the action.”
