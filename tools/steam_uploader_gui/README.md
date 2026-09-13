# SteamUploader GUI

Portable Python GUI for Workshop projects found under the current user's
`Zomboid/Workshop` directory. The project is intentionally split into domain,
persistence, service, feature, and UI packages so new Workshop fields or tools
do not have to be added to one large application module.

## Run

The recommended launcher is the executable `run.sh` in this directory:

```bash
./run.sh
```

`run.sh` finds a Python interpreter that can import Tkinter, creates a local
`.venv` from it on first launch, installs this project and the dependencies
declared in `pyproject.toml`, and reuses that environment on later launches.
If an existing `.venv` was created from a Python build without Tkinter, it is
automatically rebuilt with the Tk-capable interpreter. It can also be
double-clicked from a Linux file manager. The `.venv` directory is local to
this tool and is ignored by git.

To choose a specific interpreter explicitly:

```bash
PYTHON_BIN=/usr/bin/python3.12 ./run.sh
```

Tkinter is provided by the operating system rather than pip. If the launcher
reports that Tkinter is missing, install the platform's Tk package and run it
again.

The default Workshop root is computed as:

```text
<home>/Zomboid/Workshop
```

It is configurable in the GUI, as is the SteamUploader executable. Use the
`Settings…` button to save both values to the SQLite settings database; the
uploader path is not tied to a particular checkout or operating system. No
Linux absolute path is embedded in the application.

## Structure

```text
steam_uploader_gui/
  core/                  profiles, discovery, portable configuration
  persistence/           SQLite settings, profiles, and audit events
  services/              uploader process adapter and structured logging
  features/bbcode/       Steam BBCode parser, formatter, and preview widget
  ui/                    Tk application shell and modular UI components
    application.py       window lifecycle, actions, and service coordination
    editor.py            responsive profile editor and safety controls
    widgets.py           scrollable and collapsible reusable widgets
    project_list.py      Workshop project navigator
    theme.py             shared light/dark color palette
    state.py             persisted UI preferences
tests/                   dependency-light core tests
```

The editor uses a scrollable layout with collapsible per-mod sections. App ID
and Workshop ID are read-only unless the unsafe identifier-editing checkbox in
Settings is enabled. Section expansion, selected project, update selections,
and window geometry are stored in the SQLite UI-state namespace.

## BBCode editor

The description and change-note editors each have separate `BBCode source` and
`Steam preview` tabs. The preview renders supported embedded local or HTTP(S)
images, including `[url=...][img]...[/img][/url]` image links and direct image
URL snippets. Steam CDN image URLs are recognized even when their URL has no
file extension. Image links can be clicked from the preview to open their
target. The primary Workshop preview panel displays PNG, JPEG, and animated
GIF files.

The toolbar inserts common Steam tags such as `[b]`, `[i]`, `[u]`, `[strike]`,
`[quote]`, `[code]`, headings, links, images, and lists. Paste or type emoji and
other Unicode directly; the editor keeps the text as Unicode and avoids
truncating the middle of common emoji sequences. Use `Open full editor`,
double-click the editor, or press `Ctrl+Shift+E` for a large resizable authoring
window. The inline description can also be resized with its bottom drag handle.
Both source and preview panes have their own scrollbars, so long Workshop
descriptions do not require fighting the outer project scroll area.

Use Settings to enable the persisted dark mode. It updates the source editor,
Steam preview, image preview, project list, logs, and expanded editor together.

## Safety status

The GUI discovers mod profiles, stores settings in SQLite, validates files, and
shows every scan, validation, subprocess, stdout, stderr, and exit event in the
live log and a dated JSONL log file.

The bundled SteamUploader backend supports both full manifest updates and the
selective `update --request` command. The latter calls only the selected Steam
UGC setters, so a content-only update does not overwrite title, description,
tags, visibility, or preview. The toolbar can fetch current public Workshop
metadata and open the item page directly.

Full uploads are available when all six update fields are selected. Steam field
limits are enforced in the editors and validator: 128 characters for titles,
8,000 for descriptions and change notes, 255 per tag, and a primary preview
smaller than 1,000,000 bytes.

## Tests

```bash
python3 -m unittest discover -s tests -p 'test_*.py'
```
