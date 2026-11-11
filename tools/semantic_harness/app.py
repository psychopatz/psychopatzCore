"""Executable Core Semantic Harness application."""

from __future__ import annotations

from typing import Sequence

from .cli import AUTHORING_OPERATIONS, CLI_OPERATIONS, _parser, cli
from .process import install_shutdown_handler
from .testing.doctor import run_doctor


def _should_run_cli(arguments: object) -> bool:
    """Select headless mode only when an operation was actually requested.

    The original Project Hoomans harness opened its Tk UI for a bare
    ``run_harness.sh`` invocation.  Keep that file-manager-friendly default
    while preserving explicit CLI and diagnostic operations as headless.
    """

    if getattr(arguments, "no_gui", False):
        return True
    operations = (
        *AUTHORING_OPERATIONS,
        *CLI_OPERATIONS,
        "list_mods",
        "list_presets",
        "show_selection",
    )
    return any(getattr(arguments, operation, None) for operation in operations)


def main(argv: Sequence[str] | None = None) -> int:
    install_shutdown_handler()
    arguments = _parser().parse_args(argv)
    if arguments.doctor or arguments.doctor_json:
        return run_doctor(
            repository=arguments.repository,
            core_repository=arguments.core_repository,
            dynamic_trading_repository=arguments.dynamic_trading_repository,
            provider_roots=tuple(arguments.provider_root or ()),
            mods=tuple(
                item.strip()
                for value in (arguments.mods or ())
                for item in str(value).split(",")
                if item.strip()
            ) or None,
            preset=arguments.preset,
            lua_bin=arguments.lua,
            profile=arguments.profile,
            startup_timeout=arguments.startup_timeout,
            request_timeout=arguments.timeout,
            json_output=arguments.doctor_json,
        )
    if not arguments.gui and _should_run_cli(arguments):
        return cli(arguments)

    from .ui.shell import run_gui

    return run_gui(arguments)


if __name__ == "__main__":
    raise SystemExit(main())
