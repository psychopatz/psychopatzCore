from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from .theme import configure_text


class LiveLogPanel(ttk.Frame):
    """Read-only live event stream with a high-contrast default presentation."""

    def __init__(self, master: object) -> None:
        super().__init__(master)
        self.rowconfigure(0, weight=1)
        self.columnconfigure(0, weight=1)
        self.text = tk.Text(self, height=8, state="disabled", wrap="word", undo=False)
        configure_text(self.text, False)
        self.text.grid(row=0, column=0, sticky="nsew")
        scrollbar = ttk.Scrollbar(self, orient="vertical", command=self.text.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.text.configure(yscrollcommand=scrollbar.set)

    def set_dark_mode(self, enabled: bool) -> None:
        configure_text(self.text, enabled)

    def append(self, event: dict[str, object]) -> None:
        line = (
            f"{event.get('timestamp', '')} {event.get('level', ''):<7} "
            f"[{event.get('operation', '')}] {event.get('message', '')}\n"
        )
        self.text.configure(state="normal")
        self.text.insert("end", line)
        self.text.see("end")
        self.text.configure(state="disabled")
