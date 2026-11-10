"""Executable Core Semantic Harness application."""

from __future__ import annotations

from typing import Sequence

from .cli import _parser, cli
from .process import install_shutdown_handler
from .testing.doctor import run_doctor


def main(argv: Sequence[str] | None = None) -> int:
    install_shutdown_handler()
    arguments = _parser().parse_args(argv)
    if arguments.doctor or arguments.doctor_json:
        return run_doctor(
            repository=arguments.repository,
            core_repository=arguments.core_repository,
            lua_bin=arguments.lua,
            profile=arguments.profile,
            startup_timeout=arguments.startup_timeout,
            request_timeout=arguments.timeout,
            json_output=arguments.doctor_json,
        )
    if arguments.gui and not arguments.no_gui:
        from .ui.shell import run_gui

        return run_gui(arguments)
    return cli(arguments)


if __name__ == "__main__":
    raise SystemExit(main())
