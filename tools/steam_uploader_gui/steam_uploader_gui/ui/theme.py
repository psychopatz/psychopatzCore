from __future__ import annotations

import tkinter as tk
from tkinter import ttk


LIGHT_PALETTE = {
    "bg": "#d9d9d9",
    "surface": "#e6e6e6",
    "field": "#ffffff",
    "fg": "#1f2328",
    "muted": "#65727e",
    "border": "#b7b7b7",
    "select_bg": "#4f7cac",
    "select_fg": "#ffffff",
    "text_bg": "#ffffff",
    "text_fg": "#1f2328",
    "code_bg": "#eeeeee",
    "quote": "#666666",
    "link": "#1565c0",
}

DARK_PALETTE = {
    "bg": "#20242a",
    "surface": "#252b33",
    "field": "#30363d",
    "fg": "#e6edf3",
    "muted": "#9aa7b3",
    "border": "#4b5563",
    "select_bg": "#2f81f7",
    "select_fg": "#ffffff",
    "text_bg": "#161b22",
    "text_fg": "#e6edf3",
    "code_bg": "#2b3139",
    "quote": "#a7b0ba",
    "link": "#66b3ff",
}


def palette(dark_mode: bool) -> dict[str, str]:
    return dict(DARK_PALETTE if dark_mode else LIGHT_PALETTE)


def apply_theme(root: tk.Misc, dark_mode: bool) -> dict[str, str]:
    """Apply the shared palette to ttk widgets and return its colors."""

    colors = palette(dark_mode)
    style = ttk.Style(root)
    try:
        style.theme_use("clam")
    except tk.TclError:
        pass

    root.configure(background=colors["bg"])
    style.configure("TFrame", background=colors["bg"])
    style.configure("TLabel", background=colors["bg"], foreground=colors["fg"])
    style.configure("TLabelframe", background=colors["bg"], foreground=colors["fg"])
    style.configure("TLabelframe.Label", background=colors["bg"], foreground=colors["fg"])
    style.configure("TButton", background=colors["surface"], foreground=colors["fg"])
    style.map(
        "TButton",
        background=[("active", colors["select_bg"]), ("pressed", colors["select_bg"])],
        foreground=[("active", colors["select_fg"]), ("pressed", colors["select_fg"])],
    )
    style.configure("Toolbutton", background=colors["surface"], foreground=colors["fg"])
    style.map(
        "Toolbutton",
        background=[("active", colors["select_bg"]), ("pressed", colors["select_bg"])],
        foreground=[("active", colors["select_fg"]), ("pressed", colors["select_fg"])],
    )
    style.configure("TCheckbutton", background=colors["bg"], foreground=colors["fg"])
    style.map("TCheckbutton", background=[("active", colors["surface"])])
    style.configure("TEntry", fieldbackground=colors["field"], foreground=colors["fg"])
    style.configure("TCombobox", fieldbackground=colors["field"], foreground=colors["fg"])
    style.map(
        "TCombobox",
        fieldbackground=[("readonly", colors["field"])],
        foreground=[("readonly", colors["fg"])],
    )
    style.configure("TNotebook", background=colors["bg"], bordercolor=colors["border"])
    style.configure(
        "TNotebook.Tab",
        background=colors["surface"],
        foreground=colors["fg"],
        padding=(8, 3),
    )
    style.map(
        "TNotebook.Tab",
        background=[("selected", colors["field"]), ("active", colors["surface"])],
        foreground=[("selected", colors["fg"])],
    )
    style.configure("TScrollbar", background=colors["surface"], troughcolor=colors["bg"])
    style.configure("TPanedwindow", background=colors["bg"])
    style.configure("TScale", background=colors["bg"], troughcolor=colors["surface"])
    style.configure("TSeparator", background=colors["border"])
    return colors


def configure_text(widget: tk.Text, dark_mode: bool, *, preview: bool = False) -> None:
    colors = palette(dark_mode)
    widget.configure(
        background=colors["text_bg"] if preview else colors["field"],
        foreground=colors["text_fg"],
        insertbackground=colors["fg"],
        selectbackground=colors["select_bg"],
        selectforeground=colors["select_fg"],
        highlightbackground=colors["border"],
        highlightcolor=colors["select_bg"],
    )


def configure_listbox(widget: tk.Listbox, dark_mode: bool) -> None:
    colors = palette(dark_mode)
    widget.configure(
        background=colors["field"],
        foreground=colors["text_fg"],
        selectbackground=colors["select_bg"],
        selectforeground=colors["select_fg"],
    )


def configure_menu(menu: tk.Menu, dark_mode: bool) -> None:
    colors = palette(dark_mode)
    menu.configure(
        background=colors["surface"],
        foreground=colors["fg"],
        activebackground=colors["select_bg"],
        activeforeground=colors["select_fg"],
        disabledforeground=colors["muted"],
    )
