# PsychopatzCore Profiler

The PsychopatzCore profiler is shared development infrastructure for observing
timers, counters, gauges, event rates, bounded history, growth, and spikes across
arbitrary Psychopatz mods. It does not assign process memory to an individual mod.

## Architecture

The tiny `PsychopatzProfilerBootstrap` is the only profiler component required by
Core in an OFF session. It reads one configuration value during startup and stops.
The generic backend lives under `common/media/lua/shared`, split into a stable
entry/API, bounded-history, analysis, and snapshot modules. The Project Zomboid
bootstrap, clock, event, snapshot-file, client UI, and multiplayer adapters live
under the versioned `42.19` runtime tree.

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
growth analysis, warnings, self-overhead gauges, and snapshot export. Profiling
is independent of PZ's generic debug setting.

Developers embedding Core can set `PSYCHOPATZ_PROFILER_MODE` to `BASIC` or
`DETAILED` before Core initializes. The global takes precedence over the file.

At runtime, `PsychopatzCore.ProfilerBootstrap.Disable()` stops Core callbacks,
network handlers, histories, metrics, warnings, samplers, and the GUI. Hot
functions and heavy modules are deliberately selected during startup. After an
OFF startup or a runtime stop, restart the game/server with an enabled mode to
install full instrumentation again. A late `Enable(mode)` may return
`restart_required`; this tradeoff keeps an OFF hot path identical to the
original function and prevents PZ's automatic script discovery from constructing
the dormant backend or GUI.

## Disabled mode

OFF performs one startup configuration read. Discovered profiler implementation
files immediately return at their startup guard. They do not create the profiler
API/backend table, metric registry, histories, timers, gauges, warnings, ring
buffers, snapshot writers, GUI, profiler networking, or sampling callbacks.
There is no profiler `OnTick` or recurring event. The bootstrap table and its
small set of lifecycle/configuration functions remain loaded. A consumer may
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

`RegisterSampler` is useful for logical state owned by gameplay. Its callback is
called only by an active profiler sample, normally once per second. The profiler
must never become canonical gameplay state.

Timers reuse metric and stack storage. Rates aggregate within intervals rather
than retaining individual events. DETAILED histories use fixed circular buffers
of 300 one-second samples by default. Old samples are overwritten.

## Project Hoomans integration

Project Hoomans is the first consumer. Its `42.20` integration wraps real shared
systems at startup: server update, Director and population pumps, scheduled jobs,
spatial rebuild, world census, perception/decision/pathing boundaries, and the
NPC scheduler. Once-per-second samplers expose actual NPC/live-body, world,
active-aggro, scheduler, abstract-group, settlement, and dirty-record counts.

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

The scan runs at most once per ten seconds and caps each section at 25,000 nodes,
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

## Known limitations

- Exact per-mod RAM attribution is unavailable.
- Only code routed through registered/wrapped boundaries is timed.
- The in-game History view reports bounded series rather than rendering a
  high-frequency graph; the external GUI provides the lightweight RSS graph.
- Snapshot replacement is reader-tolerant rather than atomically renamed due to
  the portable PZ Lua file API.
- Profiler backend, GUI, and consumer hot-path instrumentation are selected at
  startup and require a restart after OFF/disable if they must be enabled again.
