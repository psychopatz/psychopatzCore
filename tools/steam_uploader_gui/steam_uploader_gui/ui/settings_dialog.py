from __future__ import annotations

import tkinter as tk
from collections.abc import Callable
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

from ..core.config import (
    SETTING_DARK_MODE,
    SETTING_IDENTIFIER_EDITING,
    SETTING_UPLOADER_PATH,
    SETTING_WORKSHOP_ROOT,
    default_database_path,
    default_log_dir,
)
from ..persistence.database import SettingsDatabase


class SettingsDialog(tk.Toplevel):
    """Persisted application settings that are independent of a mod profile."""

    def __init__(
        self,
        parent: tk.Misc,
        database: SettingsDatabase,
        workshop_root: str,
        uploader_path: str,
        identifier_editing: bool,
        dark_mode: bool,
        on_saved: Callable[[str, str, bool, bool], None],
    ) -> None:
        super().__init__(parent)
        self.database = database
        self.on_saved = on_saved
        self.title("Steam Uploader Settings")
        self.transient(parent)
        self.resizable(False, False)

        self.workshop_root_var = tk.StringVar(value=workshop_root)
        self.uploader_path_var = tk.StringVar(value=uploader_path)
        self.identifier_editing_var = tk.BooleanVar(value=identifier_editing)
        self.dark_mode_var = tk.BooleanVar(value=dark_mode)
        self._build()
        self.protocol("WM_DELETE_WINDOW", self.destroy)
        self.grab_set()
        self.focus_force()

    def _build(self) -> None:
        frame = ttk.Frame(self, padding=14)
        frame.pack(fill="both", expand=True)
        frame.columnconfigure(1, weight=1)

        ttk.Label(frame, text="Workshop root").grid(row=0, column=0, sticky="w", pady=4)
        ttk.Entry(frame, textvariable=self.workshop_root_var, width=64).grid(
            row=0, column=1, sticky="ew", padx=8, pady=4
        )
        ttk.Button(frame, text="Browse…", command=self._browse_workshop_root).grid(row=0, column=2, pady=4)

        ttk.Label(frame, text="SteamUploader executable").grid(row=1, column=0, sticky="w", pady=4)
        ttk.Entry(frame, textvariable=self.uploader_path_var, width=64).grid(
            row=1, column=1, sticky="ew", padx=8, pady=4
        )
        ttk.Button(frame, text="Browse…", command=self._browse_uploader).grid(row=1, column=2, pady=4)

        ttk.Checkbutton(
            frame,
            text="Enable identifier editing (unsafe)",
            variable=self.identifier_editing_var,
        ).grid(row=2, column=0, columnspan=3, sticky="w", pady=(6, 4))
        ttk.Label(
            frame,
            text="Allows changing App ID and Workshop ID in the project editor.",
        ).grid(row=3, column=0, columnspan=3, sticky="w", pady=(0, 4))

        ttk.Checkbutton(
            frame,
            text="Use dark mode",
            variable=self.dark_mode_var,
        ).grid(row=4, column=0, columnspan=3, sticky="w", pady=(6, 4))

        ttk.Separator(frame).grid(row=5, column=0, columnspan=3, sticky="ew", pady=10)
        ttk.Label(frame, text="Database").grid(row=6, column=0, sticky="w", pady=2)
        ttk.Label(frame, text=str(default_database_path())).grid(
            row=6, column=1, columnspan=2, sticky="w", padx=8, pady=2
        )
        ttk.Label(frame, text="Log directory").grid(row=7, column=0, sticky="w", pady=2)
        ttk.Label(frame, text=str(default_log_dir())).grid(
            row=7, column=1, columnspan=2, sticky="w", padx=8, pady=2
        )
        ttk.Label(
            frame,
            text="The uploader path is stored in the SQLite settings database and used for future uploads.",
            wraplength=520,
        ).grid(row=8, column=0, columnspan=3, sticky="w", pady=(12, 4))

        actions = ttk.Frame(frame)
        actions.grid(row=9, column=0, columnspan=3, sticky="e", pady=(10, 0))
        ttk.Button(actions, text="Cancel", command=self.destroy).pack(side="right")
        ttk.Button(actions, text="Save settings", command=self._save).pack(side="right", padx=(0, 8))

    def _browse_workshop_root(self) -> None:
        selected = filedialog.askdirectory(
            parent=self,
            initialdir=self.workshop_root_var.get() or str(Path.home()),
        )
        if selected:
            self.workshop_root_var.set(selected)

    def _browse_uploader(self) -> None:
        current = Path(self.uploader_path_var.get()).expanduser()
        initialdir = str(current.parent if current.parent.exists() else Path.home())
        selected = filedialog.askopenfilename(parent=self, initialdir=initialdir)
        if selected:
            self.uploader_path_var.set(selected)

    def _save(self) -> None:
        workshop_text = self.workshop_root_var.get().strip()
        uploader_text = self.uploader_path_var.get().strip()
        if not workshop_text:
            messagebox.showerror("Settings", "Choose a Workshop root directory.", parent=self)
            return
        if not uploader_text:
            messagebox.showerror("Settings", "Choose the SteamUploader executable.", parent=self)
            return

        workshop_root = str(Path(workshop_text).expanduser())
        uploader_path = str(Path(uploader_text).expanduser())
        self.database.set_setting(SETTING_WORKSHOP_ROOT, workshop_root)
        self.database.set_setting(SETTING_UPLOADER_PATH, uploader_path)
        self.database.set_setting(
            SETTING_IDENTIFIER_EDITING,
            "1" if self.identifier_editing_var.get() else "0",
        )
        self.database.set_setting(SETTING_DARK_MODE, "1" if self.dark_mode_var.get() else "0")
        self.on_saved(
            workshop_root,
            uploader_path,
            self.identifier_editing_var.get(),
            self.dark_mode_var.get(),
        )
        self.destroy()
