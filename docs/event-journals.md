# Events and journals

PsychopatzCore provides three small shared, UI-free modules:

- `PC_EventBus` performs exact-name subscribe, unsubscribe, and vararg emit.
- `PC_RingBuffer` provides O(1) bounded append and deterministic snapshots.
- `PC_JournalService` lazily creates per-subject `boundedRing` or
  `uniqueArchive` containers and exports/imports plain save-safe tables.

Core knows only event IDs, journal type IDs, subject keys, entries, and storage
policies. A consuming mod owns domain event definitions, eligibility, routing,
translation, persistence, multiplayer authority, and UI presentation. Core
never imports Project Hoomans and never automatically saves journals.

## Using the API from another mod

```lua
local Events = require "PsychopatzCore/Events/PC_EventBus"
local Journals = require "PsychopatzCore/Journal/PC_JournalService"

Journals.registerType("myothermod.history", {
    storage = "boundedRing",
    capacity = 20,
    persistent = true,
})

local function route(subjectID, itemFullType)
    Journals.append("myothermod.history", subjectID,
        "myothermod.itemFound", worldMinute(), itemFullType)
end

Events.subscribe("myothermod.itemFound", route, "myothermod.routes")

-- Called only after the authoritative gameplay mutation succeeds.
Events.emit("myothermod.itemFound", subjectID, "Base.Apple")
```

Gameplay code emits semantic events only. It must not call a journal, UI,
translation, or persistence adapter. Route modules subscribe during module
initialization, apply eligibility, and append accepted semantic arguments.
An emit with no listener performs one table lookup and allocates no event
table. A rejected route must return before `append`, preserving lazy storage.

`get` does not allocate. `getRecent` returns an empty snapshot for an absent
journal. `export` returns `nil` for an absent journal; consuming mods decide
whether and where to save the returned representation. `import` validates and
skips malformed entries. Event metadata and translations belong in one
consumer registry, not in every saved entry. Persist stable IDs such as
`Base.Apple`, then localize only while rendering.

Persistent routes should run on the gameplay authority. Clients should request
a snapshot when a relevant UI opens; they should not independently append or
receive every subject's full history. Journal failures are isolated by the
event bus so an optional listener cannot cancel the gameplay action.

For a discovery archive, use `storage = "uniqueArchive"` and optionally supply
`uniqueKey(entry)`. A future radio route can store station and conversation IDs
once without saving translated dialogue:

```lua
Journals.registerType("myothermod.radioDiscovery", {
    storage = "uniqueArchive",
    persistent = true,
    uniqueKey = function(entry)
        return tostring(entry[3]) .. ":" .. tostring(entry[4])
    end,
})
```

Avoid polling, per-subject ticks, rendered strings, unbounded histories,
high-frequency diagnostic events in player journals, and direct journal calls
from gameplay. Coalescing is intentionally deferred: a future policy or route
can coalesce before append without changing the event bus or stored metadata.
