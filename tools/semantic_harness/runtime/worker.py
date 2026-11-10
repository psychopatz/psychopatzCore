"""Public Core-owned worker entrypoint with explicit provider delegation."""

from __future__ import annotations

import importlib
import sys
from dataclasses import replace
from pathlib import Path
from typing import Any

from .config import HarnessConfig, build_worker_launch_spec
from .core_worker import CoreLuaSemanticWorker


def _provider_worker_class(config: HarnessConfig) -> type[Any] | None:
    reference = config.provider_python_worker
    if not reference:
        return None
    if str(config.repository) not in sys.path:
        sys.path.insert(0, str(config.repository))
    module_name, separator, attribute = str(reference).partition(":")
    if not separator or not module_name or not attribute:
        raise ValueError(f"invalid provider worker reference: {reference}")
    module = importlib.import_module(module_name)
    worker_class = getattr(module, attribute, None)
    if not isinstance(worker_class, type):
        raise TypeError(f"provider worker is not a class: {reference}")
    return worker_class


class LuaSemanticWorker:
    """Select the Core worker or an explicit provider adapter at construction."""

    def __new__(cls, scenario: Any = None, *args: Any, **kwargs: Any) -> Any:
        config = kwargs.get("config")
        if config is None:
            config = HarnessConfig.discover(
                repository=kwargs.get("repository"),
                core_repository=kwargs.get("core_repository"),
                dynamic_trading_repository=kwargs.get("dynamic_trading_repository"),
                lua_bin=kwargs.get("lua_bin"),
                worker_script=kwargs.get("worker_script"),
                profile=kwargs.get("profile", "core"),
                startup_timeout=kwargs.get("startup_timeout", 8.0),
                request_timeout=kwargs.get("request_timeout", 5.0),
                shutdown_timeout=kwargs.get("shutdown_timeout", 1.0),
            )
        worker_class = _provider_worker_class(config)
        if worker_class is not None:
            provider_kwargs = dict(kwargs)
            provider_kwargs["config"] = config
            launch_spec = build_worker_launch_spec(config)
            if config.provider_worker_script is not None:
                launch_spec = replace(
                    launch_spec,
                    worker_script=config.provider_worker_script,
                )
            provider_kwargs["launch_spec"] = launch_spec
            provider_kwargs["repository"] = config.repository
            provider_kwargs["core_repository"] = config.core_repository
            provider_kwargs["lua_bin"] = config.lua_bin
            if config.provider_worker_script is not None:
                provider_kwargs["worker_script"] = config.provider_worker_script
            provider_kwargs["profile"] = (
                config.provider_worker_profile or config.profile
            )
            return worker_class(scenario, *args, **provider_kwargs)
        kwargs["config"] = config
        return CoreLuaSemanticWorker(scenario, *args, **kwargs)


__all__ = ["CoreLuaSemanticWorker", "LuaSemanticWorker"]
