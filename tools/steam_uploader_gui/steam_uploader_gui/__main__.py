from __future__ import annotations

import sys


def main() -> int:
    try:
        from .ui.app import run_gui
        return run_gui()
    except ModuleNotFoundError as exc:
        if exc.name in {"tkinter", "_tkinter"}:
            print("Tkinter is required for the GUI. Install the platform's Tk package and try again.", file=sys.stderr)
            return 2
        raise


if __name__ == "__main__":
    raise SystemExit(main())
