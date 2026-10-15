#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

find_gui_python() {
    local candidate
    local candidates=()

    if [[ -n "${PYTHON_BIN:-}" ]]; then
        candidates+=("$PYTHON_BIN")
    fi

    candidates+=(
        /usr/bin/python3
        /usr/local/bin/python3
        "$(command -v python3 2>/dev/null || true)"
        "$(command -v python 2>/dev/null || true)"
    )

    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue
        if [[ "$candidate" != */* ]]; then
            candidate="$(command -v "$candidate" 2>/dev/null || true)"
        fi
        [[ -x "$candidate" ]] || continue
        if "$candidate" -c 'import tkinter; from PIL import Image' >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && "$(uname -s)" == "Linux" ]]; then
    printf 'Radio Simulator GUI needs a graphical display (DISPLAY or WAYLAND_DISPLAY).\n' >&2
    exit 2
fi

PYTHON_BIN_RESOLVED="$(find_gui_python || true)"
if [[ -z "$PYTHON_BIN_RESOLVED" ]]; then
    printf 'No Python interpreter with Tkinter and Pillow was found.\n' >&2
    printf 'Install the OS Tk package and Pillow, or set PYTHON_BIN to a compatible Python.\n' >&2
    exit 2
fi

export PYTHONPATH="$REPO_ROOT/tools${PYTHONPATH:+:$PYTHONPATH}"
if [[ "${1:-}" == "--asset-viewer" ]]; then
    shift
    exec "$PYTHON_BIN_RESOLVED" "$SCRIPT_DIR/gui.py" "$@"
fi
exec "$PYTHON_BIN_RESOLVED" "$SCRIPT_DIR/simulator_gui.py" "$@"
