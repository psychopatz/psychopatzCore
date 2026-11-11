#!/usr/bin/env bash

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "$HARNESS_DIR/../.." && pwd)"
VENV_DIR="$HARNESS_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
BOOTSTRAP_PYTHON="${SEMANTIC_HARNESS_PYTHON:-python3}"

if ! command -v "$BOOTSTRAP_PYTHON" >/dev/null 2>&1; then
    echo "semantic harness: Python executable not found: $BOOTSTRAP_PYTHON" >&2
    exit 2
fi

if ! "$BOOTSTRAP_PYTHON" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
    echo "semantic harness: Python 3.10 or newer is required" >&2
    exit 2
fi

if [ ! -w "$HARNESS_DIR" ]; then
    VENV_PYTHON="$BOOTSTRAP_PYTHON"
elif [ ! -x "$VENV_PYTHON" ]; then
    if [ -e "$VENV_DIR" ]; then
        echo "semantic harness: incomplete venv at $VENV_DIR; remove it or repair it, then retry" >&2
        exit 2
    fi
    echo "semantic harness: creating venv at $VENV_DIR"
    "$BOOTSTRAP_PYTHON" -m venv "$VENV_DIR"
fi

if [ "$VENV_PYTHON" = "$BOOTSTRAP_PYTHON" ]; then
    if ! command -v "$VENV_PYTHON" >/dev/null 2>&1; then
        echo "semantic harness: Python executable is unavailable: $VENV_PYTHON" >&2
        exit 2
    fi
elif [ ! -x "$VENV_PYTHON" ]; then
    echo "semantic harness: venv Python is unavailable: $VENV_PYTHON" >&2
    exit 2
fi

HARNESS_ARGS=("$@")
cd "$REPOSITORY_ROOT"
export PYTHONPATH="$REPOSITORY_ROOT${PYTHONPATH:+:$PYTHONPATH}"
if [ -z "${SEMANTIC_HARNESS_CORE_REPOSITORY:-}" ]; then
    export SEMANTIC_HARNESS_CORE_REPOSITORY="$REPOSITORY_ROOT"
fi

exec "$VENV_PYTHON" -m tools.semantic_harness.entrypoints.app "${HARNESS_ARGS[@]}"
