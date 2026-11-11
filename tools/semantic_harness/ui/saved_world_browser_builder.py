"""Build the read-only saved-world browser surface."""

from __future__ import annotations

from typing import Any

from .saved_world_relationship_projection import RELATIONSHIP_CATEGORY_LABELS

def build_saved_world_browser(self, parent: Any) -> None:
    """Build the save-backed world browser as a full-width Lab surface."""

    ttk = self._ttk
    parent.columnconfigure(0, weight=1)
    parent.rowconfigure(1, weight=1)

    self.saved_world_save_var = self._tk.StringVar(value="")
    self.saved_world_player_var = self._tk.StringVar(value="")
    self.saved_world_search_var = self._tk.StringVar(
        value=str(self._ui_state.get("saved_world_search") or "")
    )
    self.saved_world_view_var = self._tk.StringVar(
        value=str(
            self._ui_state.get("saved_world_view")
            or "Relationship to Player"
        )
    )
    self.saved_world_category_var = self._tk.StringVar(value="")
    self.saved_world_relationship_category_var = self._tk.StringVar(
        value=str(
            self._ui_state.get("saved_world_relationship_category")
            or "All relationship categories"
        )
    )
    self.saved_world_npc_var = self._tk.StringVar(value="")
    self.saved_world_status_var = self._tk.StringVar(
        value="Discover compatible saves to browse the persisted world."
    )
    self.saved_world_target_var = self._tk.StringVar(
        value="No saved Player/NPC pair loaded"
    )

    header = ttk.LabelFrame(parent, text="Saved World · read-only source", padding=8)
    header.grid(row=0, column=0, sticky="ew", pady=(0, 8))
    header.columnconfigure(1, weight=1)
    header.columnconfigure(4, weight=1)
    ttk.Label(header, text="Save").grid(row=0, column=0, sticky="w", padx=(0, 6))
    self.saved_world_save_box = ttk.Combobox(
        header,
        textvariable=self.saved_world_save_var,
        state="disabled",
        width=40,
    )
    self.saved_world_save_box.grid(row=0, column=1, sticky="ew", padx=(0, 8))
    self.saved_world_save_box.bind(
        "<<ComboboxSelected>>", lambda _event: self._on_saved_world_save()
    )
    self.saved_world_discover_button = ttk.Button(
        header,
        text="Reload saves",
        command=self._discover_saved_worlds,
    )
    self.saved_world_discover_button.grid(row=0, column=2, sticky="w", padx=(0, 18))
    ttk.Label(header, text="Player").grid(row=0, column=3, sticky="w", padx=(0, 6))
    self.saved_world_player_box = ttk.Combobox(
        header,
        textvariable=self.saved_world_player_var,
        state="disabled",
        width=28,
    )
    self.saved_world_player_box.grid(row=0, column=4, sticky="ew", padx=(0, 8))
    self.saved_world_player_box.bind(
        "<<ComboboxSelected>>", lambda _event: self._on_saved_world_player()
    )
    self.saved_world_inspect_button = ttk.Button(
        header,
        text="Refresh world",
        command=self._inspect_saved_world,
    )
    self.saved_world_inspect_button.grid(row=0, column=5, sticky="w")

    ttk.Label(header, text="Search world").grid(
        row=1, column=0, sticky="w", padx=(0, 6), pady=(8, 0)
    )
    search_entry = ttk.Entry(header, textvariable=self.saved_world_search_var)
    search_entry.grid(row=1, column=1, sticky="ew", pady=(8, 0))
    search_entry.bind("<KeyRelease>", lambda _event: self._render_saved_world_tree())
    ttk.Label(header, text="View").grid(
        row=1, column=2, sticky="w", padx=(12, 6), pady=(8, 0)
    )
    self.saved_world_view_box = ttk.Combobox(
        header,
        textvariable=self.saved_world_view_var,
        values=("Relationship to Player", "Saved affiliations"),
        state="readonly",
        width=28,
    )
    self.saved_world_view_box.grid(
        row=1, column=3, columnspan=2, sticky="ew", pady=(8, 0)
    )
    self.saved_world_view_box.bind(
        "<<ComboboxSelected>>", lambda _event: self._on_saved_world_view()
    )
    self.saved_world_import_button = ttk.Button(
        header,
        text="Load selected NPC",
        command=self._import_saved_world_target,
    )
    self.saved_world_import_button.grid(row=1, column=5, sticky="w", pady=(8, 0))
    navigation = ttk.LabelFrame(header, text="Top-level world navigation", padding=(4, 3))
    navigation.grid(row=2, column=0, columnspan=6, sticky="ew", pady=(8, 0))
    navigation.columnconfigure(1, weight=1)
    ttk.Label(navigation, text="Relationship categories").grid(
        row=0, column=0, sticky="nw", padx=(0, 8)
    )
    self.saved_world_relationship_nav_buttons = {}
    all_categories = ("All relationship categories",) + RELATIONSHIP_CATEGORY_LABELS
    for index, label in enumerate(all_categories):
        button = ttk.Button(
            navigation,
            text=label,
            command=lambda value=label: self._select_saved_world_relationship_category(value),
        )
        button.grid(
            row=index // 3,
            column=1 + (index % 3),
            sticky="ew",
            padx=(0 if index % 3 == 0 else 4, 0),
            pady=(0 if index < 3 else 3, 0),
        )
        self.saved_world_relationship_nav_buttons[label] = button
    saved_button = ttk.Button(
        navigation,
        text="Saved affiliations / overlays",
        command=lambda: self._select_saved_world_relationship_category(
            "Saved affiliations / overlays"
        ),
    )
    saved_button.grid(row=3, column=1, columnspan=3, sticky="ew", pady=(3, 0))
    self.saved_world_relationship_nav_buttons["Saved affiliations / overlays"] = saved_button
    ttk.Label(
        header,
        textvariable=self.saved_world_target_var,
        anchor="w",
    ).grid(row=3, column=0, columnspan=6, sticky="ew", pady=(8, 0))
    ttk.Label(
        header,
        textvariable=self.saved_world_status_var,
        anchor="w",
        justify="left",
        wraplength=1000,
    ).grid(row=4, column=0, columnspan=6, sticky="ew", pady=(4, 0))

    browser_frame = ttk.LabelFrame(parent, text="World", padding=6)
    browser_frame.grid(row=1, column=0, sticky="nsew")
    browser_frame.rowconfigure(0, weight=1)
    browser_frame.columnconfigure(0, weight=1)
    browser_frame.columnconfigure(2, weight=1, minsize=300)
    self.saved_world_tree = ttk.Treeview(
        browser_frame,
        columns=("kind", "source", "group"),
        show="tree headings",
        selectmode="browse",
    )
    self.saved_world_tree.heading("#0", text="Saved actors")
    self.saved_world_tree.heading("kind", text="Type")
    self.saved_world_tree.heading("source", text="Source")
    self.saved_world_tree.heading("group", text="Affiliation / lens")
    self.saved_world_tree.column("#0", minwidth=260, width=520, stretch=True)
    self.saved_world_tree.column("kind", minwidth=110, width=150, stretch=False)
    self.saved_world_tree.column("source", minwidth=90, width=110, stretch=False)
    self.saved_world_tree.column("group", minwidth=160, width=220, stretch=False)
    for tag, foreground in {
        "relationship_companion": "#18794e",
        "relationship_hostile": "#b42318",
        "relationship_trader": "#8a5a00",
        "relationship_settler": "#2457a6",
        "relationship_neutral": "#5b6470",
        "relationship_other": "#6b3f8f",
        "relationship_unknown": "#7a7a7a",
    }.items():
        self.saved_world_tree.tag_configure(tag, foreground=foreground)
    self.saved_world_tree.grid(row=0, column=0, sticky="nsew")
    tree_scroll = ttk.Scrollbar(
        browser_frame, orient="vertical", command=self.saved_world_tree.yview
    )
    tree_scroll.grid(row=0, column=1, sticky="ns")
    self.saved_world_tree.configure(yscrollcommand=tree_scroll.set)
    group_frame = ttk.LabelFrame(
        browser_frame,
        text="World context · read-only",
        padding=6,
    )
    group_frame.grid(row=0, column=2, sticky="nsew", padx=(8, 0))
    group_frame.rowconfigure(2, weight=1)
    group_frame.columnconfigure(0, weight=1)
    self.saved_world_group_title_var = self._tk.StringVar(
        value="Select a relationship category, faction, community, or overlay"
    )
    self.saved_world_group_source_var = self._tk.StringVar(value="Source: MISSING")
    ttk.Label(
        group_frame,
        textvariable=self.saved_world_group_title_var,
        anchor="w",
        wraplength=360,
    ).grid(row=0, column=0, sticky="ew", pady=(0, 2))
    ttk.Label(
        group_frame,
        textvariable=self.saved_world_group_source_var,
        anchor="w",
        wraplength=360,
    ).grid(row=1, column=0, sticky="ew", pady=(0, 4))
    self.saved_world_group_inspector = self._ScrolledText(
        group_frame,
        wrap="word",
        height=16,
        width=38,
        state="disabled",
    )
    self.saved_world_group_inspector.grid(
        row=2, column=0, sticky="nsew", pady=(2, 0)
    )
    self.saved_world_tree.bind(
        "<<TreeviewSelect>>", lambda _event: self._on_saved_world_tree_select()
    )
    self.saved_world_tree.bind(
        "<Double-1>", lambda _event: self._import_saved_world_target()
    )
    self.saved_world_tree.bind(
        "<<TreeviewOpen>>", lambda _event: self._save_ui_state()
    )
    self.saved_world_tree.bind(
        "<<TreeviewClose>>", lambda _event: self._save_ui_state()
    )
    self.saved_world_tree_root_iid = "world-root"
    self.saved_world_tree_actor_rows: dict[str, dict[str, Any]] = {}
    self.saved_world_tree_group_nodes: dict[str, dict[str, Any]] = {}
    self.saved_world_tree_actor_groups: dict[str, str] = {}


__all__ = ["build_saved_world_browser"]
