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
        self.config = HarnessConfig.discover(
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
        self.worker = LuaSemanticWorker(_scenario(arguments, self.config), config=self.config)
        self.input_var = tk.StringVar()
        self.output = tk.Text(root, width=100, height=30, state="disabled")
        self.output.pack(fill="both", expand=True, padx=8, pady=8)
        controls = ttk.Frame(root)
        controls.pack(fill="x", padx=8, pady=(0, 8))
        ttk.Entry(controls, textvariable=self.input_var).pack(side="left", fill="x", expand=True)
        ttk.Button(controls, text="Send", command=self.submit).pack(side="left", padx=(8, 0))
        root.protocol("WM_DELETE_WINDOW", self.close)

    def _append(self, value: Any) -> None:
        self.output.configure(state="normal")
        self.output.insert("end", json.dumps(value, ensure_ascii=False, indent=2) + "\n")
        self.output.configure(state="disabled")
        self.output.see("end")

    def submit(self) -> None:
        text = self.input_var.get().strip()
        if not text:
            return
        self.input_var.set("")
        self._append(self.worker.input(text))

    def close(self) -> None:
        self.worker.close()
        self.root.destroy()


def run_gui(arguments: Any) -> int:
    import tkinter as tk

    root = tk.Tk()
    root.title("Semantic Harness")
    SemanticHarnessApp(root, arguments)
    root.mainloop()
    return 0


__all__ = ["SemanticHarnessApp", "run_gui"]
