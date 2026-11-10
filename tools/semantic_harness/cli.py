"""Provider-neutral command-line entry point for Semantic Harness."""

from __future__ import annotations

import argparse
import importlib
import json
from copy import deepcopy
from pathlib import Path
from typing import Any, Sequence

from .runtime.config import PROFILE_ALIASES, HarnessConfig
from .runtime.worker import LuaSemanticWorker
from .scenario import load_json_document


AUTHORING_OPERATIONS: tuple[str, ...] = ()
CLI_OPERATIONS = ("input", "ping", "capabilities")


def _provider_value(config: HarnessConfig, reference: str | None, default: Any) -> Any:
    """Resolve an optional provider-owned default through manifest metadata."""

    if not reference:
        return deepcopy(default)
    module_name, separator, attribute = reference.partition(":")
    if not separator or not module_name or not attribute:
        raise ValueError(f"invalid provider reference: {reference}")
    if str(config.repository) not in __import__("sys").path:
        __import__("sys").path.insert(0, str(config.repository))
    module = importlib.import_module(module_name)
    value = getattr(module, attribute)
    return deepcopy(value() if callable(value) else value)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Core-owned provider-neutral semantic dialogue harness."
    )
    parser.add_argument(
        "--profile",
        default="core",
        choices=tuple(dict.fromkeys(PROFILE_ALIASES)),
    )
    parser.add_argument("--repository", type=Path)
    parser.add_argument("--core-repository", type=Path)
    parser.add_argument("--dynamic-trading-repository", type=Path)
    parser.add_argument("--lua", type=Path)
    parser.add_argument("--worker-script", type=Path)
    parser.add_argument("--scenario", type=Path)
    parser.add_argument("--input")
    parser.add_argument("--ping", action="store_true")
    parser.add_argument("--capabilities", action="store_true")
    parser.add_argument("--jsonl", action="store_true")
    parser.add_argument("--no-gui", action="store_true")
    parser.add_argument("--gui", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--doctor-json", action="store_true")
    parser.add_argument("--startup-timeout", type=float, default=8.0)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--shutdown-timeout", type=float, default=1.0)
    return parser


def _scenario(arguments: argparse.Namespace, config: HarnessConfig) -> dict[str, Any]:
    if arguments.scenario is not None:
        return load_json_document(arguments.scenario)
    return _provider_value(config, config.provider_python_scenario, {})


def _emit(value: Any, *, jsonl: bool) -> None:
    if jsonl:
        print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))
    else:
        print(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True))


def cli(arguments: argparse.Namespace) -> int:
    config = HarnessConfig.discover(
        repository=arguments.repository,
        core_repository=arguments.core_repository,
        dynamic_trading_repository=arguments.dynamic_trading_repository,
        lua_bin=arguments.lua,
        worker_script=arguments.worker_script,
        profile=arguments.profile,
        startup_timeout=arguments.startup_timeout,
        request_timeout=arguments.timeout,
        shutdown_timeout=arguments.shutdown_timeout,
    )
    with LuaSemanticWorker(_scenario(arguments, config), config=config) as worker:
        if arguments.ping:
            _emit(worker.ping(), jsonl=arguments.jsonl)
        elif arguments.capabilities:
            _emit(worker.capabilities(), jsonl=arguments.jsonl)
        elif arguments.input is not None:
            _emit(worker.input(arguments.input), jsonl=arguments.jsonl)
        else:
            _emit(worker.status(), jsonl=arguments.jsonl)
    return 0


def main(argv: Sequence[str] | None = None) -> int:
    return cli(_parser().parse_args(argv))


__all__ = ["AUTHORING_OPERATIONS", "CLI_OPERATIONS", "_parser", "cli", "main"]
