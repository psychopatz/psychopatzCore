"""Small provider-neutral Tk shell for interactive Core profiles."""

from __future__ import annotations

import json
from typing import Any

from ..cli import _scenario
from ..runtime.config import HarnessConfig
from ..runtime.worker import LuaSemanticWorker


class SemanticHarnessApp:
    """Render bounded worker responses without owning provider UI policy."""

    def __init__(self, root: Any, arguments: Any) -> None:
        import tkinter as tk
        from tkinter import ttk

        self.root = root
        self.arguments = arguments
        self.config: HarnessConfig | None = None
        self.worker: LuaSemanticWorker | None = None
        self.input_var = tk.StringVar()
        self.status_var = tk.StringVar(value="Starting semantic harness…")

        root.title("Semantic Harness")
        root.minsize(720, 480)
        ttk.Label(root, textvariable=self.status_var).pack(
            fill="x", padx=8, pady=(8, 0)
        )
        self.output = tk.Text(root, width=100, height=30, state="disabled")
        self.output.pack(fill="both", expand=True, padx=8, pady=8)
        controls = ttk.Frame(root)
        controls.pack(fill="x", padx=8, pady=(0, 8))
        self.entry = ttk.Entry(controls, textvariable=self.input_var)
        self.entry.pack(side="left", fill="x", expand=True)
        self.send_button = ttk.Button(
            controls, text="Send", command=self.submit, state="disabled"
        )
        self.send_button.pack(side="left", padx=(8, 0))
        root.protocol("WM_DELETE_WINDOW", self.close)
        root.after(10, self._start_worker)

    def _selected_mods(self) -> tuple[str, ...] | None:
        values = getattr(self.arguments, "mods", None) or ()
        selected = tuple(
            item.strip()
            for value in values
            for item in str(value).split(",")
            if item.strip()
        )
        return selected or None

    def _start_worker(self) -> None:
        try:
            self.config = HarnessConfig.discover(
                repository=self.arguments.repository,
                core_repository=self.arguments.core_repository,
                dynamic_trading_repository=self.arguments.dynamic_trading_repository,
                provider_roots=tuple(self.arguments.provider_root or ()),
                mods=self._selected_mods(),
                preset=self.arguments.preset,
                lua_bin=self.arguments.lua,
                worker_script=self.arguments.worker_script,
                profile=self.arguments.profile,
                startup_timeout=self.arguments.startup_timeout,
                request_timeout=self.arguments.timeout,
                shutdown_timeout=self.arguments.shutdown_timeout,
            )
            self.worker = LuaSemanticWorker(
                _scenario(self.arguments, self.config), config=self.config
            )
            self.status_var.set(
                "Ready — " + (self.config.profile or "core")
            )
            self.entry.configure(state="normal")
            self.send_button.configure(state="normal")
            self.entry.focus_set()
        except Exception as error:
            self.status_var.set("Startup failed — see output")
            self._append(
                {
                    "ok": False,
                    "type": "startup_error",
                    "error": f"{type(error).__name__}: {error}",
                }
            )

    def _append(self, value: Any) -> None:
        self.output.configure(state="normal")
        self.output.insert("end", json.dumps(value, ensure_ascii=False, indent=2) + "\n")
        self.output.configure(state="disabled")
        self.output.see("end")

    def submit(self) -> None:
        text = self.input_var.get().strip()
        if not text or self.worker is None:
            return
        self.input_var.set("")
        self._append(self.worker.input(text))

    def close(self) -> None:
        if self.worker is not None:
            self.worker.close()
        self.root.destroy()


def run_gui(arguments: Any) -> int:
    import tkinter as tk

    root = tk.Tk()
    SemanticHarnessApp(root, arguments)
    root.mainloop()
    return 0


__all__ = ["SemanticHarnessApp", "run_gui"]
