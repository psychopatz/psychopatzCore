"""Provider-neutral local runtime and Lua executable discovery."""

from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path


class ConfigurationError(RuntimeError):
    """Raised when a required local harness runtime cannot be discovered."""


RUNTIME_DIRECTORY_PATTERN = re.compile(r"^\d+\.\d+$")


def discover_newest_runtime(mod_root: str | Path) -> str:
    """Return the newest numeric Build runtime directory under ``mod_root``."""

    root = Path(mod_root).expanduser().resolve()
    if not root.is_dir():
        raise ConfigurationError(f"runtime root does not exist: {root}")

    versions = [
        (tuple(int(part) for part in child.name.split(".")), child.name)
        for child in root.iterdir()
        if child.is_dir() and RUNTIME_DIRECTORY_PATTERN.fullmatch(child.name)
    ]
    if not versions:
        raise ConfigurationError(f"no numeric runtime directory under {root}")
    return max(versions)[1]


def discover_lua(explicit: str | Path | None = None) -> Path:
    """Find an executable Lua interpreter from an explicit path or PATH."""

    if explicit:
        candidates = [str(explicit)]
    else:
        environment = os.environ.get("SEMANTIC_HARNESS_LUA")
        if environment is None:
            environment = os.environ.get("PNC_HARNESS_LUA")
        candidates = [environment] if environment else []
        candidates.extend(["lua", "luajit"])

    for candidate in candidates:
        found = shutil.which(candidate)
        if found:
            return Path(found).resolve()
        path = Path(candidate).expanduser()
        if path.is_file() and path.stat().st_mode & 0o111:
            return path.resolve()
    raise ConfigurationError(
        "could not locate a Lua executable; set "
        "SEMANTIC_HARNESS_LUA or use an explicit path"
    )


def probe_lua(lua_bin: Path, timeout: float = 2.0) -> tuple[bool, str]:
    """Return whether ``lua_bin`` starts and its bounded version line."""

    try:
        result = subprocess.run(
            [str(lua_bin), "-v"],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return False, str(error)
    output = (result.stdout or result.stderr or "").strip().splitlines()
    version = output[0] if output else "unknown Lua version"
    if result.returncode != 0:
        return False, f"{version} (exit {result.returncode})"
    return True, version


__all__ = [
    "ConfigurationError",
    "RUNTIME_DIRECTORY_PATTERN",
    "discover_lua",
    "discover_newest_runtime",
    "probe_lua",
]
