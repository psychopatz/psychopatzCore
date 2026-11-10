"""Core-only worker façade used by the canonical harness."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Mapping

from ..worker import SemanticWorker
from .config import HarnessConfig, build_worker_launch_spec


class CoreLuaSemanticWorker(SemanticWorker):
    """Run the provider-neutral Core worker without adopter state."""

    def __init__(self, scenario: Mapping[str, Any] | None = None, *, lua_bin: str | Path | None = None, repository: str | Path | None = None, core_repository: str | Path | None = None, dynamic_trading_repository: str | Path | None = None, worker_script: str | Path | None = None, profile: str = "core", startup_timeout: float = 8.0, request_timeout: float = 5.0, shutdown_timeout: float = 1.0, config: HarnessConfig | None = None, activity_log: Any | None = None) -> None:
        self.config = config or HarnessConfig.discover(repository=repository, core_repository=core_repository, dynamic_trading_repository=dynamic_trading_repository, lua_bin=lua_bin, worker_script=worker_script, profile=profile, startup_timeout=startup_timeout, request_timeout=request_timeout, shutdown_timeout=shutdown_timeout)
        super().__init__(scenario or {}, build_worker_launch_spec(self.config), activity_log=activity_log, import_source_on_start=False)

    def ping(self) -> dict[str, Any]:
        return self._request("PING")

    def input(self, text: str) -> dict[str, Any]:
        return self._request("PARSE", {"text": str(text)})


__all__ = ["CoreLuaSemanticWorker"]
