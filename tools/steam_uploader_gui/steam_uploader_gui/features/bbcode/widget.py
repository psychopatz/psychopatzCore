from __future__ import annotations

import tkinter as tk
from collections.abc import Callable
from tkinter import ttk

from .formatting import normalize_line_endings, unicode_prefix, wrap_selection
from .renderer import render
from ...ui.theme import configure_menu, configure_text, palette


class BBCodeEditor(ttk.Frame):
    """Source editor with a Steam-like preview and an expanded authoring mode."""

    def __init__(
        self,
        master: object,
        initial: str = "",
        max_length: int | None = None,
        text_height: int | None = None,
        editor_title: str = "Steam Workshop description editor",
        on_change: Callable[[str], None] | None = None,
        allow_expand: bool = True,
        dark_mode: bool = False,
        **kwargs: object,
    ):
        super().__init__(master, **kwargs)
        self.max_length = max_length
        self.text_height = text_height
        self.editor_title = editor_title
        self._on_change = on_change
        self.allow_expand = allow_expand
        self._dark_mode = bool(dark_mode)
        self._expanded_window: tk.Toplevel | None = None
        self._expanded_editor: BBCodeEditor | None = None
        self._syncing_expanded = False
        self._menus: list[tk.Menu] = []
        self._expanded_footer_label: ttk.Label | None = None
        toolbar = ttk.Frame(self)
        toolbar.pack(fill="x", pady=(0, 4))
        for label, opening, closing in (
            ("B", "[b]", "[/b]"), ("I", "[i]", "[/i]"), ("U", "[u]", "[/u]"),
            ("S", "[strike]", "[/strike]"), ("Quote", "[quote]", "[/quote]"),
            ("Code", "[code]", "[/code]"), ("List", "[list]\n[*]", "\n[/list]"),
        ):
            ttk.Button(
                toolbar,
                text=label,
                width=max(4, len(label) + 1),
                command=lambda o=opening, c=closing: self._wrap(o, c),
            ).pack(side="left", padx=(0, 3))

        ttk.Button(
            toolbar,
            text="Link…",
            width=6,
            command=self._insert_link,
        ).pack(side="left", padx=(0, 3))
        ttk.Button(
            toolbar,
            text="Image…",
            width=7,
            command=self._insert_image,
        ).pack(side="left", padx=(0, 3))

        headings = ttk.Menubutton(toolbar, text="Heading ▾")
        heading_menu = tk.Menu(headings, tearoff=False)
        self._menus.append(heading_menu)
        for label, tag in (("Heading 1", "h1"), ("Heading 2", "h2"), ("Heading 3", "h3")):
            heading_menu.add_command(
                label=label,
                command=lambda t=tag: self._wrap(f"[{t}]", f"[/{t}]"),
            )
        headings.configure(menu=heading_menu)
        headings.pack(side="left", padx=(0, 3))

        emoji_button = ttk.Menubutton(toolbar, text="Emoji ▾")
        emoji_menu = tk.Menu(emoji_button, tearoff=False)
        self._menus.append(emoji_menu)
        for group, values in (
            ("Faces", ("😀", "😃", "😂", "😉", "😍", "🤔", "😎", "😭", "😡", "🥳")),
            ("Symbols", ("✅", "❌", "⚠️", "⭐", "🔥", "💡", "❤️", "🎉", "🛠️", "☕")),
            ("Arrows", ("→", "←", "↑", "↓", "↗", "↘", "•", "…", "✓", "★")),
        ):
            submenu = tk.Menu(emoji_menu, tearoff=False)
            self._menus.append(submenu)
            for value in values:
                submenu.add_command(
                    label=value,
                    command=lambda character=value: self._insert_text(character),
                )
            emoji_menu.add_cascade(label=group, menu=submenu)
        emoji_menu.add_separator()
        emoji_menu.add_command(
            label="Insert Unicode character…",
            command=self._show_unicode_help,
        )
        emoji_button.configure(menu=emoji_menu)
        emoji_button.pack(side="left", padx=(0, 3))
        for menu in self._menus:
            configure_menu(menu, self._dark_mode)

        if self.allow_expand:
            ttk.Button(
                toolbar,
                text="Open full editor",
                command=self.open_expanded,
            ).pack(side="left", padx=(8, 3))
        self.unicode_label = ttk.Label(
            toolbar,
            text="Unicode / emoji safe",
        )
        self.unicode_label.pack(side="right", padx=(8, 0))

        self.tabs = ttk.Notebook(self)
        self.tabs.pack(fill="both", expand=True)
        source_frame = ttk.Frame(self.tabs)
        source_frame.columnconfigure(0, weight=1)
        source_frame.rowconfigure(0, weight=1)
        preview_frame = ttk.Frame(self.tabs)
        preview_frame.columnconfigure(0, weight=1)
        preview_frame.rowconfigure(0, weight=1)
        self.tabs.add(source_frame, text="BBCode source")
        self.tabs.add(preview_frame, text="Steam preview")
        text_options: dict[str, object] = {
            "wrap": "word",
            "undo": True,
            "autoseparators": True,
            "exportselection": True,
            "padx": 10,
            "pady": 8,
            "borderwidth": 1,
            "relief": "solid",
        }
        if self.text_height is not None:
            text_options["height"] = self.text_height
        source_text_frame = ttk.Frame(source_frame)
        source_text_frame.grid(row=0, column=0, sticky="nsew")
        source_text_frame.columnconfigure(0, weight=1)
        source_text_frame.rowconfigure(0, weight=1)
        self.source = tk.Text(source_text_frame, **text_options)
        configure_text(self.source, self._dark_mode)
        source_scrollbar = ttk.Scrollbar(
            source_text_frame,
            orient="vertical",
            command=self.source.yview,
        )
        self.source.configure(yscrollcommand=source_scrollbar.set)
        self.source.grid(row=0, column=0, sticky="nsew")
        source_scrollbar.grid(row=0, column=1, sticky="ns")
        preview_options: dict[str, object] = {
            "wrap": "word",
            "state": "disabled",
            "padx": 10,
            "pady": 8,
            "borderwidth": 1,
            "relief": "solid",
        }
        if self.text_height is not None:
            preview_options["height"] = self.text_height
        preview_text_frame = ttk.Frame(preview_frame)
        preview_text_frame.grid(row=0, column=0, sticky="nsew")
        preview_text_frame.columnconfigure(0, weight=1)
        preview_text_frame.rowconfigure(0, weight=1)
        self.preview = tk.Text(preview_text_frame, **preview_options)
        configure_text(self.preview, self._dark_mode, preview=True)
        preview_scrollbar = ttk.Scrollbar(
            preview_text_frame,
            orient="vertical",
            command=self.preview.yview,
        )
        self.preview.configure(yscrollcommand=preview_scrollbar.set)
        self.preview.grid(row=0, column=0, sticky="nsew")
        preview_scrollbar.grid(row=0, column=1, sticky="ns")
        self.counter = ttk.Label(source_frame, anchor="e")
        self.counter.grid(row=1, column=0, sticky="ew", pady=(3, 0))
        self.source.bind("<KeyRelease>", self._source_changed)
        self.source.bind("<<Paste>>", self._source_changed)
        self.source.bind("<Control-Shift-e>", self._open_expanded_event)
        self.source.bind("<Double-Button-1>", self._open_expanded_event)
        self._preview_job: str | None = None
        self._set_source(initial)
        self.refresh_preview()

    def _wrap(self, opening: str, closing: str) -> None:
        wrap_selection(self.source, opening, closing)
        self._source_changed()

    def _insert_text(self, value: str) -> None:
        try:
            self.source.delete("sel.first", "sel.last")
        except tk.TclError:
            pass
        self.source.insert("insert", value)
        self.source.focus_set()
        self._source_changed()

    def _selected_text(self) -> tuple[str, str, str] | None:
        try:
            start = self.source.index("sel.first")
            end = self.source.index("sel.last")
        except tk.TclError:
            return None
        return start, end, self.source.get(start, end)

    def _insert_link(self) -> None:
        from tkinter import simpledialog

        selected = self._selected_text()
        url = simpledialog.askstring(
            "Insert link",
            "Link URL:",
            parent=self.winfo_toplevel(),
        )
        if not url or not url.strip():
            return
        target = url.strip()
        label = selected[2] if selected else target
        markup = f"[url={target}]{label}[/url]"
        if selected:
            self.source.delete(selected[0], selected[1])
            self.source.insert(selected[0], markup)
        else:
            self.source.insert("insert", markup)
        self.source.focus_set()
        self._source_changed()

    def _insert_image(self) -> None:
        from tkinter import simpledialog

        value = simpledialog.askstring(
            "Insert image",
            "Image URL or local file path:",
            parent=self.winfo_toplevel(),
        )
        if not value or not value.strip():
            return
        self._insert_text(f"[img]{value.strip()}[/img]")

    def _show_unicode_help(self) -> None:
        """Explain that arbitrary Unicode can be pasted without an ASCII-only filter."""

        from tkinter import messagebox

        messagebox.showinfo(
            "Unicode and emoji",
            "Paste any Unicode text directly into the editor. Emoji, accented text, CJK, "
            "Arabic, Cyrillic, and other complex characters are stored as UTF-8 and kept "
            "in the Workshop payload.",
            parent=self.winfo_toplevel(),
        )

    def _open_expanded_event(self, _event: object = None) -> str:
        self.open_expanded()
        return "break"

    def _schedule_preview(self, _event: object = None) -> None:
        if self._preview_job:
            self.after_cancel(self._preview_job)
        self._preview_job = self.after(120, self.refresh_preview)

    def _source_changed(self, _event: object = None) -> None:
        self._enforce_limit()
        self._schedule_preview()
        self._emit_changed()

    def _enforce_limit(self) -> None:
        current = self.source.get("1.0", "end-1c")
        source = normalize_line_endings(current)
        if source != current:
            self.source.delete("1.0", "end")
            self.source.insert("1.0", source)
        if self.max_length is not None and len(source) > self.max_length:
            source = unicode_prefix(source, self.max_length)
            self.source.delete("1.0", "end")
            self.source.insert("1.0", source)
        if self.max_length is None:
            self.counter.configure(text="")
        else:
            self.counter.configure(text=f"{len(source):,} / {self.max_length:,} characters")

    def _emit_changed(self) -> None:
        if self._on_change is not None:
            self._on_change(self.get_source())
        # This event also covers programmatic changes mirrored from the expanded
        # editor. The parent editor uses it for dirty-state tracking.
        self.source.event_generate("<<BBCodeChanged>>", when="tail")

    def refresh_preview(self) -> None:
        self._preview_job = None
        self._enforce_limit()
        render(self.preview, self.source.get("1.0", "end-1c"))

    def set_dark_mode(self, enabled: bool) -> None:
        """Update all native Tk controls used by this editor immediately."""

        self._dark_mode = bool(enabled)
        configure_text(self.source, self._dark_mode)
        configure_text(self.preview, self._dark_mode, preview=True)
        for menu in self._menus:
            configure_menu(menu, self._dark_mode)
        colors = palette(self._dark_mode)
        self.unicode_label.configure(foreground=colors["muted"])
        self.refresh_preview()
        if self._expanded_editor is not None:
            self._expanded_editor.set_dark_mode(self._dark_mode)
        if self._expanded_footer_label is not None and self._expanded_footer_label.winfo_exists():
            self._expanded_footer_label.configure(foreground=colors["muted"])

    def get_source(self) -> str:
        return self.source.get("1.0", "end-1c")

    def set_source(self, value: str) -> None:
        self._set_source(value)
        self.refresh_preview()
        if self._expanded_editor is not None and not self._syncing_expanded:
            self._expanded_editor._set_source(self.get_source())
            self._expanded_editor.refresh_preview()

    def _set_source(self, value: str) -> None:
        value = normalize_line_endings(value)
        if self.max_length is not None:
            value = unicode_prefix(value, self.max_length)
        self.source.delete("1.0", "end")
        self.source.insert("1.0", value)
        self._enforce_limit()

    def _sync_from_expanded(self, value: str) -> None:
        if self._syncing_expanded:
            return
        self._syncing_expanded = True
        try:
            self._set_source(value)
            self.refresh_preview()
            self._emit_changed()
        finally:
            self._syncing_expanded = False

    def _close_expanded_window(self, window: tk.Toplevel) -> None:
        if self._expanded_window is window:
            self._expanded_editor = None
            self._expanded_window = None
        if window.winfo_exists():
            window.destroy()

    def close_expanded(self) -> None:
        """Close the detached editor before switching the profile being edited."""

        if self._expanded_window is not None:
            self._close_expanded_window(self._expanded_window)

    def _toggle_fullscreen(self, window: tk.Toplevel, button: ttk.Button) -> None:
        current = str(window.attributes("-fullscreen")).lower() in {"1", "true", "yes"}
        window.attributes("-fullscreen", not current)
        button.configure(text="Exit full screen" if not current else "Full screen")

    def open_expanded(self) -> None:
        """Open a large, resizable editor while keeping the inline editor in sync."""

        if self._expanded_window is not None and self._expanded_window.winfo_exists():
            self._expanded_window.deiconify()
            self._expanded_window.lift()
            self._expanded_window.focus_force()
            return

        window = tk.Toplevel(self.winfo_toplevel())
        window.title(self.editor_title)
        window.minsize(760, 520)
        window.geometry("1040x760")
        try:
            window.state("zoomed")
        except tk.TclError:
            pass
        window.columnconfigure(0, weight=1)
        window.rowconfigure(0, weight=1)

        expanded = BBCodeEditor(
            window,
            initial=self.get_source(),
            max_length=self.max_length,
            text_height=28,
            editor_title=self.editor_title,
            on_change=self._sync_from_expanded,
            allow_expand=False,
            dark_mode=self._dark_mode,
        )
        expanded.grid(row=0, column=0, sticky="nsew", padx=12, pady=(12, 4))
        footer = ttk.Frame(window, padding=(12, 4, 12, 10))
        footer.grid(row=1, column=0, sticky="ew")
        footer.columnconfigure(0, weight=1)
        self._expanded_footer_label = ttk.Label(
            footer,
            text="Changes are applied to the Workshop profile as you type. Ctrl+Shift+E or double-click opens this view.",
        )
        self._expanded_footer_label.grid(row=0, column=0, sticky="w")
        self._expanded_footer_label.configure(foreground=palette(self._dark_mode)["muted"])
        fullscreen_button = ttk.Button(
            footer,
            text="Full screen",
        )
        fullscreen_button.configure(
            command=lambda: self._toggle_fullscreen(window, fullscreen_button),
        )
        fullscreen_button.grid(row=0, column=1, padx=(12, 0))
        ttk.Button(
            footer,
            text="Done",
            command=lambda: self._close_expanded_window(window),
        ).grid(row=0, column=2, padx=(8, 0))

        self._expanded_window = window
        self._expanded_editor = expanded

        def closed() -> None:
            self._close_expanded_window(window)

        window.protocol("WM_DELETE_WINDOW", closed)
        def escape(_event: object = None) -> str:
            if str(window.attributes("-fullscreen")).lower() in {"1", "true", "yes"}:
                self._toggle_fullscreen(window, fullscreen_button)
            else:
                closed()
            return "break"

        window.bind("<Escape>", escape)
        window.focus_force()
