"""ConvoEngine-native family authoring pane for Semantic Lab.

The pane consumes SemanticLabAuthoringService directly for compact,
health-colored family browsing, kind-discoverable filtering, progressive
disclosure of identity/participants/State & Flow, single-path normal dialogue
authoring, and canonical write validation.
"""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any, Callable

from tools.semantic_harness.codebuilder.convo_engine_fields import (
    describe_unknown_fields,
    list_field_descriptors,
)
from tools.semantic_harness.studio.completeness_workbench import (
    DialogueCompletenessWorkbench,
    SEMANTIC_TAG_STYLES,
)


_S11_COMMON_NAMES: tuple[str, ...] = (
    "inputPolicy",
    "repeatPolicy",
    "statePolicy",
    "postconditions",
    "closure",
)

_S11_ADVANCED_NAMES: tuple[str, ...] = (
    "roles",
    "participantSet",
    "topics",
    "events",
    "activities",
    "memories",
    "domains",
)

_S11_CONTROL_NAMES: tuple[str, ...] = _S11_COMMON_NAMES + _S11_ADVANCED_NAMES

_S11_SCALAR_CHOICES: dict[str, tuple[str, ...]] = {
    "inputPolicy": ("", "typed_parity", "click_only", "typed_only"),
    "repeatPolicy": ("", "once", "cooldown", "max_uses", "state_retired", "unlimited"),
}

_HEALTH_BADGES: dict[str, str] = {
    "RED": "! Broken",
    "ORANGE": "! Risky",
    "YELLOW": "? Review",
    "BLUE": "-> Cont.",
    "PURPLE": "* Oblig.",
    "GREEN": "OK",
}

_KIND_FILTER_SPECS: tuple[tuple[str, str], ...] = (
    ("all", "All"),
    ("dialogue", "Dialogues"),
    ("behavior", "Behaviors"),
    ("beat", "Beats"),
    ("realization", "Realizations"),
)

_COMMON_OUTCOMES: tuple[str, ...] = (
    "acknowledged",
    "accepted",
    "known",
    "unknown",
    "refused",
    "failed",
    "valid",
)


class ConvoEngineAuthoringPane:
    """Browse, edit, and validate canonical ConvoEngine families."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: Any,
        *,
        auto_refresh: bool = True,
        on_preview_in_simulation: Callable[[str | None, dict[str, Any] | None], None] | None = None,
        on_open_kind_editor: Callable[[str, str, str | None, str | None], Any] | None = None,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._messagebox = messagebox
        self.service = service
        self._on_preview_in_simulation = on_preview_in_simulation
        self._on_open_kind_editor = on_open_kind_editor

        self._field_descriptors = self._load_field_descriptors()
        self._s11_descriptors = self._load_s11_field_descriptors()
        self._s11_json_descriptors = [
            d for d in self._s11_descriptors if d.get("editor_kind") == "json"
        ]
        self._s11_scalar_descriptors = [
            d for d in self._s11_descriptors if d.get("editor_kind") != "json"
        ]
        self._s11_scalar_vars: dict[str, Any] = {
            str(d["name"]): tk.StringVar() for d in self._s11_scalar_descriptors
        }

        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)

        self._families: list[dict[str, Any]] = []
        self._filtered_families: list[dict[str, Any]] = []
        self._family_health_by_id: dict[str, dict[str, Any]] = {}
        self._current_family_id: str | None = None
        self._syncing_selection: bool = False
        self._current_entry: dict[str, Any] | None = None
        self._document: dict[str, Any] | None = None
        self._loaded_fingerprint: str | None = None
        self._editors: dict[str, Any] = {}
        self._editor_boxes: dict[str, Any] = {}
        self._s11_scalar_widgets: dict[str, Any] = {}
        self._normal_widgets: dict[str, Any] = {}
        self._highlighted_field: str | None = None
        self._action_contracts: list[dict[str, Any]] = []
        self._kind_filter: str = "all"

        self._family_settings_visible = False
        self._participants_visible = False
        self._advanced_schema_visible = False
        self._advanced_s11_visible = False
        self._validation_details_visible = False

        self._status_var = tk.StringVar(value="Refresh to load ConvoEngine families")
        self._filter_var = tk.StringVar()
        self._kind_filter_vars: dict[str, Any] = {
            key: tk.StringVar(value=f"{label} (0)") for key, label in _KIND_FILTER_SPECS
        }

        self._header_title_var = tk.StringVar(value="No family selected")
        self._header_meta_var = tk.StringVar(value="")
        self._participants_summary_var = tk.StringVar(value="Participants: Default")
        self._conditional_meta_var = tk.StringVar(value="")

        self._canonical_id_var = tk.StringVar()
        self._kind_var = tk.StringVar(value="dialogue")
        self._namespace_var = tk.StringVar(value="social")
        self._id_var = tk.StringVar(value="new_family")
        self._owner_var = tk.StringVar(value="ProjectHoomans")
        self._source_path_var = tk.StringVar(value="")
        self._speaker_var = tk.StringVar(value='["participant"]')
        self._addressee_var = tk.StringVar(value='["participant"]')
        self._target_var = tk.StringVar(value='{"type":"entity.any"}')
        self._slots_var = tk.StringVar(value="{}")
        self._unknown_fields_var = tk.StringVar(value="(none)")

        self._affordance_label_var = tk.StringVar()
        self._say_single_var = tk.StringVar()
        self._execute_action_var = tk.StringVar()
        self._recommend_pick_var = tk.StringVar()
        self._after_mode_var = tk.StringVar(value="end")
        self._reply_outcome_var = tk.StringVar(value="acknowledged")
        self._reply_say_var = tk.StringVar()
        self._reply_summary_var = tk.StringVar(value="Outcomes: (none)")

        self._loaded_affordance_label = ""
        self._loaded_say_single = ""
        self._loaded_execute_action = ""

        self._real_act_var = tk.StringVar()
        self._real_strategy_var = tk.StringVar()
        self._real_concept_var = tk.StringVar()
        self._loaded_real_act = ""
        self._loaded_real_strategy = ""
        self._loaded_real_concept = ""
        self._loaded_real_translations: Any = None
        self._real_widgets: dict[str, Any] = {}

        self._build_toolbar()
        self._build_body()
        self._refreshed = False
        if auto_refresh:
            self.refresh()

    def _load_field_descriptors(self) -> list[dict[str, Any]]:
        describe = getattr(self.service, "describe_convo_engine_fields", None)
        if callable(describe):
            items = describe(category="exchange", editor_kind="json")
            if isinstance(items, list) and items:
                return items
        return list_field_descriptors(category="exchange", editor_kind="json")

    def _load_s11_field_descriptors(self) -> list[dict[str, Any]]:
        describe = getattr(self.service, "describe_convo_engine_fields", None)
        items = describe() if callable(describe) else list_field_descriptors()
        by_name = {
            str(item["name"]): item
            for item in (items or ())
            if isinstance(item, dict) and item.get("name") in _S11_CONTROL_NAMES
        }
        return [by_name[name] for name in _S11_CONTROL_NAMES if name in by_name]

    def field_descriptors(self) -> list[dict[str, Any]]:
        return list(self._field_descriptors) + list(self._s11_descriptors)

    def _build_toolbar(self) -> None:
        ttk = self._ttk
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 5))
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Filter families").grid(row=0, column=0, sticky="w")
        filter_entry = ttk.Entry(toolbar, textvariable=self._filter_var)
        filter_entry.grid(row=0, column=1, sticky="ew", padx=(6, 6))
        filter_entry.bind("<KeyRelease>", lambda _event: self._apply_filter())
        ttk.Button(toolbar, text="↻ Refresh", command=self.refresh).grid(row=0, column=2)
        ttk.Label(toolbar, textvariable=self._status_var).grid(
            row=1, column=0, columnspan=3, sticky="w", pady=(4, 0)
        )

    def _build_body(self) -> None:
        ttk = self._ttk
        left = ttk.LabelFrame(self.frame, text="ConvoEngine families")
        left.grid(row=2, column=0, sticky="nsew", padx=(0, 7))
        left.rowconfigure(1, weight=1)
        left.columnconfigure(0, weight=1)

        kind_bar = ttk.Frame(left)
        kind_bar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 4))
        self._kind_buttons: dict[str, Any] = {}
        for col_idx, (kind_key, _label) in enumerate(_KIND_FILTER_SPECS):
            btn = ttk.Button(
                kind_bar,
                textvariable=self._kind_filter_vars[kind_key],
                command=lambda k=kind_key: self.set_kind_filter(k),
            )
            btn.grid(row=0, column=col_idx, padx=(0, 2), sticky="ew")
            self._kind_buttons[kind_key] = btn

        self._family_tree = ttk.Treeview(
            left,
            columns=("health", "family"),
            show="headings",
            selectmode="browse",
        )
        self._family_tree.heading("health", text="Health")
        self._family_tree.heading("family", text="Family")
        self._family_tree.column("health", width=74, minwidth=64, stretch=False)
        self._family_tree.column("family", width=220, minwidth=140, stretch=True)
        for tag_name, style in SEMANTIC_TAG_STYLES.items():
            self._family_tree.tag_configure(tag_name, **style)
        self._family_tree.grid(row=1, column=0, sticky="nsew")
        self._family_tree.bind("<<TreeviewSelect>>", lambda _event: self._family_selected())
        scroll = ttk.Scrollbar(left, orient="vertical", command=self._family_tree.yview)
        scroll.grid(row=1, column=1, sticky="ns")
        self._family_tree.configure(yscrollcommand=scroll.set)

        actions = ttk.Frame(left)
        actions.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(5, 0))
        ttk.Button(actions, text="+ New", command=self.new_family).pack(side="left")

        menubutton_cls = getattr(ttk, "Menubutton", ttk.Button)
        overflow_btn = menubutton_cls(actions, text="⋯")
        menu_cls = getattr(self._tk, "Menu", None)
        if callable(menu_cls):
            overflow_menu = menu_cls(overflow_btn, tearoff=0)
            overflow_menu.add_command(label="Duplicate", command=self.duplicate_family)
            overflow_menu.add_command(label="Move family…", command=self.open_move_family)
            overflow_menu.add_command(label="Open source path", command=self.open_source_location)
            overflow_menu.add_separator()
            overflow_menu.add_command(label="Delete", command=self.delete_family)
            overflow_btn.configure(menu=overflow_menu)
        overflow_btn.pack(side="left", padx=(4, 0))
        self._family_overflow_btn = overflow_btn

        right = ttk.Frame(self.frame)
        right.grid(row=2, column=1, sticky="nsew")
        right.rowconfigure(1, weight=1)
        right.columnconfigure(0, weight=1)

        self._build_selected_header(right)
        self._build_right_notebook(right)

    def _build_selected_header(self, right: Any) -> None:
        ttk = self._ttk
        header = ttk.Frame(right, padding=(4, 2))
        header.grid(row=0, column=0, sticky="ew", pady=(0, 5))
        header.columnconfigure(0, weight=1)

        top_row = ttk.Frame(header)
        top_row.grid(row=0, column=0, sticky="ew")
        top_row.columnconfigure(0, weight=1)
        ttk.Label(top_row, textvariable=self._header_title_var).grid(row=0, column=0, sticky="w")
        ttk.Button(
            top_row,
            text="Preview in Simulation",
            command=self.preview_in_simulation,
        ).grid(row=0, column=1, padx=(6, 4))
        ttk.Button(
            top_row,
            text="Family settings…",
            command=self.toggle_family_settings,
        ).grid(row=0, column=2)

        ttk.Label(header, textvariable=self._header_meta_var).grid(row=1, column=0, sticky="w")

        part_row = ttk.Frame(header)
        part_row.grid(row=2, column=0, sticky="ew", pady=(2, 0))
        part_row.columnconfigure(0, weight=1)
        ttk.Label(part_row, textvariable=self._participants_summary_var).grid(row=0, column=0, sticky="w")
        ttk.Button(
            part_row,
            text="Edit participants…",
            command=self.toggle_participants_editor,
        ).grid(row=0, column=1)

        self._conditional_meta_label = ttk.Label(header, textvariable=self._conditional_meta_var)
        self._conditional_meta_label.grid(row=3, column=0, sticky="w")
        self._set_visible(self._conditional_meta_label, False)

        # Collapsible participants editor (hidden by default)
        self._participants_panel = ttk.LabelFrame(header, text="Participants")
        self._participants_panel.grid(row=4, column=0, sticky="ew", pady=(4, 0))
        self._participants_panel.columnconfigure(1, weight=1)
        self._participants_panel.columnconfigure(3, weight=1)
        self._entry(self._participants_panel, 0, 0, "Speaker", self._speaker_var)
        self._entry(self._participants_panel, 0, 2, "Addressee", self._addressee_var)
        self._set_visible(self._participants_panel, False)

        # Collapsible Family settings (hidden by default)
        self._family_settings_panel = ttk.LabelFrame(header, text="Family settings")
        self._family_settings_panel.grid(row=5, column=0, sticky="ew", pady=(4, 0))
        for col in (1, 3):
            self._family_settings_panel.columnconfigure(col, weight=1)
        self._entry(self._family_settings_panel, 0, 0, "Canonical ID", self._canonical_id_var, readonly=True)
        self._entry(self._family_settings_panel, 0, 2, "Owner (Move)", self._owner_var)
        ttk.Label(self._family_settings_panel, text="Kind").grid(row=1, column=0, sticky="w", padx=4, pady=2)
        self._kind_box = ttk.Combobox(
            self._family_settings_panel,
            textvariable=self._kind_var,
            state="readonly",
            values=("dialogue", "behavior", "beat", "realization"),
            width=18,
        )
        self._kind_box.grid(row=1, column=1, sticky="ew", padx=(0, 5), pady=2)
        self._entry(self._family_settings_panel, 1, 2, "Namespace", self._namespace_var)
        self._entry(self._family_settings_panel, 2, 0, "Family ID", self._id_var)
        self._entry(self._family_settings_panel, 2, 2, "Source path", self._source_path_var, readonly=True)
        self._entry(
            self._family_settings_panel,
            3,
            0,
            "Extra / preserved fields",
            self._unknown_fields_var,
            readonly=True,
        )
        ttk.Label(
            self._family_settings_panel,
            text="Changing kind alters schema validation; prefer + New for another kind.",
        ).grid(row=3, column=2, columnspan=2, sticky="w", padx=4)
        self._set_visible(self._family_settings_panel, False)

    def _build_right_notebook(self, right: Any) -> None:
        ttk = self._ttk
        notebook = ttk.Notebook(right)
        notebook.grid(row=1, column=0, sticky="nsew")
        structured = ttk.Frame(notebook, padding=6)
        s11_controls = ttk.Frame(notebook, padding=6)
        completeness_tab = ttk.Frame(notebook, padding=4)
        notebook.add(structured, text="Dialogue")
        notebook.add(s11_controls, text="State & Flow")
        notebook.add(completeness_tab, text="Dialogue Completeness")

        self._right_notebook = notebook
        self._structured_tab = structured
        self._s11_controls_tab = s11_controls
        self._completeness_tab = completeness_tab

        self._build_dialogue_tab(structured)
        self._build_state_and_flow_tab(s11_controls)

        completeness_tab.rowconfigure(0, weight=1)
        completeness_tab.columnconfigure(0, weight=1)
        self.completeness_workbench = DialogueCompletenessWorkbench(
            completeness_tab,
            self._tk,
            ttk,
            self._ScrolledText,
            self._messagebox,
            self.service,
            on_open_family=self.open_family_from_completeness,
            on_select_family=self.select_family_from_completeness,
            on_run_family_tests=self.run_family_tests,
            auto_analyze=False,
        )
        if callable(getattr(notebook, "bind", None)) and callable(getattr(notebook, "select", None)):
            def _on_tab_change(_event: Any = None) -> None:
                try:
                    if str(notebook.select()) == str(completeness_tab):
                        self.completeness_workbench.ensure_loaded()
                except Exception:
                    pass

            notebook.bind("<<NotebookTabChanged>>", _on_tab_change, add="+")

    def _build_dialogue_tab(self, structured: Any) -> None:
        ttk = self._ttk
        structured.columnconfigure(0, weight=1)
        structured.rowconfigure(3, weight=1)

        # Single normal editing path for dialogue concepts
        normal = ttk.LabelFrame(structured, text="Conversation turn")
        normal.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        self._dialogue_normal_frame = normal
        normal.columnconfigure(1, weight=1)
        normal.columnconfigure(3, weight=1)

        aff_entry = self._entry(normal, 0, 0, "Button label", self._affordance_label_var)
        say_entry = self._entry(normal, 0, 2, "Spoken line", self._say_single_var)
        self._normal_widgets["affordance"] = aff_entry
        self._normal_widgets["say"] = say_entry

        ttk.Label(normal, text="Action").grid(row=1, column=0, sticky="w", padx=4, pady=2)
        self._execute_box = ttk.Combobox(normal, textvariable=self._execute_action_var, width=24)
        self._execute_box.grid(row=1, column=1, sticky="ew", padx=(0, 5), pady=2)
        self._normal_widgets["execute"] = self._execute_box

        ttk.Label(normal, text="After this").grid(row=1, column=2, sticky="w", padx=4, pady=2)
        after_row = ttk.Frame(normal)
        after_row.grid(row=1, column=3, sticky="ew", padx=(0, 5), pady=2)
        after_row.columnconfigure(1, weight=1)
        self._after_mode_box = ttk.Combobox(
            after_row,
            textvariable=self._after_mode_var,
            state="readonly",
            values=("end", "continue", "recommend"),
            width=11,
        )
        self._after_mode_box.grid(row=0, column=0, padx=(0, 4))
        self._recommend_box = ttk.Combobox(after_row, textvariable=self._recommend_pick_var, width=18)
        self._recommend_box.grid(row=0, column=1, sticky="ew")
        ttk.Button(after_row, text="+Recommend", command=self.add_recommendation).grid(row=0, column=2, padx=(4, 0))
        self._normal_widgets["after"] = self._recommend_box

        ttk.Label(normal, text="NPC outcome").grid(row=2, column=0, sticky="w", padx=4, pady=2)
        self._reply_outcome_box = ttk.Combobox(
            normal,
            textvariable=self._reply_outcome_var,
            values=_COMMON_OUTCOMES,
            width=18,
        )
        self._reply_outcome_box.grid(row=2, column=1, sticky="ew", padx=(0, 5), pady=2)
        reply_row = ttk.Frame(normal)
        reply_row.grid(row=2, column=2, columnspan=2, sticky="ew", padx=4, pady=2)
        reply_row.columnconfigure(1, weight=1)
        ttk.Label(reply_row, text="Reply line").grid(row=0, column=0, sticky="w", padx=(0, 4))
        reply_say_entry = ttk.Entry(reply_row, textvariable=self._reply_say_var)
        reply_say_entry.grid(row=0, column=1, sticky="ew")
        ttk.Button(reply_row, text="Set reply", command=self.set_reply_outcome).grid(row=0, column=2, padx=(4, 2))
        ttk.Button(reply_row, text="Del reply", command=self.delete_reply_outcome).grid(row=0, column=3)
        self._normal_widgets["reply"] = reply_say_entry

        ttk.Label(normal, textvariable=self._reply_summary_var).grid(
            row=3, column=0, columnspan=4, sticky="w", padx=4, pady=(2, 2)
        )

        # Primary save/validate bar
        action_bar = ttk.Frame(structured)
        action_bar.grid(row=1, column=0, sticky="ew", pady=(0, 6))
        ttk.Button(action_bar, text="Validate", command=self.preview_record).pack(side="left")
        ttk.Button(action_bar, text="Write canonical source", command=self.write_source).pack(
            side="left", padx=6
        )
        ttk.Button(action_bar, text="Advanced schema / details ▸", command=self.toggle_advanced_schema).pack(
            side="right"
        )
        ttk.Button(action_bar, text="Validation details ▸", command=self.toggle_validation_details).pack(
            side="right", padx=(0, 6)
        )

        # Collapsible validation report (hidden by default)
        self._validation_details_frame = ttk.LabelFrame(structured, text="Validation details")
        self._validation_details_frame.grid(row=2, column=0, sticky="ew", pady=(0, 6))
        self._validation_details_frame.columnconfigure(0, weight=1)
        self._report = self._ScrolledText(self._validation_details_frame, height=6, wrap="none", state="disabled")
        self._report.grid(row=0, column=0, sticky="nsew")
        self._set_visible(self._validation_details_frame, False)

        # Collapsible Advanced schema / raw JSON editors (hidden by default)
        self._advanced_schema_frame = ttk.LabelFrame(structured, text="Advanced schema / raw JSON")
        self._advanced_schema_frame.grid(row=3, column=0, sticky="nsew")
        self._advanced_schema_frame.columnconfigure(0, weight=1)
        self._advanced_schema_frame.rowconfigure(1, weight=1)

        slots_bar = ttk.Frame(self._advanced_schema_frame)
        slots_bar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
        slots_bar.columnconfigure(1, weight=1)
        self._entry(slots_bar, 0, 0, "Slots JSON", self._slots_var)

        fields = ttk.PanedWindow(self._advanced_schema_frame, orient="vertical")
        fields.grid(row=1, column=0, sticky="nsew")
        upper = ttk.Frame(fields)
        lower = ttk.Frame(fields)
        upper.columnconfigure(0, weight=1)
        lower.columnconfigure(0, weight=1)
        fields.add(upper, weight=1)
        fields.add(lower, weight=2)
        split_index = max(1, (len(self._field_descriptors) + 1) // 2)
        for index, descriptor in enumerate(self._field_descriptors):
            name = str(descriptor["name"])
            label = str(descriptor["label"])
            host = upper if index < split_index else lower
            row = index if index < split_index else index - split_index
            box = ttk.LabelFrame(host, text=label)
            box.grid(row=row, column=0, sticky="nsew", padx=2, pady=2)
            host.rowconfigure(row, weight=1)
            box.columnconfigure(0, weight=1)
            editor = self._ScrolledText(box, height=3, wrap="none")
            editor.grid(row=0, column=0, sticky="nsew")
            self._editors[name] = editor
            self._editor_boxes[name] = box
        self._set_visible(self._advanced_schema_frame, False)

        # Kind-specific realization panel (shown only when kind == "realization")
        real_panel = ttk.LabelFrame(structured, text="Realization authoring")
        real_panel.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        real_panel.columnconfigure(1, weight=1)
        real_panel.columnconfigure(3, weight=1)
        self._real_widgets["realization.dialogueAct"] = self._entry(
            real_panel, 0, 0, "Dialogue act", self._real_act_var
        )
        self._real_widgets["realization.strategy"] = self._entry(
            real_panel, 0, 2, "Strategy", self._real_strategy_var
        )
        self._real_widgets["realization.concept"] = self._entry(
            real_panel, 1, 0, "Concept", self._real_concept_var
        )
        ttk.Label(real_panel, text="Translations JSON").grid(row=2, column=0, sticky="nw", padx=4, pady=2)
        self._real_translations_editor = self._ScrolledText(real_panel, height=6, wrap="none")
        self._real_translations_editor.grid(row=2, column=1, columnspan=3, sticky="nsew", padx=(0, 5), pady=2)
        self._real_widgets["realization.translations"] = self._real_translations_editor
        self._realization_panel = real_panel
        self._set_visible(self._realization_panel, False)

        # Non-dialogue routing notice for behavior / beat (read-only here)
        route_panel = ttk.LabelFrame(structured, text="Kind-specific editor required")
        route_panel.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        route_panel.columnconfigure(0, weight=1)
        self._non_dialogue_route_var = self._tk.StringVar(
            value="Behavior and Beat families are authored in Interaction Modules (read-only here)."
        )
        ttk.Label(route_panel, textvariable=self._non_dialogue_route_var).grid(
            row=0, column=0, sticky="w", padx=6, pady=4
        )
        ttk.Button(
            route_panel,
            text="Open in Interaction Modules",
            command=self.open_in_kind_editor,
        ).grid(row=0, column=1, padx=6, pady=4)
        self._non_dialogue_route_panel = route_panel
        self._set_visible(self._non_dialogue_route_panel, False)

    def _build_state_and_flow_tab(self, s11_controls: Any) -> None:
        ttk = self._ttk
        s11_controls.columnconfigure(0, weight=1)
        s11_controls.rowconfigure(1, weight=1)
        s11_controls.rowconfigure(3, weight=1)

        s11_scalars = ttk.Frame(s11_controls)
        s11_scalars.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        for col_idx, descriptor in enumerate(self._s11_scalar_descriptors):
            name = str(descriptor["name"])
            label = "Input mode" if name == "inputPolicy" else (
                "Repeat behavior" if name == "repeatPolicy" else str(descriptor["label"])
            )
            ttk.Label(s11_scalars, text=label).grid(row=0, column=col_idx * 2, sticky="w", padx=4)
            choices = _S11_SCALAR_CHOICES.get(name)
            if choices:
                box = ttk.Combobox(
                    s11_scalars,
                    textvariable=self._s11_scalar_vars[name],
                    values=choices,
                    width=18,
                )
                box.grid(row=0, column=col_idx * 2 + 1, sticky="ew", padx=(0, 8))
                self._s11_scalar_widgets[name] = box
            else:
                entry = ttk.Entry(s11_scalars, textvariable=self._s11_scalar_vars[name])
                entry.grid(row=0, column=col_idx * 2 + 1, sticky="ew", padx=(0, 8))
                self._s11_scalar_widgets[name] = entry
            s11_scalars.columnconfigure(col_idx * 2 + 1, weight=1)

        common_json = [d for d in self._s11_json_descriptors if d.get("name") in _S11_COMMON_NAMES]
        adv_json = [d for d in self._s11_json_descriptors if d.get("name") in _S11_ADVANCED_NAMES]

        common_host = ttk.Frame(s11_controls)
        common_host.grid(row=1, column=0, sticky="nsew")
        common_host.columnconfigure(0, weight=1)
        for row, descriptor in enumerate(common_json):
            name = str(descriptor["name"])
            label = str(descriptor["label"])
            box = ttk.LabelFrame(common_host, text=label)
            box.grid(row=row, column=0, sticky="nsew", padx=2, pady=2)
            common_host.rowconfigure(row, weight=1)
            box.columnconfigure(0, weight=1)
            editor = self._ScrolledText(box, height=3, wrap="none")
            editor.grid(row=0, column=0, sticky="nsew")
            self._editors[name] = editor
            self._editor_boxes[name] = box

        adv_bar = ttk.Frame(s11_controls)
        adv_bar.grid(row=2, column=0, sticky="ew", pady=(4, 2))
        ttk.Button(
            adv_bar,
            text="Advanced semantic fields ▸",
            command=self.toggle_advanced_s11,
        ).pack(side="left")

        self._advanced_s11_frame = ttk.Frame(s11_controls)
        self._advanced_s11_frame.grid(row=3, column=0, sticky="nsew")
        self._advanced_s11_frame.columnconfigure(0, weight=1)
        for row, descriptor in enumerate(adv_json):
            name = str(descriptor["name"])
            label = str(descriptor["label"])
            box = ttk.LabelFrame(self._advanced_s11_frame, text=label)
            box.grid(row=row, column=0, sticky="nsew", padx=2, pady=2)
            self._advanced_s11_frame.rowconfigure(row, weight=1)
            box.columnconfigure(0, weight=1)
            editor = self._ScrolledText(box, height=2, wrap="none")
            editor.grid(row=0, column=0, sticky="nsew")
            self._editors[name] = editor
            self._editor_boxes[name] = box
        self._set_visible(self._advanced_s11_frame, False)

    @staticmethod
    def _set_visible(widget: Any, visible: bool) -> None:
        if visible:
            if callable(getattr(widget, "grid", None)):
                widget.grid()
        else:
            if callable(getattr(widget, "grid_remove", None)):
                widget.grid_remove()

    def toggle_family_settings(self) -> None:
        self._family_settings_visible = not self._family_settings_visible
        self._set_visible(self._family_settings_panel, self._family_settings_visible)

    def toggle_participants_editor(self) -> None:
        self._participants_visible = not self._participants_visible
        self._set_visible(self._participants_panel, self._participants_visible)

    def toggle_advanced_schema(self) -> None:
        self._advanced_schema_visible = not self._advanced_schema_visible
        self._set_visible(self._advanced_schema_frame, self._advanced_schema_visible)

    def toggle_advanced_s11(self) -> None:
        self._advanced_s11_visible = not self._advanced_s11_visible
        self._set_visible(self._advanced_s11_frame, self._advanced_s11_visible)

    def toggle_validation_details(self) -> None:
        self._validation_details_visible = not self._validation_details_visible
        self._set_visible(self._validation_details_frame, self._validation_details_visible)

    def open_move_family(self) -> None:
        self._family_settings_visible = True
        self._set_visible(self._family_settings_panel, True)
        self._status_var.set("Edit Owner in Family settings and Write canonical source to move family")

    def open_source_location(self) -> None:
        self._family_settings_visible = True
        self._set_visible(self._family_settings_panel, True)
        path = self._source_path_var.get()
        self._status_var.set(f"Source path: {path}" if path else "No saved source path yet")

    def preview_in_simulation(self) -> None:
        if callable(self._on_preview_in_simulation):
            self._on_preview_in_simulation(self._current_family_id, self._document)
        else:
            self._status_var.set(
                f"Preview in Simulation ready for {self._current_family_id or '(none)'}"
            )

    def _entry(
        self,
        parent: Any,
        row: int,
        column: int,
        label: str,
        variable: Any,
        *,
        readonly: bool = False,
    ) -> Any:
        self._ttk.Label(parent, text=label).grid(row=row, column=column, sticky="w", padx=4, pady=2)
        entry = self._ttk.Entry(parent, textvariable=variable)
        entry.grid(row=row, column=column + 1, sticky="ew", padx=(0, 5), pady=2)
        if readonly:
            entry.configure(state="readonly")
        return entry

    @staticmethod
    def _pretty(value: Any) -> str:
        return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"

    @staticmethod
    def _compact_json(value: Any) -> str:
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))

    def _set_report(self, value: Any) -> None:
        self._report.configure(state="normal")
        self._report.delete("1.0", "end")
        self._report.insert("1.0", self._pretty(value))
        self._report.configure(state="disabled")

    def _read_json_editor(self, name: str) -> Any:
        raw = self._editors[name].get("1.0", "end").strip()
        if not raw:
            return None
        try:
            return json.loads(raw)
        except json.JSONDecodeError as error:
            raise ValueError(f"{name}: invalid JSON ({error})") from error

    def _write_json_editor(self, name: str, value: Any) -> None:
        editor = self._editors[name]
        editor.delete("1.0", "end")
        if value is not None:
            editor.insert("1.0", self._pretty(value))

    def _load_catalog_families(self) -> list[dict[str, Any]]:
        families: list[dict[str, Any]] = []
        offset = 0
        while True:
            page = self.service.dispatch_operation(
                "convo.catalog",
                {"query": "", "limit": 200, "offset": offset},
            )
            items = list(page.get("items") or [])
            families.extend(items)
            if not page.get("truncated") or not items:
                break
            offset += len(items)
        return families

    def _refresh_health_projection(self) -> None:
        analyze = getattr(self.service, "analyze_convo_completeness", None)
        if not callable(analyze):
            return
        try:
            report = analyze(strict_manifest=False)
        except Exception:
            return
        self._update_health_from_report(report)

    def _update_health_from_report(self, report: dict[str, Any] | None) -> None:
        if not isinstance(report, dict):
            return
        rows = report.get("families") or {}
        by_id: dict[str, dict[str, Any]] = {}
        if isinstance(rows, dict):
            for fid, row in rows.items():
                if isinstance(row, dict):
                    by_id[str(row.get("familyId") or fid)] = row
        else:
            for row in rows:
                if isinstance(row, dict) and row.get("familyId"):
                    by_id[str(row["familyId"])] = row
        if by_id:
            self._family_health_by_id = by_id

    def _update_kind_counts(self) -> None:
        counts = {"all": len(self._families), "dialogue": 0, "behavior": 0, "beat": 0, "realization": 0}
        for item in self._families:
            kind = str(item.get("kind") or "dialogue")
            if kind in counts:
                counts[kind] += 1
        for key, label in _KIND_FILTER_SPECS:
            self._kind_filter_vars[key].set(f"{label} ({counts.get(key, 0)})")

    def set_kind_filter(self, kind: str) -> None:
        self._kind_filter = kind if kind in dict(_KIND_FILTER_SPECS) else "all"
        self._apply_filter()

    def ensure_refreshed(self) -> None:
        """Populate ConvoEngine families and action contracts on first use."""
        if not self._refreshed:
            self.refresh()

    def refresh(self) -> None:
        self._refreshed = True
        try:
            self._families = self._load_catalog_families()
            self._action_contracts = self.service.list_convo_engine_action_contracts()
        except (OSError, ValueError, KeyError, TypeError) as error:
            self._families = []
            self._filtered_families = []
            self._status_var.set(f"ConvoEngine family load failed: {error}")
            return
        self._refresh_health_projection()
        self._update_kind_counts()
        contract_ids = [item["id"] for item in self._action_contracts]
        self._execute_box.configure(values=contract_ids)
        self._recommend_box.configure(values=[item["canonicalID"] for item in self._families])
        self._apply_filter()

    def _apply_filter(self) -> None:
        needle = self._filter_var.get().strip().lower()
        self._family_tree.delete(*self._family_tree.get_children())
        self._filtered_families = [
            item
            for item in self._families
            if (self._kind_filter == "all" or str(item.get("kind") or "") == self._kind_filter)
            and (
                not needle
                or needle in str(item.get("canonicalID", "")).lower()
                or needle in str(item.get("owner", "")).lower()
                or needle in str(item.get("kind", "")).lower()
                or needle in str(item.get("namespace", "")).lower()
                or needle in str(item.get("path", "")).lower()
            )
        ]
        selected_fid: str | None = None
        for item in self._filtered_families:
            fid = str(item.get("canonicalID") or item.get("id") or "")
            health_row = self._family_health_by_id.get(fid) or {}
            status = str(health_row.get("semanticStatus") or "GREEN")
            badge = _HEALTH_BADGES.get(status, status)
            self._family_tree.insert(
                "",
                "end",
                iid=fid,
                values=(badge, fid),
                tags=(status,),
            )
            if self._current_family_id and (
                item.get("canonicalID") == self._current_family_id
                or item.get("id") == self._current_family_id
            ):
                selected_fid = fid
        if selected_fid is not None:
            self._set_family_tree_selection(selected_fid)
            self._family_selected()
        elif self._current_family_id is not None:
            self._status_var.set(
                f"Selected family {self._current_family_id} is outside the active filter"
            )
        elif self._filtered_families:
            first_fid = str(
                self._filtered_families[0].get("canonicalID")
                or self._filtered_families[0].get("id")
                or ""
            )
            self._set_family_tree_selection(first_fid)
            self._family_selected()
        else:
            self._status_var.set("No ConvoEngine families match filter")

    def _set_family_tree_selection(self, fid: str) -> None:
        try:
            self._family_tree.selection_set(fid)
        except Exception:
            pass
        if callable(getattr(self._family_tree, "see", None)):
            try:
                self._family_tree.see(fid)
            except Exception:
                pass

    def select_family(self, family_id: str) -> bool:
        """Select a family in the primary browser by canonical ID."""
        return self.select_family_from_completeness(family_id)

    def select_family_from_completeness(self, family_id: str) -> bool:
        """Synchronize main editor selection from Workbench without reentrant loops."""
        if not family_id:
            return False
        self.ensure_refreshed()
        if self._current_family_id == family_id and any(
            e.get("canonicalID") == family_id or e.get("id") == family_id
            for e in self._filtered_families
        ):
            return True
        if self._syncing_selection:
            return False
        self._syncing_selection = True
        try:
            in_filtered = any(
                e.get("canonicalID") == family_id or e.get("id") == family_id
                for e in self._filtered_families
            )
            if not in_filtered:
                self._current_family_id = family_id
                self._filter_var.set("")
                self._kind_filter = "all"
                self._apply_filter()
            for entry in self._filtered_families:
                if entry.get("canonicalID") == family_id or entry.get("id") == family_id:
                    fid = str(entry.get("canonicalID") or entry.get("id") or "")
                    self._set_family_tree_selection(fid)
                    self._family_selected()
                    return True
            return False
        finally:
            self._syncing_selection = False

    @staticmethod
    def resolve_target_field(
        field_path: str | None,
        diag_code: str | None = None,
    ) -> str | None:
        """Map a diagnostic path/code to the exact canonical editor control name."""
        known_fields = (
            "behavior.stimuli",
            "behavior.outputs",
            "beat.entry",
            "beat.candidates",
            "realization.translations",
            "realization.dialogueAct",
            "realization.strategy",
            "realization.concept",
            "statePolicy",
            "inputPolicy",
            "repeatPolicy",
            "postconditions",
            "closure",
            "roles",
            "participantSet",
            "topics",
            "events",
            "activities",
            "memories",
            "domains",
            "reply",
            "after",
            "when",
            "say",
            "execute",
            "affordance",
        )
        raw = str(field_path or "")
        for name in known_fields:
            if f".{name}" in raw or raw == name or raw.startswith(f"{name}.") or raw.startswith(f"{name}["):
                return name
        non_dialogue_subfields = (
            ("stimuli", "behavior.stimuli"),
            ("outputs", "behavior.outputs"),
            ("requiredCapabilities", "behavior.outputs"),
            ("entry", "beat.entry"),
            ("candidates", "beat.candidates"),
            ("translations", "realization.translations"),
            ("dialogueAct", "realization.dialogueAct"),
            ("strategy", "realization.strategy"),
            ("concept", "realization.concept"),
        )
        for sub, mapped in non_dialogue_subfields:
            if f".{sub}" in raw or raw == sub or raw.startswith(f"{sub}."):
                return mapped
        code_map = {
            "stale_poststate_risk": "statePolicy",
            "unhandled_state_outcome": "statePolicy",
            "pending_without_exit": "statePolicy",
            "unreachable_branch": "statePolicy",
            "unhandled_action_outcome": "reply",
            "dead_end": "after",
            "unbounded_loop": "repeatPolicy",
            "missing_repeat_policy": "repeatPolicy",
            "dangling_memory": "closure",
            "lost_commitment": "closure",
            "role_unbound": "roles",
            "role_cardinality_mismatch": "roles",
            "unbounded_group_reaction": "participantSet",
            "missing_behavior_stimuli": "behavior.stimuli",
            "missing_behavior_outputs": "behavior.outputs",
            "invalid_behavior_capability": "behavior.outputs",
            "unresolved_behavior_output_reference": "behavior.outputs",
            "missing_beat_entry": "beat.entry",
            "unresolved_beat_candidate": "beat.candidates",
            "missing_en_realization": "realization.translations",
            "empty_realization_locale": "realization.translations",
            "realization_undeclared_slot": "realization.translations",
            "missing_realization_binding": "realization.dialogueAct",
        }
        return code_map.get(str(diag_code or ""))

    def open_in_kind_editor(
        self,
        field_path: str | None = None,
        diag_code: str | None = None,
    ) -> Any:
        """Route the current family to its kind-specific editor surface."""
        fid = self._current_family_id
        if not fid:
            return None
        kind = str((self._document or {}).get("kind") or (self._current_entry or {}).get("kind") or "dialogue")
        if callable(self._on_open_kind_editor):
            return self._on_open_kind_editor(kind, fid, field_path, diag_code)
        target_field = self.resolve_target_field(field_path, diag_code)
        self._status_var.set(
            f"{kind.capitalize()} {fid} routes to Interaction Modules ({target_field or kind})"
        )
        return target_field

    def focus_field(
        self,
        field_path: str | None,
        diag_code: str | None = None,
    ) -> str | None:
        """Switch to the owning tab and focus/highlight the exact canonical editor control."""
        field_name = self.resolve_target_field(field_path, diag_code)
        target_tab = (
            self._s11_controls_tab
            if field_name in _S11_CONTROL_NAMES
            else self._structured_tab
        )
        if callable(getattr(self._right_notebook, "select", None)):
            self._right_notebook.select(target_tab)
        if not field_name:
            return None
        if field_name in _S11_ADVANCED_NAMES:
            self._advanced_s11_visible = True
            self._set_visible(self._advanced_s11_frame, True)
        if field_name == "when":
            self._advanced_schema_visible = True
            self._set_visible(self._advanced_schema_frame, True)

        widget = (
            self._real_widgets.get(field_name)
            or self._s11_scalar_widgets.get(field_name)
            or self._normal_widgets.get(field_name)
            or self._editors.get(field_name)
        )
        if field_name in _S11_CONTROL_NAMES and field_name not in self._s11_scalar_widgets:
            widget = self._editors.get(field_name)
        if widget is not None:
            if callable(getattr(widget, "focus_set", None)):
                try:
                    widget.focus_set()
                except Exception:
                    pass
            try:
                widget.configure(highlightthickness=2, highlightbackground="#d97706")
            except Exception:
                pass
        self._highlighted_field = field_name
        return field_name

    def open_family_from_completeness(
        self,
        family_id: str,
        field_path: str | None = None,
        diag_code: str | None = None,
    ) -> bool:
        """Select a canonical family and route/focus the kind-appropriate editor & field."""
        if not self.select_family_from_completeness(family_id):
            return False
        kind = str((self._document or {}).get("kind") or (self._current_entry or {}).get("kind") or "dialogue")
        if kind in ("behavior", "beat"):
            if callable(self._on_open_kind_editor):
                self._on_open_kind_editor(kind, family_id, field_path, diag_code)
            target = self.resolve_target_field(field_path, diag_code)
            if target:
                self._highlighted_field = target
            self._status_var.set(f"Routed {kind} {family_id} to Interaction Modules ({target or kind})")
            return True
        self.focus_field(field_path, diag_code)
        return True

    def run_family_tests(self, family_id: str) -> dict[str, Any]:
        """Delegate family-level test execution to SemanticLabAuthoringService."""
        fn = getattr(self.service, "run_family_tests", None)
        if callable(fn):
            result = fn(family_id)
        else:
            result = {
                "ok": True,
                "ran": False,
                "familyId": family_id,
                "message": "No exact family-level runnable test is registered",
            }
        self._status_var.set(str(result.get("message") or f"Family test check complete for {family_id}"))
        return result

    def _family_selected(self) -> None:
        selection = self._family_tree.selection()
        if not selection:
            return
        selected_fid = str(selection[0])
        entry = next(
            (
                item
                for item in self._filtered_families
                if str(item.get("canonicalID") or item.get("id") or "") == selected_fid
            ),
            None,
        )
        if entry is None:
            return
        dispatch = getattr(self.service, "dispatch_operation", None)
        if callable(dispatch):
            try:
                loaded = dispatch("convo.get", {"target": entry.get("sourcePath") or entry.get("canonicalID")})
            except (OSError, ValueError) as error:
                self._status_var.set(f"Load failed: {error}")
                return
            if not loaded.get("found"):
                self._status_var.set("Load failed: family missing")
                return
            document = loaded["document"]
            loaded_fp = loaded.get("sourceFingerprint")
        else:
            try:
                document = json.loads(Path(entry["sourcePath"]).read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as error:
                self._status_var.set(f"Load failed: {error}")
                return
            loaded_fp = entry.get("sourceFingerprint")
        self._current_entry = entry
        self._current_family_id = str(entry.get("canonicalID") or entry.get("id") or "")
        self._document = document
        self._loaded_fingerprint = loaded_fp
        self._load_family_form(document)
        self._status_var.set(f"{entry['canonicalID']}")
        if hasattr(self, "completeness_workbench") and self._current_family_id:
            if not self._syncing_selection:
                self._syncing_selection = True
                try:
                    self.completeness_workbench.select_family(
                        self._current_family_id,
                        ensure_loaded=False,
                        notify=False,
                    )
                finally:
                    self._syncing_selection = False

    def _load_family_form(self, doc: dict[str, Any]) -> None:
        ns = doc.get("namespace") or ""
        fid = str(doc.get("id") or "")
        canonical_id = f"{ns}.{fid}" if ns else fid
        kind = str(doc.get("kind") or (self._current_entry or {}).get("kind") or "dialogue")
        owner = str(doc.get("owner") or (self._current_entry or {}).get("owner") or "")
        source_path = str((self._current_entry or {}).get("sourcePath") or "")

        self._canonical_id_var.set(canonical_id)
        self._kind_var.set(kind)
        self._namespace_var.set(str(ns))
        self._id_var.set(fid)
        self._owner_var.set(owner)
        self._source_path_var.set(source_path)

        health_row = self._family_health_by_id.get(canonical_id) or {}
        status = str(health_row.get("semanticStatus") or "GREEN")
        badge = _HEALTH_BADGES.get(status, status)
        coverage = str(health_row.get("fixtureCoverage") or "unknown")
        self._header_title_var.set(canonical_id or "(draft)")
        self._header_meta_var.set(
            f"{kind.capitalize()} · {owner or 'auto'} · {badge} · Tests: {coverage}"
            + (f" · {ns}" if ns else "")
        )

        participants = doc.get("participants") or {}
        speaker = participants.get("speaker", ["participant"])
        addressee = participants.get("addressee", ["participant"])
        self._speaker_var.set(self._compact_json(speaker))
        self._addressee_var.set(self._compact_json(addressee))
        if speaker == ["participant"] and addressee == ["participant"]:
            self._participants_summary_var.set("Participants: Default (participant ↔ participant)")
        else:
            self._participants_summary_var.set(
                f"Participants: {', '.join(map(str, speaker))} ↔ {', '.join(map(str, addressee))}"
            )

        self._target_var.set(self._compact_json(doc.get("target", {"type": "entity.any"})))
        slots = doc.get("slots", {})
        self._slots_var.set(self._compact_json(slots))

        unknown = describe_unknown_fields(doc)
        self._unknown_fields_var.set(", ".join(unknown.keys()) if unknown else "(none)")

        cond_parts: list[str] = []
        if slots:
            cond_parts.append(f"Slots: {len(slots)}")
        if unknown:
            cond_parts.append(f"Extra fields: {', '.join(unknown.keys())}")
        self._conditional_meta_var.set(" · ".join(cond_parts))
        self._set_visible(self._conditional_meta_label, bool(cond_parts))

        aff = doc.get("affordance")
        aff_label = aff.get("label") if isinstance(aff, dict) and isinstance(aff.get("label"), str) else ""
        self._affordance_label_var.set(aff_label)
        self._loaded_affordance_label = aff_label

        say = doc.get("say")
        say_single = say if isinstance(say, str) else ""
        self._say_single_var.set(say_single)
        self._loaded_say_single = say_single

        exe = doc.get("execute")
        exe_action = exe.get("use", "") if isinstance(exe, dict) else (exe if isinstance(exe, str) else "")
        self._execute_action_var.set(exe_action)
        self._loaded_execute_action = exe_action

        after = doc.get("after")
        if isinstance(after, dict) and after.get("recommend"):
            self._after_mode_var.set("recommend")
        elif isinstance(after, dict) and after.get("continue"):
            self._after_mode_var.set("continue")
        else:
            self._after_mode_var.set("end")

        reply = doc.get("reply")
        if isinstance(reply, dict) and reply:
            keys = sorted(str(k) for k in reply.keys())
            self._reply_summary_var.set(f"Outcomes: {', '.join(keys)}")
            first_key = keys[0]
            self._reply_outcome_var.set(first_key)
            first_branch = reply.get(first_key)
            self._reply_say_var.set(
                str(first_branch.get("say") or "") if isinstance(first_branch, dict) else ""
            )
        else:
            self._reply_summary_var.set("Outcomes: (none)")
            self._reply_say_var.set("")

        for descriptor in self._field_descriptors + self._s11_json_descriptors:
            name = str(descriptor["name"])
            self._write_json_editor(name, doc.get(name))
        for descriptor in self._s11_scalar_descriptors:
            name = str(descriptor["name"])
            val = doc.get(name)
            self._s11_scalar_vars[name].set("" if val is None else str(val))

        has_advanced_s11 = any(doc.get(name) for name in _S11_ADVANCED_NAMES)
        self._advanced_s11_visible = has_advanced_s11
        self._set_visible(self._advanced_s11_frame, has_advanced_s11)

        # Kind-specific surface switching (non-dialogue safety)
        is_dialogue = kind == "dialogue"
        is_realization = kind == "realization"
        is_beh_or_beat = kind in ("behavior", "beat")
        self._set_visible(self._dialogue_normal_frame, is_dialogue)
        self._set_visible(self._realization_panel, is_realization)
        self._set_visible(self._non_dialogue_route_panel, is_beh_or_beat)
        if is_beh_or_beat:
            self._non_dialogue_route_var.set(
                f"{kind.capitalize()} {canonical_id} is authored in Interaction Modules (read-only here)."
            )
        if is_realization:
            act = str(doc.get("dialogueAct") or "")
            strat = str(doc.get("strategy") or "")
            conc = str(doc.get("concept") or "")
            self._real_act_var.set(act)
            self._real_strategy_var.set(strat)
            self._real_concept_var.set(conc)
            self._loaded_real_act = act
            self._loaded_real_strategy = strat
            self._loaded_real_concept = conc
            trans = doc.get("translations")
            self._loaded_real_translations = copy.deepcopy(trans)
            self._real_translations_editor.delete("1.0", "end")
            if trans is not None:
                self._real_translations_editor.insert("1.0", self._pretty(trans))

    def _form_document(self) -> dict[str, Any]:
        if self._document is None:
            raise ValueError("Select or create a ConvoEngine family first")
        doc = copy.deepcopy(self._document)
        kind = str(
            doc.get("kind")
            or (self._current_entry or {}).get("kind")
            or self._kind_var.get().strip()
            or "dialogue"
        )
        if kind in ("behavior", "beat"):
            # Non-dialogue safety: never mutate behavior/beat via dialogue form
            return doc
        if kind == "realization":
            act = self._real_act_var.get().strip()
            if act != self._loaded_real_act:
                if act:
                    doc["dialogueAct"] = act
                else:
                    doc.pop("dialogueAct", None)
            strat = self._real_strategy_var.get().strip()
            if strat != self._loaded_real_strategy:
                if strat:
                    doc["strategy"] = strat
                else:
                    doc.pop("strategy", None)
            conc = self._real_concept_var.get().strip()
            if conc != self._loaded_real_concept:
                if conc:
                    doc["concept"] = conc
                else:
                    doc.pop("concept", None)
            raw_trans = self._real_translations_editor.get("1.0", "end").strip()
            parsed_trans = json.loads(raw_trans) if raw_trans else None
            if parsed_trans != self._loaded_real_translations:
                if parsed_trans is None:
                    doc.pop("translations", None)
                else:
                    doc["translations"] = parsed_trans
            return doc

        doc["schema"] = "psychopatz.convo-engine.v1"
        doc["kind"] = self._kind_var.get().strip() or "dialogue"
        ns = self._namespace_var.get().strip()
        if ns:
            doc["namespace"] = ns
        else:
            doc.pop("namespace", None)
        doc["id"] = self._id_var.get().strip()
        owner = self._owner_var.get().strip()
        if owner:
            doc["owner"] = owner
        doc["participants"] = {
            "speaker": json.loads(self._speaker_var.get()),
            "addressee": json.loads(self._addressee_var.get()),
        }
        slots = json.loads(self._slots_var.get())
        if slots:
            doc["slots"] = slots
        else:
            doc.pop("slots", None)
        for descriptor in self._field_descriptors + self._s11_json_descriptors:
            name = str(descriptor["name"])
            value = self._read_json_editor(name)
            if value is None:
                doc.pop(name, None)
            else:
                doc[name] = value
        for descriptor in self._s11_scalar_descriptors:
            name = str(descriptor["name"])
            raw_scalar = self._s11_scalar_vars[name].get().strip()
            if raw_scalar:
                doc[name] = raw_scalar
            else:
                doc.pop(name, None)

        single_say = self._say_single_var.get().strip()
        if single_say != self._loaded_say_single:
            if single_say:
                doc["say"] = single_say
            elif isinstance(doc.get("say"), str):
                doc.pop("say", None)
        elif single_say and "say" not in doc:
            doc["say"] = single_say

        aff_label = self._affordance_label_var.get().strip()
        if aff_label != self._loaded_affordance_label or (aff_label and "affordance" not in doc):
            if aff_label:
                aff_obj = copy.deepcopy(doc.get("affordance") or {})
                if isinstance(aff_obj, dict) and isinstance(aff_obj.get("label"), str | type(None)):
                    aff_obj["label"] = aff_label
                    doc["affordance"] = aff_obj

        exe_action = self._execute_action_var.get().strip()
        if exe_action != self._loaded_execute_action or (exe_action and "execute" not in doc):
            if exe_action:
                exe_obj = doc.get("execute")
                if isinstance(exe_obj, dict):
                    exe_obj["use"] = exe_action
                else:
                    doc["execute"] = exe_action
        return doc

    def add_recommendation(self) -> None:
        if self._document is None:
            return
        target = self._recommend_pick_var.get().strip()
        if not target:
            return
        after = self._read_json_editor("after") or {}
        if not isinstance(after, dict):
            after = {}
        rec = list(after.get("recommend") or [])
        if target not in rec:
            rec.append(target)
        after["recommend"] = rec
        self._after_mode_var.set("recommend")
        self._write_json_editor("after", after)
        self._status_var.set(f"Added recommendation {target}; validate and write explicitly")

    def set_reply_outcome(self) -> None:
        if self._document is None:
            return
        outcome = self._reply_outcome_var.get().strip()
        say_text = self._reply_say_var.get().strip()
        if not outcome or not say_text:
            return
        reply = self._read_json_editor("reply") or {}
        if not isinstance(reply, dict):
            reply = {}
        branch = copy.deepcopy(reply.get(outcome) or {})
        branch["say"] = say_text
        reply[outcome] = branch
        self._write_json_editor("reply", reply)
        self._reply_summary_var.set(f"Outcomes: {', '.join(sorted(str(k) for k in reply.keys()))}")
        self._status_var.set(f"Updated reply.{outcome}; validate and write explicitly")

    def delete_reply_outcome(self) -> None:
        if self._document is None:
            return
        outcome = self._reply_outcome_var.get().strip()
        reply = self._read_json_editor("reply") or {}
        if isinstance(reply, dict) and outcome in reply:
            reply.pop(outcome)
            self._write_json_editor("reply", reply or None)
            self._reply_summary_var.set(
                f"Outcomes: {', '.join(sorted(str(k) for k in reply.keys()))}" if reply else "Outcomes: (none)"
            )
            self._status_var.set(f"Removed reply.{outcome}; validate and write explicitly")

    def new_family(self) -> None:
        owner = self._owner_var.get().strip() or "ProjectHoomans"
        kind = self._kind_var.get().strip() or "dialogue"
        ns = self._namespace_var.get().strip() or "social"
        fid = f"family_{len(self._families) + 1}"
        spec = {
            "kind": kind,
            "namespace": ns,
            "id": fid,
            "owner": owner,
            "participants": {"speaker": ["participant"], "addressee": ["participant"]},
            "affordance": {"label": "Talk about topic"},
            "say": "New ConvoEngine utterance.",
            "reply": {"acknowledged": {"say": "Understood."}},
        }
        res = self.service.dispatch_operation(
            "convo.change.preview",
            {
                "operation": "create",
                "requestedOwner": owner,
                "document": spec,
            },
        )
        if res.get("ok") is True:
            self._document = copy.deepcopy(res["document"])
            self._current_entry = None
            self._loaded_fingerprint = None
            self._load_family_form(self._document)
            self._status_var.set(f"Drafted new family {ns}.{fid} in memory; write explicitly")
        else:
            self._status_var.set("New family draft failed validation")

    def duplicate_family(self) -> None:
        if self._document is None:
            return
        dup = copy.deepcopy(self._document)
        dup["id"] = f"{dup.get('id', 'family')}_copy"
        self._document = dup
        self._current_entry = None
        self._loaded_fingerprint = None
        self._load_family_form(dup)
        self._status_var.set(f"Duplicated as {dup['id']} in memory; write explicitly")

    def delete_family(self) -> dict[str, Any] | None:
        if self._current_entry is None:
            return None
        target = self._current_entry.get("sourcePath") or self._current_entry.get("canonicalID")
        if not self._messagebox.askyesno(
            "Delete ConvoEngine family",
            f"Delete canonical source {self._current_entry['canonicalID']} ({Path(str(target)).name})?",
        ):
            return {"ok": False, "cancelled": True, "writes": []}
        payload = {
            "operation": "delete",
            "target": target,
            "expectedFingerprint": self._loaded_fingerprint,
        }
        try:
            res = self.service.dispatch_operation("convo.change.apply", payload)
        except (OSError, ValueError) as error:
            res = {"ok": False, "diagnostics": [{"severity": "error", "message": str(error)}], "writes": []}
        self._set_report(res)
        if res.get("ok") is True:
            self._loaded_fingerprint = None
            self._current_entry = None
            self._current_family_id = None
            self.refresh()
            self._status_var.set("Deleted canonical family source via ConvoTransaction")
        else:
            diags = res.get("diagnostics") or []
            msg = diags[0].get("message") if diags else "Delete rejected"
            self._status_var.set(f"Delete rejected: {msg}")
        return res

    def preview_record(self) -> dict[str, Any] | None:
        try:
            doc = self._form_document()
            kind = str(doc.get("kind") or "dialogue")
            if kind in ("behavior", "beat"):
                report = {
                    "ok": False,
                    "reason": "non_dialogue_kind_route",
                    "kind": kind,
                    "diagnostics": [
                        {
                            "severity": "info",
                            "message": f"{kind.capitalize()} families are validated and edited in Interaction Modules.",
                        }
                    ],
                }
                self._set_report(report)
                self._status_var.set(f"{kind.capitalize()} must be edited in Interaction Modules")
                return report
            if kind == "realization":
                existing_path = (self._current_entry or {}).get("sourcePath")
                report = self.service.dispatch_operation(
                    "convo.change.preview",
                    {
                        "operation": "write" if existing_path else "create",
                        "target": existing_path,
                        "requestedOwner": doc.get("owner"),
                        "document": doc,
                        "allowLegacySchema": False,
                    },
                )
                self._set_report(report)
                self._status_var.set(
                    "Validated canonical Realization record"
                    if report.get("ok") is True
                    else "Realization validation rejected"
                )
                return report
            report = self.service.dispatch_operation(
                "convo.simulate",
                {
                    "document": doc,
                    "sourcePath": (self._current_entry or {}).get("sourcePath"),
                    "speaker": "player",
                    "addressee": "npc",
                    "npcTarget": "companion",
                    "slotValues": {},
                    "style": "neutral",
                    "locale": "EN",
                    "resultOutcome": None,
                },
            )
            self._set_report(report)
            self._status_var.set(
                "Validated canonical ConvoEngine record"
                if report.get("ok") is True
                else "ConvoEngine validation rejected"
            )
            return report
        except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError) as error:
            report = {"ok": False, "diagnostics": [{"severity": "error", "message": str(error)}]}
            self._set_report(report)
            self._status_var.set(f"Validation failed: {error}")
            return report

    def write_source(self) -> dict[str, Any]:
        if self._document is None:
            return {"ok": False, "writes": [], "reason": "no_family"}
        cur_kind = str(
            self._document.get("kind")
            or (self._current_entry or {}).get("kind")
            or self._kind_var.get().strip()
            or "dialogue"
        )
        if cur_kind in ("behavior", "beat"):
            res = {
                "ok": False,
                "writes": [],
                "reason": "non_dialogue_kind_route",
                "message": f"{cur_kind.capitalize()} families must be edited in Interaction Modules",
            }
            self._set_report(res)
            self._status_var.set(res["message"])
            return res
        report = self.preview_record()
        if not report or report.get("ok") is not True:
            return report or {"ok": False, "writes": []}
        doc = self._form_document()
        existing_path = (self._current_entry or {}).get("sourcePath")
        if not self._messagebox.askyesno(
            "Write ConvoEngine source",
            f"Write validated family {doc['id']} ({doc.get('owner') or 'auto'})?",
        ):
            return {"ok": False, "cancelled": True, "writes": []}
        payload = {
            "operation": "write" if existing_path else "create",
            "target": existing_path,
            "expectedFingerprint": self._loaded_fingerprint if existing_path else None,
            "requestedOwner": doc.get("owner"),
            "document": doc,
            "allowLegacySchema": False,
        }
        try:
            written = self.service.dispatch_operation("convo.change.apply", payload)
        except (OSError, ValueError) as error:
            written = {"ok": False, "diagnostics": [{"severity": "error", "message": str(error)}], "writes": []}
        self._set_report(written)
        self._status_var.set(
            "Canonical ConvoEngine source committed via ConvoTransaction"
            if written.get("ok") is True
            else "Write rejected by ConvoTransaction / CodeBuilder validation"
        )
        if written.get("ok") is True:
            self._loaded_fingerprint = written.get("sourceFingerprint")
            saved_fid = self._current_family_id
            self.refresh()
            if hasattr(self, "completeness_workbench") and self.completeness_workbench._report and saved_fid:
                self.completeness_workbench.run_affected_analysis([saved_fid])
        return written

    def run_integrity_audit(self) -> dict[str, Any]:
        report = self.service.dispatch_operation("convo.audit", {"checkDeterminism": False})
        self._set_report(report)
        self._status_var.set(
            f"ConvoEngine Integrity Audit OK ({report['stats']['familyFilesChecked']} families, 0 violations)"
            if report.get("ok") is True
            else f"ConvoEngine Integrity Audit found {report.get('violationCount')} violations"
        )
        return report


__all__ = ["ConvoEngineAuthoringPane"]
