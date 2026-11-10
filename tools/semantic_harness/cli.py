"""Provider-neutral command-line entry point for Semantic Harness."""

from __future__ import annotations

import argparse
import importlib
import json
from copy import deepcopy
from pathlib import Path
from typing import Any, Sequence

from .mod_manager import ModManager, ModManagerError
from .runtime.config import PROFILE_ALIASES, HarnessConfig, discover_core_repository
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
        help="compatibility preset alias; use --preset or --mods for new selections",
    )
    parser.add_argument("--preset", help="named manifest-driven selection preset")
    parser.add_argument(
        "--mods",
        action="append",
        help="provider IDs to enable; repeat or provide a comma-separated list",
    )
    parser.add_argument(
        "--provider-root",
        action="append",
        type=Path,
        help="repository root to scan for provider manifests",
    )
    parser.add_argument("--list-mods", action="store_true")
    parser.add_argument("--list-presets", action="store_true")
    parser.add_argument("--show-selection", action="store_true")
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
    provider_roots = tuple(arguments.provider_root or ())
    if arguments.list_mods or arguments.list_presets:
        try:
            core = discover_core_repository(
                arguments.core_repository,
                cwd=Path(arguments.repository).expanduser().resolve()
                if arguments.repository is not None
                else None,
            )
            roots = list(provider_roots)
            if arguments.repository is not None:
                roots.append(arguments.repository)
            if arguments.dynamic_trading_repository is not None:
                roots.append(arguments.dynamic_trading_repository)
            manager = ModManager.discover(
                core_repository=core,
                repository_roots=roots,
                cwd=Path.cwd(),
            )
        except (ModManagerError, ValueError) as error:
            raise SystemExit(str(error)) from error
        _emit(
            manager.describe()
            if arguments.list_mods
            else {"schema": "semantic.harness.selection_presets.v1", "presets": list(manager.presets())},
            jsonl=arguments.jsonl,
        )
        return 0

    mods: tuple[str, ...] | None = None
    if arguments.mods:
        mods = tuple(
            item.strip()
            for value in arguments.mods
            for item in str(value).split(",")
            if item.strip()
        )
    config = HarnessConfig.discover(
        repository=arguments.repository,
        core_repository=arguments.core_repository,
        dynamic_trading_repository=arguments.dynamic_trading_repository,
        provider_roots=provider_roots,
        mods=mods,
        preset=arguments.preset,
        lua_bin=arguments.lua,
        worker_script=arguments.worker_script,
        profile=arguments.profile,
        startup_timeout=arguments.startup_timeout,
        request_timeout=arguments.timeout,
        shutdown_timeout=arguments.shutdown_timeout,
    )
    if arguments.show_selection:
        _emit(config.activation_plan or {}, jsonl=arguments.jsonl)
        return 0
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
