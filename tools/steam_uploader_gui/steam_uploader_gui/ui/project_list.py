from __future__ import annotations

import tkinter as tk
from collections.abc import Callable, Iterable
from tkinter import ttk

from .theme import configure_listbox


class ProjectList(ttk.Frame):
    """Workshop project navigator independent from the selected profile editor."""

    def __init__(self, master: object, on_selected: Callable[[str], None]) -> None:
        super().__init__(master)
        self.columnconfigure(0, weight=1)
        self.rowconfigure(1, weight=1)
        self.on_selected = on_selected
        self._keys: list[str] = []

        ttk.Label(self, text="Workshop projects").grid(row=0, column=0, sticky="w")
        list_frame = ttk.Frame(self)
        list_frame.grid(row=1, column=0, sticky="nsew", pady=(6, 0))
        list_frame.columnconfigure(0, weight=1)
        list_frame.rowconfigure(0, weight=1)
        self.listbox = tk.Listbox(
            list_frame,
            exportselection=False,
            activestyle="dotbox",
            selectmode="browse",
        )
        self.listbox.grid(row=0, column=0, sticky="nsew")
        scrollbar = ttk.Scrollbar(list_frame, orient="vertical", command=self.listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.listbox.configure(yscrollcommand=scrollbar.set)
        self.listbox.bind("<<ListboxSelect>>", self._selection_changed)

    def set_dark_mode(self, enabled: bool) -> None:
        configure_listbox(self.listbox, enabled)

    def set_projects(self, projects: Iterable[tuple[str, str]]) -> None:
        values = list(projects)
        self._keys = [key for key, _label in values]
        self.listbox.delete(0, "end")
        for _key, label in values:
            self.listbox.insert("end", label)

    def update_label(self, key: str, label: str) -> None:
        if key not in self._keys:
            return
        index = self._keys.index(key)
        self.listbox.delete(index)
        self.listbox.insert(index, label)

    def select_key(self, key: str | None) -> None:
        self.listbox.selection_clear(0, "end")
        if key is None or key not in self._keys:
            return
        index = self._keys.index(key)
        self.listbox.selection_set(index)
        self.listbox.see(index)
        # selection_set does not reliably emit the virtual event before the
        # window enters its event loop. Call the application callback directly
        # so the first discovered mod is actually loaded on startup.
        self.on_selected(key)

    def selected_key(self) -> str | None:
        selected = self.listbox.curselection()
        if not selected:
            return None
        index = selected[0]
        return self._keys[index] if index < len(self._keys) else None

    def _selection_changed(self, _event: object = None) -> None:
        key = self.selected_key()
        if key is not None:
            self.on_selected(key)
