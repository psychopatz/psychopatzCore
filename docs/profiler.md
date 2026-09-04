# PsychopatzCore Profiler

The PsychopatzCore profiler is shared development infrastructure for observing
timers, counters, gauges, event rates, bounded history, growth, and spikes across
arbitrary Psychopatz mods. It does not assign process memory to an individual mod.

## Architecture

The tiny `PsychopatzProfilerBootstrap` is the only profiler component required by
Core in an OFF session. It reads one configuration value during startup and stops.
The shared bootstrap never requires client or server implementation files.
Thin `00_PsychopatzCore_Client_Init.lua` and
`00_PsychopatzCore_Server_Init.lua` anchors delegate to layer-specific
composition roots. Those roots register dormant role starters, and an enabled
bootstrap starts each role only after PZ has made that layer's Lua path
available.
The generic backend lives under `common/media/lua/shared`, split into a stable
entry/API, bounded-history, analysis, and snapshot modules. The Project Zomboid
bootstrap, clock, event, snapshot-file, client UI, and multiplayer adapters live
under the versioned runtime tree (`42.20` for the current Build 42 branch).

Consumer mods own only static metric names and startup instrumentation. The
backend has no Project Hoomans, Dynamic Trading, NPC, settlement, or trade logic.

## Modes and activation

Profiling defaults to `OFF`. To enable it, create `PsychopatzCore_Profiler.txt` in
the Project Zomboid Lua file area (the same area used by `getFileReader`) with:

```text
mode=DETAILED
```

Use `mode=BASIC` for current timers, counters, gauges, rates, averages, peaks,
and one-second aggregates. `DETAILED` additionally creates bounded histories,
growth analysis, warnings, self-overhead gauges, exclusive timer accounting,
and snapshot export. Profiling
is independent of PZ's generic debug setting.

Developers embedding Core can set `PSYCHOPATZ_PROFILER_MODE` to `BASIC` or
`DETAILED` before Core initializes. The global takes precedence over the file.

At runtime, `PsychopatzCore.ProfilerBootstrap.Disable()` stops Core callbacks,
network handlers, histories, metrics, warnings, samplers, and the GUI. Hot
functions and heavy modules are restored by registered cleanup hooks. An active
local bridge can enable or reconfigure the profiler again without restarting.
The desktop app never enables that bridge implicitly: when its explicit setting
is OFF, profiler changes retain the restart-based compatibility path.
If both bridge and profiler started OFF, one startup is required because strict
OFF deliberately has no recurring listener.

## Disabled mode

OFF performs one startup configuration read. Discovered profiler implementation
files immediately return at their startup guard. They do not create the profiler
API/backend table, metric registry, histories, timers, gauges, warnings, ring
buffers, snapshot writers, GUI, profiler networking, or sampling callbacks.
There is no profiler `OnTick` or recurring event. The bootstrap table, its small
set of lifecycle/configuration functions, and one dormant role-starter closure
for the active runtime layer remain loaded. The closure has no event hook and is
never called while OFF. A consumer may
also load its tiny startup integration gate; Project Hoomans allocates no
profiler metric state and installs no wrappers when that gate sees OFF.

No snapshot file is created, truncated, polled, or updated while OFF.

## Public API

The active backend is `PsychopatzCore.Profiler`:

```lua
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
if Bootstrap.IsEnabled() then
    local Profiler = PsychopatzCore.Profiler
    Profiler.RegisterNamespace("FutureMod", { displayName = "Future Mod" })
    update = Profiler.Wrap("FutureMod.Director.Update", update)
    Profiler.SetGauge("FutureMod.Cache.Size", cacheSize)
    Profiler.RecordRate("FutureMod.Network.Requests", 1)
end
```

Available operations are `RegisterNamespace`, `Begin`, `Finish`, `Wrap`,
`Increment`, `Decrement`, `SetGauge`, `RecordRate`, `ConfigureMetric`,
`RegisterSampler`, `ResetPeaks`, `ResetHistories`, `ResetWarnings`,
`BuildSnapshot`, and `ExportSnapshot`.

Every metric name must contain a namespace followed by a path, such as
`FutureMod.Market.Refresh`. Registration supplies friendly metadata but is not
required. Keep names in static locals/upvalues; do not concatenate names inside
per-frame loops.

New feature integrations should register once through
`PsychopatzProfilerFeatureRegistry` instead of duplicating enable/disable and
capture-section checks:

```lua
local Features = require "PsychopatzCore/Profiler/PsychopatzProfilerFeatureRegistry"
Features.Register({
    id = "FutureMod.World", namespace = "FutureMod", displayName = "Future Mod",
    sections = { "performance" },
    samplers = {{ id = "population", callback = function(Profiler)
        Profiler.SetGauge("FutureMod.World.Population", World.Count())
    end }},
    install = function(Profiler, config)
        local original = World.Update
        World.Update = Profiler.Wrap("FutureMod.World.Update", original)
        return function() World.Update = original end
    end,
})
```

The registry owns section gating, runtime reconfiguration, sampler/provider
unregistration, and cleanup. Require it only after the tiny bootstrap gate says
profiling or live control is active. In an OFF startup it is not loaded and it
installs no event callbacks, samplers, providers, wrappers, or per-frame checks.

`RegisterSampler` is useful for logical state owned by gameplay. Its callback is
called only by an active profiler sample, normally once per second. The
Project Zomboid adapter uses the tick event only for requested sub-second
intervals; one-second and slower intervals use the lower-frequency event.
The profiler must never become canonical gameplay state.

Timer `msPerSec`, `totalMs`, `lastMs`, and `peakMs` are inclusive: nested
instrumented calls are included in their parent. The corresponding
`selfMsPerSec`, `selfTotalMs`, `lastSelfMs`, and `selfPeakMs` fields exclude
nested instrumented calls, making them suitable for summing CPU attribution.
Project Hoomans wrappers also use the protected wrapper option so a callback
error unwinds its timer stack before the error is rethrown.

Timers reuse metric and stack storage. Rates aggregate within intervals rather
than retaining individual events. DETAILED histories use fixed circular buffers
of 300 one-second samples by default. Old samples are overwritten.

## Project Hoomans integration

Project Hoomans is the first consumer. Its `42.20` integration wraps real shared
systems at startup: server update, Director and population pumps, scheduled jobs,
spatial rebuild, world census, perception/decision/pathing boundaries, and the
NPC scheduler. Once-per-second samplers expose actual NPC/live-body, world,
active-aggro, scheduler, abstract-group, settlement, and dirty-record counts.
The core adapter also exposes optional `ProjectZomboid` gauges for the game's
average FPS, CPU/GPU frame times and waits, target/UI/lighting FPS, and the
bounded local performance, network, and game statistics tables used by the
stock admin statistics UI. Missing engine APIs are omitted rather than
reported as zero.

The former Project Hoomans-local timing collector was removed. Instrumentation
names and observation points remain in Project Hoomans; storage and analysis are
owned exclusively by PsychopatzCore.

## In-game UI and multiplayer

With profiling enabled, the owner opens the existing Psychopatz admin control
(`R`) and launches **Psychopatz Profiler** from the Debug Hub. The GUI module is
not required until that action is selected. Closed windows do no refresh or draw
work. An open window refreshes about once per second and provides generic
Overview, CPU, Metrics, Growth, Network, Events, and History views plus reset and
manual export actions.

Dedicated servers install one profiler command handler only while profiling is
active. An authorized Core owner client requests a compact server snapshot only
while the profiler window is open, at most once every two seconds. Closing the
window stops requests; stopping profiling removes both client and server command
handlers. Ordinary players cannot request server profiler data.

## Snapshots

DETAILED mode writes `PsychopatzCore_Profiler_latest.json` through PZ's writable
Lua-file API, normally in the user's `Zomboid/Lua` area. The exact base directory
is controlled by Project Zomboid. The schema is versioned (`profilerVersion: 1`)
and groups generic timers, counters, gauges, and rates beneath arbitrary
namespaces. History buffers are never exported.

Project Zomboid's portable Lua writer does not expose a cross-platform atomic
replace operation. The writer therefore replaces the compact latest file
directly. The external reader treats malformed/partial reads as transient and
keeps the last valid snapshot. Snapshot failures affect observability only.

## External Python profiler

See `tools/profiler/README.md`. The application separates `ProcessMonitor`,
`SnapshotReader`, `HistoryStore`, `CsvRecorder`, and `ProfilerModel` from the Tk
UI. It uses `psutil` rather than `/proc`, `ps`, WMI, PowerShell, or platform shell
commands. Histories and warnings are bounded.

Process RSS and optional JVM values belong to the entire **Project Zomboid
process/JVM**, never to Project Hoomans or another mod. Correlate those values
with logical gauges to identify suspects. Messages such as “possible continuous
growth” are observations, not proof of a memory leak.

### Project Hoomans ModData diagnostics

DETAILED mode adds a bounded, value-redacted Project Hoomans diagnostic. It
separately summarizes persisted `PNC_*` GlobalModData tables, live runtime NPC
records, and inventory/runtime-inventory structures. The report includes shape
estimates, table/entry/string counts, inventory item/container/op-log counts,
truncation status, and the largest normalized paths.

The scan runs at most once per configured ModData interval (60 seconds by
default) and caps each section at 2,000 nodes,
depth 12, and 30 retained paths. Dynamic identifiers and raw values are not
exported. Estimated bytes are useful for comparisons and locating growth; they
are not exact JVM heap, serialized, compressed-save, or disk byte counts. The
persisted, runtime, and inventory sections overlap and must not be added together.

The desktop GUI displays this data under **PROJECT HOOMANS MODDATA BLOAT
ANALYSIS**. It also maintains a compact machine-readable report at
`~/Zomboid/Lua/PsychopatzCore_Profiler_LLM_latest.json` and provides an
**Export LLM Report** button. The LLM report keeps the top 20 timers, bounded
gauges, warnings, ModData diagnostics, and one process sample while excluding
raw save content.

The desktop workspace uses separate **Performance**, **ModData Summary**, and
**NPC Data Inspector** tabs. Tree headings are clickable and sort using their
underlying numeric values rather than formatted text; the initial Performance
view places the highest timer latency first. The NPC inspector identifies records
by display name and exposes bounded runtime and persisted content locally (up to
50 NPCs, 500 nodes per view, depth 8, and 160 characters per string). Per-NPC
contents are deliberately excluded from the automatic LLM report.

Expansion state, selection, and scroll position survive periodic refreshes.
**Pause Updates** freezes all desktop-side sampling, rendering, CSV rows, and
LLM report writes while leaving the current snapshot available for inspection.
It does not stop the already-running in-game Lua profiler; use OFF to remove its
callbacks and instrumentation. Disable the independent bridge as well when its
bounded control polling is not needed.

Project Hoomans server instrumentation also breaks the outer update and record
broadcast timings into subsystem phases. Server metrics cover player lifecycle,
factions, needs, engine path planning, body cleanup/audits, materialization,
zombie aggro, social encounters, and per-NPC presence/health/stamina/animation/
spatial/scheduling work. Network broadcast metrics separately time roster
queueing, recipient discovery, payload construction, and payload sending.

## Known limitations

- Exact per-mod RAM attribution is unavailable.
- Only code routed through registered/wrapped boundaries is timed.
- The adapter prefers the public GameTime server clock, which is a monotonic
  millisecond conversion, and falls back to wall-clock milliseconds when that
  clock is unavailable. Backward movement is clamped; the engine's private
  nanosecond clock is not accessed through unsupported reflection.
- The in-game History view reports bounded series rather than rendering a
  high-frequency graph; the external GUI provides the lightweight RSS graph.
- Snapshot replacement is reader-tolerant rather than atomically renamed due to
  the portable PZ Lua file API.
- Live enable requires an already-active profiler activation probe or bridge.
  When both started OFF, strict zero-recurring-overhead behavior means there is
  intentionally no listener and the first enable requires a game startup.
