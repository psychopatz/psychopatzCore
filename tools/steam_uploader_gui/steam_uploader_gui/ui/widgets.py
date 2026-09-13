from __future__ import annotations

import tkinter as tk
from collections.abc import Callable
from tkinter import ttk

from .theme import palette


class ScrollableFrame(ttk.Frame):
    """A keyboard- and mouse-scrollable frame that resizes to the viewport width."""

    def __init__(self, master: object, **kwargs: object) -> None:
        super().__init__(master, **kwargs)
        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        self.canvas = tk.Canvas(self, highlightthickness=0, borderwidth=0)
        self.scrollbar = ttk.Scrollbar(self, orient="vertical", command=self.canvas.yview)
        self.canvas.configure(yscrollcommand=self.scrollbar.set)
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.scrollbar.grid(row=0, column=1, sticky="ns")

        self.content = ttk.Frame(self.canvas, padding=(0, 0, 8, 8))
        self._window_id = self.canvas.create_window((0, 0), window=self.content, anchor="nw")
        self.content.bind("<Configure>", self._content_configured)
        self.canvas.bind("<Configure>", self._canvas_configured)
        self.canvas.bind("<Enter>", self._bind_mousewheel)
        self.canvas.bind("<Leave>", self._unbind_mousewheel)

    def set_dark_mode(self, enabled: bool) -> None:
        self.canvas.configure(background=palette(enabled)["bg"])

    def _content_configured(self, _event: object = None) -> None:
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    def _canvas_configured(self, event: tk.Event[tk.Misc]) -> None:
        self.canvas.itemconfigure(self._window_id, width=event.width)

    def _bind_mousewheel(self, _event: object = None) -> None:
        self.canvas.bind_all("<MouseWheel>", self._mousewheel)
        self.canvas.bind_all("<Button-4>", self._mousewheel)
        self.canvas.bind_all("<Button-5>", self._mousewheel)

    def _unbind_mousewheel(self, _event: object = None) -> None:
        self.canvas.unbind_all("<MouseWheel>")
        self.canvas.unbind_all("<Button-4>")
        self.canvas.unbind_all("<Button-5>")

    def _mousewheel(self, event: tk.Event[tk.Misc]) -> None:
        if getattr(event, "num", None) == 4:
            amount = -1
        elif getattr(event, "num", None) == 5:
            amount = 1
        else:
            amount = -int(getattr(event, "delta", 0) / 120) or -1
        self.canvas.yview_scroll(amount, "units")


class CollapsibleSection(ttk.Frame):
    """Reusable section with an accessible button header and persistent body."""

    def __init__(
        self,
        master: object,
        title: str,
        expanded: bool = True,
        on_toggle: Callable[[bool], None] | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(master, **kwargs)
        self.title = title
        self.on_toggle = on_toggle
        self._expanded = False
        self.columnconfigure(0, weight=1)

        self.header = ttk.Frame(self)
        self.header.grid(row=0, column=0, sticky="ew")
        self.header.columnconfigure(0, weight=1)
        self.toggle_button = ttk.Button(
            self.header,
            command=self.toggle,
            style="Toolbutton",
            takefocus=True,
        )
        self.toggle_button.grid(row=0, column=0, sticky="ew")

        self.body = ttk.Frame(self, padding=(8, 4, 8, 8))
        self.set_expanded(expanded, notify=False)

    @property
    def expanded(self) -> bool:
        return self._expanded

    def _update_button(self) -> None:
        marker = "▾" if self._expanded else "▸"
        self.toggle_button.configure(text=f"{marker} {self.title}", takefocus=True)

    def set_expanded(self, expanded: bool, notify: bool = True) -> None:
        self._expanded = bool(expanded)
        if self._expanded:
            self.body.grid(row=1, column=0, sticky="ew")
        else:
            self.body.grid_remove()
        self._update_button()
        if notify and self.on_toggle:
            self.on_toggle(self._expanded)

    def toggle(self) -> None:
        self.set_expanded(not self._expanded)


class VerticalResizeGrip(tk.Canvas):
    """Small drag handle for panels whose content is intentionally resizable."""

    def __init__(
        self,
        master: object,
        on_resize: Callable[[int], None],
        min_height: int = 260,
        max_height: int = 1200,
    ) -> None:
        super().__init__(
            master,
            width=18,
            height=16,
            highlightthickness=0,
            borderwidth=0,
            background="#d9d9d9",
            cursor="sb_v_double_arrow",
        )
        self._on_resize = on_resize
        self._min_height = min_height
        self._max_height = max_height
        self._start_y = 0
        self._start_height = 0
        self._dark_mode = False
        self._draw_grip()
        self.bind("<ButtonPress-1>", self._start_drag)
        self.bind("<B1-Motion>", self._drag)

    def _draw_grip(self) -> None:
        self.delete("all")
        colors = palette(self._dark_mode)
        self.configure(background=colors["surface"])
        for offset in (5, 9, 13):
            self.create_line(
                4,
                offset,
                13,
                offset,
                fill=colors["muted"],
                width=1,
            )

    def set_dark_mode(self, enabled: bool) -> None:
        self._dark_mode = bool(enabled)
        self._draw_grip()

    def _start_drag(self, event: tk.Event[tk.Misc]) -> None:
        parent = self.master
        self._start_y = event.y_root
        self._start_height = max(self._min_height, int(parent.winfo_height()))

    def _drag(self, event: tk.Event[tk.Misc]) -> None:
        height = self._start_height + (event.y_root - self._start_y)
        self._on_resize(max(self._min_height, min(self._max_height, height)))
