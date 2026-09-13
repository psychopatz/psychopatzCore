#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
VENV_DIR="$SCRIPT_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
PYTHON_BIN="${PYTHON_BIN:-}"

find_tk_python() {
    local candidate
    local candidates=()

    if [[ -n "$PYTHON_BIN" ]]; then
        candidates+=("$PYTHON_BIN")
    fi

    # Prefer the distro Python that commonly carries the system Tk package.
    # The command-based candidates keep this portable across other systems.
    candidates+=(
        /usr/bin/python3.12
        /usr/bin/python3.11
        /usr/bin/python3
        /usr/local/bin/python3.12
        /usr/local/bin/python3.11
        "$(command -v python3.12 2>/dev/null || true)"
        "$(command -v python3.11 2>/dev/null || true)"
        "$(command -v python3 2>/dev/null || true)"
    )

    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue
        if [[ "$candidate" != */* ]]; then
            candidate="$(command -v "$candidate" 2>/dev/null || true)"
        fi
        [[ -x "$candidate" ]] || continue
        if "$candidate" -c 'import tkinter' >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

if [[ -x "$VENV_PYTHON" ]] && ! "$VENV_PYTHON" -c 'import tkinter' >/dev/null 2>&1; then
    printf 'Existing virtual environment has no Tkinter; rebuilding it with a Tk-capable Python.\n'
    HOST_PYTHON="$(find_tk_python || true)"
    if [[ -z "$HOST_PYTHON" ]]; then
        printf 'No Tk-capable Python 3 interpreter was found. Set PYTHON_BIN to one that can import tkinter.\n' >&2
        exit 2
    fi
    "$HOST_PYTHON" -m venv --clear "$VENV_DIR"
fi

if [[ ! -x "$VENV_PYTHON" ]]; then
    HOST_PYTHON="$(find_tk_python || true)"
    if [[ -z "$HOST_PYTHON" ]]; then
        printf 'No Tk-capable Python 3 interpreter was found. Set PYTHON_BIN to one that can import tkinter.\n' >&2
        exit 2
    fi

    printf 'Creating local virtual environment: %s\n' "$VENV_DIR"
    "$HOST_PYTHON" -m venv "$VENV_DIR"
fi

if [[ ! -x "$VENV_PYTHON" ]]; then
    printf 'Unable to create the local virtual environment at %s.\n' "$VENV_DIR" >&2
    exit 1
fi

if ! "$VENV_PYTHON" -m pip --version >/dev/null 2>&1; then
    printf 'Bootstrapping pip in the local virtual environment.\n'
    "$VENV_PYTHON" -m ensurepip --upgrade
fi

PACKAGE_STAMP="$VENV_DIR/.steam_uploader_gui_dependencies"
if [[ ! -f "$PACKAGE_STAMP" || "$SCRIPT_DIR/pyproject.toml" -nt "$PACKAGE_STAMP" ]] || \
   ! "$VENV_PYTHON" -m pip show steam-uploader-gui >/dev/null 2>&1; then
    printf 'Installing Steam Uploader and its Python dependencies into the local virtual environment.\n'
    "$VENV_PYTHON" -m pip install --disable-pip-version-check --editable "$SCRIPT_DIR"
    touch "$PACKAGE_STAMP"
fi

if ! "$VENV_PYTHON" -c 'import tkinter' >/dev/null 2>&1; then
    printf 'The virtual environment still cannot import Tkinter. Set PYTHON_BIN to a Tk-capable Python and run again.\n' >&2
    exit 2
fi

cd "$SCRIPT_DIR"
exec "$VENV_PYTHON" -m steam_uploader_gui "$@"
