from __future__ import annotations

from typing import Any

from .simulation_workbench_layout import (
    ACTOR_WORKBENCH_TABS,
    WORKBENCH_PANEL_NAMES,
    page_layout,
    section_order,
)
from .workbench import ActorInventoryView, InventoryGiftWorkbench, WorkbenchPage

def build_simulation_workbench(self) -> None:
    for tab_id in self.workbench_notebook.tabs():
        self.workbench_notebook.forget(tab_id)
    self.workbench_control_fields = {}
    self.workbench_panel_notebooks = {}
    self.trait_effects_var = None
    self.trait_effects_widget = None
    self.trait_effects_widgets = {}
    self.inventory_gift_workbench: InventoryGiftWorkbench | None = None
    catalog_controls = self.simulation_control_catalog.get("controls", [])
    if not isinstance(catalog_controls, list):
        catalog_controls = []
    control_limit = min(
        int(self.simulation_control_catalog.get("maxControls", 64) or 64),
        96,
    )
    self.workbench_controls = [
        control
        for control in catalog_controls[:control_limit]
        if (
            isinstance(control, dict)
            and control.get("workbench") is True
            and control.get("workbenchVisible", True) is not False
        )
    ]
    pages: dict[tuple[str, str], WorkbenchPage] = {}
    page_controls: dict[tuple[str, str], list[dict[str, Any]]] = {}
    self.actor_overview_summaries: dict[str, Any] = {}
    self.actor_needs_summaries: dict[str, Any] = {}
    self.actor_traits_summaries: dict[str, Any] = {}
    self.actor_inventory_views: dict[str, ActorInventoryView] = {}
    self.faction_context_summary: Any | None = None

    for panel_name in WORKBENCH_PANEL_NAMES:
        panel = self._ttk.Frame(self.workbench_notebook, padding=(6, 2))
        panel.rowconfigure(0, weight=1)
        panel.columnconfigure(0, weight=1)
        self.workbench_notebook.add(panel, text=panel_name)
        if panel_name in {"NPC Target", "Player"}:
            notebook = self._ttk.Notebook(panel)
            notebook.grid(row=0, column=0, sticky="nsew")
            self.workbench_panel_notebooks[panel_name] = notebook
            notebook.bind(
                "<<NotebookTabChanged>>",
                lambda _event, selected_panel=panel_name: (
                    self._on_actor_panel_tab_changed(selected_panel)
                ),
            )
            panel_tabs = ACTOR_WORKBENCH_TABS + (("Dossier", "Interactions")
                if panel_name == "NPC Target" else ())
            for tab_name in panel_tabs:
                page = WorkbenchPage(
                    notebook,
                    self._tk,
                    self._ttk,
                    self._ScrolledText,
                    self,
                    layout=page_layout(panel_name, tab_name),
                )
                page.frame.grid(row=0, column=0, sticky="nsew")
                notebook.add(page.frame, text=tab_name)
                pages[(panel_name, tab_name)] = page
        else:
            page = WorkbenchPage(
                panel,
                self._tk,
                self._ttk,
                self._ScrolledText,
                self,
                layout=page_layout(panel_name, "Overview"),
            )
            page.frame.grid(row=0, column=0, sticky="nsew")
            pages[(panel_name, "Overview")] = page

    faction_page = pages[("Faction / Community", "Overview")]
    self.faction_context_summary = faction_page.add_summary(
        "Selected faction / community · read-only source",
        height=18,
    )
    faction_page.finish()

    for panel_name in ("NPC Target", "Player"):
        overview = pages[(panel_name, "Overview")]
        self.actor_overview_summaries[panel_name] = overview.add_summary(
            "Actor identity · read-only source",
            height=7,
        )
        needs = pages[(panel_name, "Needs")]
        self.actor_needs_summaries[panel_name] = needs.add_summary(
            "Needs provenance",
            height=3,
        )
        traits = pages[(panel_name, "Personality & Traits")]
        self.actor_traits_summaries[panel_name] = traits.add_summary(
            "Personality / traits provenance",
            height=5,
        )
        inventory = pages[(panel_name, "Inventory")]
        inventory_view = ActorInventoryView(
            inventory.content,
            self,
            "player" if panel_name == "Player" else "npc",
        )
        inventory.add_widget(inventory_view.frame, sticky="nsew")
        self.actor_inventory_views[panel_name] = inventory_view
        inventory.finish()

    dossier_page = pages.get(("NPC Target", "Dossier"))
    if dossier_page is not None:
        self.npc_dossier_summary = dossier_page.add_summary(
            "Production dossier / known information",
            height=18,
        )
        dossier_page.finish()
    interaction_page = pages.get(("NPC Target", "Interactions"))
    if interaction_page is not None:
        self.npc_interaction_summary = interaction_page.add_summary(
            "Production relationship history",
            height=18,
        )
        interaction_page.finish()

    for control in self.workbench_controls:
        panel_name = str(control.get("workbenchPanel") or "World")
        if panel_name not in WORKBENCH_PANEL_NAMES:
            panel_name = "World"
        tab_name = str(control.get("workbenchTab") or "Overview")
        if (panel_name, tab_name) not in pages:
            tab_name = "Overview"
        page_controls.setdefault((panel_name, tab_name), []).append(control)

    for page_key, controls in page_controls.items():
        controls.sort(key=section_order)
        page = pages[page_key]
        for control in controls:
            page.add_section(control.get("workbenchSection"))
            field = page.add_control(
                control,
                self._scenario_control_value(control, self.scenario),
            )
            control_id = str(control["id"])
            if control_id == "runtime.language":
                field.variable = self.language_var
                field.widget.configure(textvariable=self.language_var)
                self.language_box = field.widget
            self.workbench_control_fields[control_id] = field
            if control_id in {"persona.traits", "player.traits"}:
                actor = "npc" if control_id == "persona.traits" else "player"
                title = (
                    "Production trait effects"
                    if actor == "npc"
                    else "Production-derived social profile"
                )
                effects_widget = page.add_summary(title, height=4)
                self.trait_effects_widgets[actor] = effects_widget
                if actor == "npc":
                    self.trait_effects_widget = effects_widget
        page.finish()
    relationship_page = pages.get(("Relationship", "Overview"))
    if relationship_page is not None:
        self.relationship_context_summary = relationship_page.add_summary(
            "Canonical social context · production layers",
            height=14,
        )
        self.proposal_button = self._ttk.Button(
            relationship_page.content,
            text="Propose relationship",
            command=self.propose_relationship,
        )
        relationship_page.add_widget(
            self.proposal_button,
            columnspan=4,
            sticky="w",
            pady=(8, 3),
        )
        self.relationship_preview_var = self._tk.StringVar(
            value="Live preview: waiting for production resolver"
        )
        preview_label = self._ttk.Label(
            relationship_page.content,
            textvariable=self.relationship_preview_var,
            justify="left",
            wraplength=560,
        )
        relationship_page.add_widget(
            preview_label,
            columnspan=4,
            sticky="w",
            pady=(2, 6),
        )
        self.inventory_gift_workbench = InventoryGiftWorkbench(
            relationship_page.content,
            self,
        )
        relationship_page.add_widget(
            self.inventory_gift_workbench.frame,
            columnspan=4,
            sticky="nsew",
            pady=(6, 4),
        )
        relationship_page.finish()
    override_field = self.workbench_control_fields.get("npc.personalityOverride")
    if override_field is not None and override_field.variable is not None:
        override_field.variable.trace_add(
            "write", self._update_generated_personality_controls
        )
    for key in ("approval", "respect", "familiarity"):
        field = self.workbench_control_fields.get(f"relationship.{key}")
        if field is not None and field.variable is not None:
            field.variable.trace_add("write", self._on_relationship_slider_changed)
    self._update_generated_personality_controls()
    self._render_trait_effects()
    if not self.workbench_controls:
        empty = self._ttk.Frame(self.workbench_notebook, padding=8)
        self._ttk.Label(
            empty,
            text="The Lua worker did not declare any quick simulation controls.",
        ).grid(row=0, column=0, sticky="w")
        self.workbench_notebook.add(empty, text="Context")
    self._set_relationship_preview_from_projection()
    self._set_controls(self.session.ready)
    self._clear_workbench_pending()
    self._restore_workbench_tabs_after = self.root.after_idle(
        self._restore_workbench_tabs
    )
    self._restore_ui_state_after = self.root.after_idle(self._restore_ui_state)
    self._schedule_splitter_restore()


__all__ = ["build_simulation_workbench"]
