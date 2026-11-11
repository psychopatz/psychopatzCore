"""Tkinter chat UI and CLI for the real-Lua semantic dialogue harness."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Sequence

if __package__ in {None, ""}:
    # Preserve direct ``python tools/semantic_harness/app.py`` execution.
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from tools.semantic_harness.cli import AUTHORING_OPERATIONS, CLI_OPERATIONS, _parser, cli
    from tools.semantic_harness.testing.doctor import run_doctor
    from tools.semantic_harness.ui.shell import SemanticHarnessApp, run_gui
    from tools.semantic_harness.process import install_shutdown_handler
    from tools.semantic_harness.inspection.rendering import pretty, print_result as _print_result
else:
    from .cli import AUTHORING_OPERATIONS, CLI_OPERATIONS, _parser, cli
    from tools.semantic_harness.testing.doctor import run_doctor
    from .ui.shell import SemanticHarnessApp, run_gui
    from tools.semantic_harness.process import install_shutdown_handler
    from tools.semantic_harness.inspection.rendering import pretty, print_result as _print_result


def _should_run_cli(arguments: object) -> bool:
    if getattr(arguments, "no_gui", False):
        return True
    return any(
        getattr(arguments, operation, None)
        for operation in (
            *AUTHORING_OPERATIONS,
            *CLI_OPERATIONS,
            "list_mods",
            "list_presets",
            "show_selection",
        )
    )


def main(argv: Sequence[str] | None = None) -> int:
    install_shutdown_handler()
    arguments = _parser().parse_args(argv)
    if arguments.doctor or arguments.doctor_json:
        return run_doctor(
            repository=arguments.repository,
            core_repository=arguments.core_repository,
            dynamic_trading_repository=getattr(arguments, "dynamic_trading_repository", None),
            provider_roots=tuple(getattr(arguments, "provider_root", None) or ()),
            mods=tuple(
                item.strip()
                for value in (getattr(arguments, "mods", None) or ())
                for item in str(value).split(",")
                if item.strip()
            ) or None,
            preset=getattr(arguments, "preset", None),
            lua_bin=arguments.lua,
            profile=arguments.profile,
            startup_timeout=arguments.startup_timeout,
            request_timeout=arguments.timeout,
            json_output=arguments.doctor_json,
        )
    if not arguments.gui and _should_run_cli(arguments):
        return cli(arguments)
    return run_gui(arguments)


if __name__ == "__main__":
    raise SystemExit(main())
