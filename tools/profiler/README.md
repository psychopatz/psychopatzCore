# Psychopatz Performance Profiler

This standalone Tk application monitors a Project Zomboid client or dedicated
server and reads generic PsychopatzCore profiler snapshots. It supports Linux,
Windows, and macOS without OS-specific process commands.

## Requirements

- Python 3.9 or newer
- `psutil`
- Tkinter from the operating system's Python distribution

Install only the Python dependency:

```sh
python -m pip install -r requirements.txt
```

Tkinter is commonly bundled on Windows and macOS Python distributions. Some
Linux distributions package it separately (often as `python3-tk` or an
equivalent). The launcher detects that case and installs the appropriate
package using a supported system package manager.

## Running

On Linux or macOS, the convenience launcher creates an isolated `.venv`,
installs missing Python dependencies and Tkinter, and then starts the
application:

```sh
./run_profiler.sh
./run_profiler.sh --pid 12345
```

The recommended Project Hoomans workflow is GUI-first. Launch normally:

```sh
./run_profiler.sh
```

Choose one or more capture sections under **PROJECT HOOMANS PROFILING SETUP**
and use **Apply Settings**. **Performance** is the recommended default. ModData
and NPC capture are independent and remain unregistered when not selected.
The button always persists the configuration. If the Local Control Bridge was
explicitly enabled and is connected, it also applies the same configuration
live. When the bridge is disabled, the original restart-required workflow is
used for backward compatibility and the app does not enable it implicitly.

The adjacent state-aware button reads **Enable Profiling** while profiling is
OFF and **Disable Profiling** while the current/configured runtime is active.
Disabling does not erase the selected capture sections, so the next enable
restores the previous Performance, ModData, and NPC choices.

Every enabled runtime reports a unique runtime ID and the exact configuration
fingerprint it applied. The GUI changes to **APPLIED by runtime ...** only after
the bridge response or snapshot reports an exact match. OFF releases callbacks,
metrics, histories, providers, and wrappers while preserving the selected
sections for a later live enable.

The equivalent terminal shortcut remains available for automation:

```sh
./run_profiler.sh --profile-project-hoomans
```

After using that option, start or fully restart Project Zomboid. Without the
optional bridge, profiler topology is selected during mod startup. To restore
the normal strict OFF mode afterward, close the game and run:

```sh
./run_profiler.sh --disable-game-profiler
```

For a missing Tkinter installation, the launcher supports `apt-get`, `dnf`,
`zypper`, `pacman`, `apk`, and Homebrew. A Linux package installation may ask
for the administrator password through `sudo`. If Python itself or Python's
`venv` support is unavailable, the launcher reports the missing prerequisite.

Direct invocation remains supported:

```sh
python psychopatz_profiler.py
python psychopatz_profiler.py --pid 12345
python psychopatz_profiler.py --snapshot /path/to/PsychopatzCore_Profiler_latest.json
python psychopatz_profiler.py --interval 2
```

Paths are examples only; no machine-specific path is built into the tool. Use
the **Select snapshot** button when automatic discovery is ambiguous.

Timer reports expose both inclusive msPerSec and exclusive selfMsPerSec.
The CLI and desktop metric aggregation use exclusive time when the field is
present, so nested Project Hoomans wrappers do not double-count their parents.
The ProjectZomboid namespace contains optional frame timing and stock local
performance, network, and game statistics when the 42.20 adapter can read them.

Process discovery enumerates processes with `psutil`, scores strong executable,
name, and command-line Project Zomboid signals, and distinguishes likely clients
from dedicated servers. A generic Java process is never accepted without an
independent Zomboid command-line signal. One strong candidate is selected
automatically; multiple candidates remain selectable by PID and description.

If a process exits, the GUI remains open, reports `DISCONNECTED`, discards the
dead `psutil.Process`, and rescans. Access-denied, zombie, and vanished processes
do not crash the application. Unsupported metrics display `N/A`.

After a successful **Connect**, the GUI atomically saves a stable identity made
from the process name, executable basename, and client/server kind. PID and full
command line are deliberately not persisted. On later launches it finds the
new PID matching that identity and reconnects automatically. When there is no
saved identity and exactly one safe PZ candidate, that candidate is connected
and remembered automatically.

External-app preferences are stored in:

```text
~/Zomboid/Lua/PsychopatzCore_ProfilerApp.json
```

This versioned file also preserves poll interval and selected tab. Capture and
bridge settings remain in their own game-facing configuration files.

The default poll is one second. Select 0.5, 1, 2, or 5 seconds in the GUI. Tk's
event loop schedules polling; there is no busy loop or worker thread.

## Recording and markers

**Start Recording** writes normalized CSV metric rows using the standard `csv`
module. Each row contains timestamp, row type, PID, namespace, metric, kind,
value, and marker text. Arbitrary future namespaces require no schema change.

Recordings rotate at 100 MB by default into numbered files; existing data is
kept and recording continues visibly in the next file. **Add Marker** records a
bounded in-memory graph marker and a CSV marker row, making game actions easy to
correlate with process RSS and internal metrics.

The GUI labels RSS as **PROJECT ZOMBOID PROCESS** memory. It never claims that
RSS belongs to an individual mod. Trend warnings use cautious wording and do not
claim to prove a leak.

## ModData and LLM analysis

With Project Hoomans running in DETAILED mode, the GUI shows a bounded ModData
bloat table. Expand persisted data, runtime records, and inventory state to see
their estimated shape and largest normalized paths. Estimates are comparative,
not exact heap or save-file sizes, and the three sections overlap.

The GUI automatically writes a compact report to:

```text
~/Zomboid/Lua/PsychopatzCore_Profiler_LLM_latest.json
```

Use **Export LLM...** to select Performance, ModData, or one targeted NPC. The
automatic report excludes detailed NPC contents. Explicit NPC exports may
contain identifiers and gameplay state, but remain bounded by in-game limits.

The main workspace is split into **Performance**, **ModData Summary**, and
**NPC Data Inspector** tabs. Click a column heading to sort it; numeric columns
sort by their raw values, and the default Performance order shows the largest
timer latency first. The NPC tab lists display name, faction, presence, runtime
shape, persisted shape, and item count. Selecting an NPC opens bounded runtime
and saved ModData fields. This local detailed view is not copied into the
automatic LLM report.

Expand/collapse choices, selection, and scroll position persist across snapshot
refreshes. Use **Pause Updates** to freeze process sampling, snapshot reads,
graphs, tables, CSV metric rows, and automatic LLM-report writes. Existing data
remains visible and expandable while paused; **Resume Updates** continues live
collection.

## Headless LLM interface

`profiler_cli.py` is the authoritative read-only interface used by automation
and the `pz-profiler-analysis` skill. It shares snapshot normalization and
report generation with the GUI and never dumps raw JSON as a fallback.

```sh
python profiler_cli.py status
python profiler_cli.py process status
python profiler_cli.py list-sections
python profiler_cli.py list-npcs
python profiler_cli.py summarize --sections performance --top 15 --min-ms 0.5
python profiler_cli.py summarize --sections npc --npc "Alex Morgan" \
  --npc-view animation,ai,pathing --token-budget 3000
```

Global `--snapshot` and `--config` overrides appear before the subcommand.
Reports are bounded by depth, collection length, string length, and an
approximate four-characters-per-token budget.

`process status`, normal `status`, and `summarize` reuse the GUI-saved process
identity. An LLM therefore does not need the process name or changing PID in
each request. Process output excludes the full command line.

## External Control bridge

The **External Control** tab is a generic local IPC foundation:

```text
External app -> BridgeClient -> FileBridgeTransport
             -> PsychopatzCore Bridge -> registered capability
```

It is not arbitrary Lua execution, a console, a remote administration system,
or an LLM implementation. External input is always untrusted. Commands are
explicitly registered under namespaces, arguments are bounded and validated,
and unknown commands are rejected. There is no `eval`, Java reflection,
unrestricted filesystem access, or generic command button generation.

The bridge has a separate startup configuration at
`~/Zomboid/Lua/PsychopatzCore_Bridge.txt` and defaults to disabled:

```ini
config_version=1
bridge_enabled=false
bridge_transport=file
bridge_poll_interval_ms=250
```

Enable it explicitly in **External Control** and save the bridge setting. While
the profiler is active, its existing bounded sample cycle detects that explicit
activation, starts the bridge, and removes the activation probe. **Apply
Settings** never enables the bridge implicitly. If the bridge remains disabled,
the profiler configuration is saved for the next PZ startup. If both profiler
and bridge started OFF, one game startup is unavoidable because no game-side
listener exists. In that strict OFF state, only the small bootstraps read their
configuration once: no update callback, queue, or filesystem polling exists.
Once the enabled bridge connects, every profiler setup control uses the same
live configuration pipeline.
The only initial mutating capability is the validated
`psychopatzcore.profiler.configure`; infrastructure capabilities are `ping`,
`capabilities`, and `runtimeInfo`.

**Ping Runtime** sends a unique desktop marker. The game writes
`[PsychopatzBridge] external_ping marker=...` to `console.txt`, echoes the same
marker in its response, and the app displays it under **Last response**. This
verifies both app-to-game delivery and game-to-app response handling.

The file transport uses 16 fixed slots under
`~/Zomboid/Lua/PsychopatzBridge/`. Python publishes requests atomically. Lua
processes at most four per throttled cycle and publishes a response before its
completion marker. Python removes completed slots and performs bounded cleanup
of expired bridge-owned files. Requests target the current runtime ID so a
command queued for an old PZ session is rejected with `STALE_RUNTIME`.
Each Python client claims a slot with an atomic lock file, allowing the GUI and
CLI to run concurrently without overwriting one another. They share no polling
thread or duplicate in-game profiler; both consume the same singleton PZ
runtime, snapshots, configuration, and bridge queue.

Safe CLI operations are also available:

```sh
python profiler_cli.py bridge status
python profiler_cli.py bridge ping
python profiler_cli.py bridge capabilities
```

The server is authoritative in hosted multiplayer and dedicated-server modes.
Standalone multiplayer clients do not activate a local bridge. A future network
transport must bind to `127.0.0.1` by default and require explicit opt-in and
authentication for remote access. Future events and asynchronous jobs should
use distinct versioned message types rather than changing protocol-v1 request
and response semantics.

## Capture configuration

The GUI writes `~/Zomboid/Lua/PsychopatzCore_Profiler.txt` with a versioned
contract. The recommended performance-only setup is:

```ini
config_version=2
mode=DETAILED
capture=performance
performance_interval_ms=1000
moddata_interval_ms=60000
npc_interval_ms=5000
npc_scope=selected
npc_ids=
```

Available sections are `performance`, `moddata`, and `npc`. NPC capture emits
a bounded lightweight roster, while deep runtime and persisted content is
copied only for `npc_ids`. Select an NPC in the inspector and use **Capture
Selected NPC** to configure it without manually copying the ID.

## Portability and failure behavior

The tool uses `pathlib`, `psutil`, `collections.deque`, `csv`, `json`, and
Tkinter. It does not read `/proc`, invoke `ps`/`pgrep`, use WMI/PowerShell, or
script Activity Monitor. Snapshot reads tolerate missing, stale, malformed,
partially written, inaccessible, and later-recovered files while retaining the
last valid version-1 snapshot.

Run tests without a game process:

```sh
python -m unittest discover -s tests -v
```
