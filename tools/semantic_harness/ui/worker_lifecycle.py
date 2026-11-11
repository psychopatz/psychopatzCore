"""Start the worker session and bridge its future into Tk callbacks."""

from __future__ import annotations

from pathlib import Path
from typing import Any


def worker_kwargs(app: Any) -> dict[str, Any]:
    return {
        "lua_bin": app.arguments.lua,
        "repository": Path(app.arguments.repository)
        if app.arguments.repository
        else None,
        "core_repository": Path(app.arguments.core_repository)
        if app.arguments.core_repository
        else None,
        "profile": getattr(app.arguments, "profile", "pnc"),
        "preset": getattr(app.arguments, "preset", None),
        "mods": getattr(app.arguments, "mods", None),
        "provider_roots": tuple(getattr(app.arguments, "provider_root", None) or ()),
        "dynamic_trading_repository": (
            Path(app.arguments.dynamic_trading_repository)
            if getattr(app.arguments, "dynamic_trading_repository", None)
            else None
        ),
        "startup_timeout": app.arguments.startup_timeout,
        "request_timeout": app.arguments.timeout,
        "shutdown_timeout": app.arguments.shutdown_timeout,
        "activity_log": app.activity_log,
    }


def start_worker(app: Any) -> None:
    if app.closed:
        return
    app._future = app.session.start()
    app._poll_future(app._future, app._worker_ready)
