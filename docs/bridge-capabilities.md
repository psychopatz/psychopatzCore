# Generic bridge capabilities

PsychopatzCore's bridge is transport-agnostic at the mod boundary. Mods may
register LLM/tool descriptors without coupling the Core bridge to a specific
mod, and may publish arbitrary bounded snapshot/event packets through named
channels.

## Tool catalogs

Register a tool after the bridge is ready:

```lua
PsychopatzCore.Bridge.RegisterTool("example.mod", "inspect", {
    type = "function",
    ["function"] = {
        name = "inspect",
        description = "Inspect the current target.",
        parameters = { type = "object", properties = {} },
    },
}, { kind = "llm_tool" })
```

The runtime state advertises `tool_catalog_id` and `tool_catalog_version`.
P BrainZ requests `psychopatzcore.bridge.toolCatalog` only when that catalog
ID is not already cached. Chat packets should send only the allowed
`available_tool_ids` for the current turn.

Core command handlers remain authoritative. A catalog controls what may be
presented to a model; it does not grant permission to execute a command.

## Snapshot/event channels

```lua
local bridge = PsychopatzCore.Bridge
bridge.RegisterPacketChannel("example.mod", "state", { maxEvents = 64 })
bridge.SetPacketSnapshot("example.mod", "state", { revision = 1 })
bridge.PublishPacket("example.mod", "state", {
    packet_type = "activity_changed", activity = "patrol",
})
```

P BrainZ can poll the generic `psychopatzcore.bridge.pollPackets` command with
subscriptions containing `namespace`, `channel`, `after`, and an optional
`include_snapshot`. Each event has a monotonically increasing sequence. When
the bounded event history has been overrun, the response sets `gap = true` and
includes the latest snapshot so the consumer can resynchronize.

Use snapshots for rarely changing state and events for changes. Keep volatile
data in memory; do not turn high-frequency telemetry into NPC memories.
