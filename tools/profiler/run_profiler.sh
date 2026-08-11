#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
VENV_DIR="$SCRIPT_DIR/.venv"
REQUIREMENTS="$SCRIPT_DIR/requirements.txt"
APP="$SCRIPT_DIR/psychopatz_profiler.py"
GAME_PROFILER_CONFIG="$HOME/Zomboid/Lua/PsychopatzCore_Profiler.txt"

if [ "${1:-}" = "--profile-project-hoomans" ]; then
    mkdir -p "$(dirname -- "$GAME_PROFILER_CONFIG")"
    printf '%s\n' \
        'config_version=2' \
        'mode=DETAILED' \
        'capture=performance' \
        'performance_interval_ms=1000' \
        'moddata_interval_ms=60000' \
        'npc_interval_ms=5000' \
        'npc_scope=selected' \
        'npc_ids=' > "$GAME_PROFILER_CONFIG"
    shift
    printf '%s\n' \
        "ProjectHoomans performance-only profiling is enabled." \
        "Start or fully restart Project Zomboid so startup instrumentation is installed."
elif [ "${1:-}" = "--disable-game-profiler" ]; then
    mkdir -p "$(dirname -- "$GAME_PROFILER_CONFIG")"
    printf '%s\n' \
        'config_version=2' \
        'mode=OFF' \
        'capture=performance' > "$GAME_PROFILER_CONFIG"
    printf '%s\n' \
        "Game profiling is disabled. Restart Project Zomboid to return to strict OFF mode."
    exit 0
fi

find_python() {
    if command -v python3 >/dev/null 2>&1; then
        command -v python3
        return 0
    fi
    if command -v python >/dev/null 2>&1; then
        command -v python
        return 0
    fi
    return 1
}

find_tk_python() {
    if command -v python3 >/dev/null 2>&1; then
        candidate=$(command -v python3)
        if "$candidate" -c 'import tkinter' >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi
    # Linuxbrew, pyenv, and aliases can shadow the distribution interpreter.
    # Check its stable path explicitly because system Tk packages target it.
    if [ -x /usr/bin/python3 ] \
        && /usr/bin/python3 -c 'import tkinter' >/dev/null 2>&1; then
        printf '%s\n' /usr/bin/python3
        return 0
    fi
    if command -v python >/dev/null 2>&1; then
        candidate=$(command -v python)
        if "$candidate" -c 'import tkinter' >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi
    return 1
}

rebuild_venv() {
    interpreter=$1
    printf '%s\n' "Rebuilding the profiler environment with Tk-enabled Python: $interpreter"
    if ! "$interpreter" -m venv --clear "$VENV_DIR"; then
        printf '%s\n' \
            "The selected Python could not rebuild the virtual environment." \
            "Install its venv component and run this launcher again." >&2
        exit 2
    fi
}

run_as_admin() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        printf '%s\n' \
            "Installing Tkinter requires administrator access, but sudo was not found." \
            "Install your distribution's Python Tk package and run this launcher again." >&2
        return 1
    fi
}

install_tkinter() {
    printf '%s\n' "Tkinter is missing; installing the operating-system package..."
    if command -v apt-get >/dev/null 2>&1; then
        run_as_admin apt-get install -y python3-tk
    elif command -v dnf >/dev/null 2>&1; then
        run_as_admin dnf install -y python3-tkinter
    elif command -v zypper >/dev/null 2>&1; then
        run_as_admin zypper --non-interactive install python3-tk
    elif command -v pacman >/dev/null 2>&1; then
        run_as_admin pacman -S --needed --noconfirm tk
    elif command -v apk >/dev/null 2>&1; then
        run_as_admin apk add tk
    elif command -v brew >/dev/null 2>&1; then
        brew install python-tk
    else
        printf '%s\n' \
            "No supported package manager was found." \
            "Install your operating system's Python Tkinter package and run this launcher again." >&2
        return 1
    fi
}

SYSTEM_PYTHON=$(find_tk_python || find_python || true)
if [ -z "$SYSTEM_PYTHON" ]; then
    printf '%s\n' \
        "Python 3 was not found." \
        "Install Python 3 using your operating system's normal software tools, then run this launcher again." >&2
    exit 2
fi

if [ ! -x "$VENV_DIR/bin/python" ]; then
    printf '%s\n' "Creating local profiler environment: $VENV_DIR"
    if ! "$SYSTEM_PYTHON" -m venv "$VENV_DIR"; then
        printf '%s\n' \
            "Python could not create a virtual environment." \
            "Install the Python venv component supplied by your operating system, then try again." >&2
        exit 2
    fi
fi

VENV_PYTHON="$VENV_DIR/bin/python"

# A venv can survive a Python upgrade or PATH change while retaining its old
# interpreter. Rebuild our disposable app environment with an interpreter that
# can actually load Tkinter.
TK_PYTHON=$(find_tk_python || true)
if [ -n "$TK_PYTHON" ] \
    && ! "$VENV_PYTHON" -c 'import tkinter' >/dev/null 2>&1; then
    rebuild_venv "$TK_PYTHON"
fi

if ! "$VENV_PYTHON" -c 'import tkinter' >/dev/null 2>&1; then
    install_tkinter
    TK_PYTHON=$(find_tk_python || true)
    if [ -n "$TK_PYTHON" ]; then
        rebuild_venv "$TK_PYTHON"
    fi
    if ! "$VENV_PYTHON" -c 'import tkinter' >/dev/null 2>&1; then
        printf '%s\n' \
            "Tkinter is still unavailable after package installation." \
            "Your Python installation may not use the operating system's Tk package." >&2
        exit 2
    fi
fi

if ! "$VENV_PYTHON" -c 'import psutil' >/dev/null 2>&1; then
    printf '%s\n' "Installing profiler Python dependencies..."
    "$VENV_PYTHON" -m pip install --disable-pip-version-check -r "$REQUIREMENTS"
fi

exec "$VENV_PYTHON" "$APP" "$@"
