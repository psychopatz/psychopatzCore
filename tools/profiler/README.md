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

Use **Enable DETAILED** under **PROJECT HOOMANS PROFILING SETUP**, then fully
restart Project Zomboid and load the save. The GUI displays the currently
configured mode and explains the required restart. Use **Disable (OFF)** when
finished and restart the game to restore strict zero-overhead mode.

The equivalent terminal shortcut remains available for automation:

```sh
./run_profiler.sh --profile-project-hoomans
```

After using that option, start or fully restart Project Zomboid. The profiler is
selected during mod startup; enabling it while a game process is already running
cannot retrofit wrappers into the active session. To restore the normal strict
OFF mode afterward, close the game and run:

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

Process discovery enumerates processes with `psutil`, scores strong executable,
name, and command-line Project Zomboid signals, and distinguishes likely clients
from dedicated servers. A generic Java process is never accepted without an
independent Zomboid command-line signal. One strong candidate is selected
automatically; multiple candidates remain selectable by PID and description.

If a process exits, the GUI remains open, reports `DISCONNECTED`, discards the
dead `psutil.Process`, and rescans. Access-denied, zombie, and vanished processes
do not crash the application. Unsupported metrics display `N/A`.

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

The GUI automatically writes a compact, value-redacted report to:

```text
~/Zomboid/Lua/PsychopatzCore_Profiler_LLM_latest.json
```

Use **Export LLM Report** to save another copy. This report is designed for
token-efficient inspection by an LLM: it retains only the top timers, bounded
gauges and warnings, summarized ModData structure, and a single process sample.
It does not include raw NPC identifiers, item values, or complete save tables.

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
