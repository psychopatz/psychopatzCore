"""Headless, bounded diagnostics for the semantic harness runtime."""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

from ..runtime.config import (
    ConfigurationError,
    HarnessConfig,
    discover_core_repository,
)
from ..discovery.runtime import discover_lua, probe_lua
from ..runtime.worker import LuaSemanticWorker
from tools.semantic_harness.transport.process import HarnessError


def _check(name: str, ok: bool, detail: str, *, required: bool = True) -> dict[str, Any]:
    return {"name": name, "ok": ok, "required": required, "detail": detail}


def run_doctor(
    *,
    repository: str | Path | None = None,
    core_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    provider_roots: tuple[str | Path, ...] = (),
    mods: tuple[str, ...] | None = None,
    preset: str | None = None,
    lua_bin: str | Path | None = None,
    profile: str = "pnc",
    startup_timeout: float = 8.0,
    request_timeout: float = 5.0,
    json_output: bool = False,
) -> int:
    checks: list[dict[str, Any]] = []
    resolved_repository: Path | None = None
    resolved_core: Path | None = None
    resolved_lua: Path | None = None

    checks.append(
        _check(
            "python",
            sys.version_info >= (3, 10),
            f"{sys.executable} ({sys.version.split()[0]})",
        )
    )
    expected_venv = None
    try:
        resolved_core = discover_core_repository(core_repository)
        resolved_repository = Path(repository).expanduser().resolve() if repository else resolved_core
        expected_venv = resolved_core / "tools/semantic_harness/.venv"
        checks.append(_check("repository", True, str(resolved_repository)))
        checks.append(_check("core_repository", True, str(resolved_core)))
    except ConfigurationError as error:
        checks.append(_check("repository", False, str(error)))
        checks.append(_check("core_repository", False, str(error)))

    if expected_venv is not None:
        active_venv = Path(sys.prefix).resolve() == expected_venv.resolve()
        checks.append(
            _check(
                "venv",
                active_venv,
                f"active={sys.prefix}; expected={expected_venv}",
                required=False,
            )
        )

    tk_available = importlib.util.find_spec("tkinter") is not None
    checks.append(_check("tkinter", tk_available, "importable" if tk_available else "not installed", required=False))
    display_available = bool(os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY"))
    checks.append(
        _check(
            "display",
            display_available,
            "GUI display detected" if display_available else "no DISPLAY/WAYLAND_DISPLAY; use --no-gui",
            required=False,
        )
    )

    try:
        resolved_lua = discover_lua(lua_bin)
        lua_ok, lua_detail = probe_lua(resolved_lua)
        checks.append(_check("lua", lua_ok, f"{resolved_lua}: {lua_detail}"))
    except ConfigurationError as error:
        checks.append(_check("lua", False, str(error)))

    worker_script = Path(__file__).resolve().parents[1] / "lua" / "worker.lua"
    syntax_ok = False
    if resolved_lua is not None and worker_script.is_file():
        try:
            syntax_environment = os.environ.copy()
            syntax_environment["SEMANTIC_DOCTOR_WORKER_SCRIPT"] = str(
                worker_script
            )
            syntax = subprocess.run(
                [
                    str(resolved_lua),
                    "-e",
                    "assert(loadfile(os.getenv('SEMANTIC_DOCTOR_WORKER_SCRIPT')))",
                ],
                env=syntax_environment,
                capture_output=True,
                text=True,
                timeout=2.0,
                check=False,
            )
            syntax_ok = syntax.returncode == 0
            detail = "worker.lua parses" if syntax_ok else (syntax.stderr or syntax.stdout).strip()
            checks.append(_check("worker_syntax", syntax_ok, detail or "syntax check failed"))
        except (OSError, subprocess.TimeoutExpired) as error:
            checks.append(_check("worker_syntax", False, str(error)))
    else:
        checks.append(_check("worker_syntax", False, "Lua or worker script is unavailable"))

    boot_ok = False
    if resolved_repository and resolved_core and resolved_lua and syntax_ok:
        try:
            config = HarnessConfig.discover(
                repository=resolved_repository,
                core_repository=resolved_core,
                dynamic_trading_repository=dynamic_trading_repository,
                provider_roots=provider_roots,
                mods=mods,
                preset=preset,
                lua_bin=resolved_lua,
                profile=profile,
                startup_timeout=startup_timeout,
                request_timeout=request_timeout,
            )
            from ..cli import _provider_value

            scenario = _provider_value(
                config,
                config.provider_python_scenario,
                {},
            )
            with LuaSemanticWorker(scenario, config=config) as worker:
                ping = worker.ping()
                capabilities = worker.capabilities()
            boot_ok = ping.get("type") == "pong" and capabilities.get("type") == "capabilities"
            checks.append(
                _check(
                    "worker_boot",
                    boot_ok,
                    "READY/PING/CAPABILITIES completed" if boot_ok else "unexpected worker handshake",
                )
            )
        except (HarnessError, OSError, ValueError) as error:
            checks.append(_check("worker_boot", False, str(error)))
    else:
        checks.append(_check("worker_boot", False, "prerequisite check failed"))

    required_failures = [check for check in checks if check["required"] and not check["ok"]]
    report = {"ok": not required_failures, "checks": checks}
    if json_output:
        print(json.dumps(report, ensure_ascii=False, separators=(",", ":")))
    else:
        for check in checks:
            label = "PASS" if check["ok"] else ("FAIL" if check["required"] else "WARN")
            print(f"[{label}] {check['name']}: {check['detail']}")
        print("Doctor result: " + ("PASS" if report["ok"] else "FAIL"))
    return 0 if report["ok"] else 1
