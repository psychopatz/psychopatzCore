"""Production-flow graph model and the Semantic Lab visual editor pane."""

from __future__ import annotations

import copy
import json
from typing import Any, Callable

from tools.semantic_harness.codebuilder.blocks import GATE_TYPES, TRANSITION_FIELDS
from tools.semantic_harness.codebuilder.codeblocks import (
    codeblocks_to_flow,
    flow_to_codeblocks,
    validate_codeblock_document,
)
from .model import (
    graph_transform,
    graph_inverse,
    graph_render_mode,
    flow_draft,
    flow_display_name,
    flow_graph_model,
    coverage_summary,
    coverage_lines,
    _json_text,
)
from .state import FlowEditorHistory
from .canvas import FlowEditorCanvasController
from .actions import FlowEditorActions

class FlowEditorPane:
    """Visual graph plus bounded form editor backed by worker callbacks."""

    def __init__(
        self,
        parent: Any,
        tk_module: Any,
        ttk: Any,
        scrolled_text: Any,
        filedialog: Any,
        messagebox: Any,
        *,
        on_refresh: Callable[[], Any],
        on_validate: Callable[[dict[str, Any]], Any],
        on_register: Callable[[dict[str, Any]], Any],
    ) -> None:
        self._tk = tk_module
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._filedialog = filedialog
        self._messagebox = messagebox
        self._on_refresh = on_refresh
        self._on_validate = on_validate
        self._on_register = on_register
        self._catalog: dict[str, dict[str, Any]] = {}
        self._flow_id_to_label: dict[str, str] = {}
        self._flow_label_to_id: dict[str, str] = {}
        self._draft: dict[str, Any] | None = None
        self._selected_node: str | None = None
        self._node_positions: dict[str, tuple[float, float]] = {}
        self._fact_catalog: list[dict[str, Any]] = []
        self._command_catalog: list[str] = []
        self._action_catalog: list[dict[str, Any]] = []
        self._trigger_catalog: list[dict[str, Any]] = []
        self._coverage: list[dict[str, Any]] = []
        self._history = FlowEditorHistory()
        self._canvas_controller = FlowEditorCanvasController(self)
        self._actions_controller = FlowEditorActions(self)
        self._nested_flows: list[dict[str, Any]] = []
        self._zoom = 1.0
        self._pan = (24.0, 42.0)
        self._drag_node: str | None = None
        self._drag_anchor: tuple[float, float] | None = None
        self._drag_origin: tuple[float, float] | None = None
        self._pan_anchor: tuple[float, float] | None = None
        self._pan_origin: tuple[float, float] | None = None

        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self._build_toolbar()
        self._build_body()
        self.set_status("Load a production flow to begin editing.")

    def _build_toolbar(self) -> None:
        ttk = self._ttk
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(0, weight=1)
        self.flow_var = self._tk.StringVar()

        primary_toolbar = ttk.Frame(toolbar)
        primary_toolbar.grid(row=0, column=0, sticky="w")

        self.refresh_button = ttk.Button(
            primary_toolbar, text="Refresh registry", command=self._on_refresh
        )
        self.refresh_button.grid(row=0, column=0)
        self.coverage_button = ttk.Button(
            primary_toolbar, text="Coverage", command=self.show_coverage
        )
        self.coverage_button.grid(row=0, column=1, padx=(6, 0))
        self.validate_button = ttk.Button(
            primary_toolbar, text="Validate draft", command=self.validate_draft
        )
        self.validate_button.grid(row=0, column=2, padx=(6, 0))
        self.register_button = ttk.Button(
            primary_toolbar, text="Register draft", command=self.register_draft
        )
        self.register_button.grid(row=0, column=3, padx=(6, 0))
        self.add_button = ttk.Button(
            primary_toolbar, text="Add node", command=self.add_node
        )
        self.add_button.grid(row=0, column=4, padx=(10, 0))
        self.duplicate_button = ttk.Button(
            primary_toolbar, text="Duplicate", command=self.duplicate_node
        )
        self.duplicate_button.grid(row=0, column=5, padx=(4, 0))
        self.delete_button = ttk.Button(
            primary_toolbar, text="Delete", command=self.delete_node
        )
        self.delete_button.grid(row=0, column=6, padx=(4, 0))
        self.undo_button = ttk.Button(primary_toolbar, text="Undo", command=self.undo)
        self.undo_button.grid(row=0, column=7, padx=(10, 0))
        self.redo_button = ttk.Button(primary_toolbar, text="Redo", command=self.redo)
        self.redo_button.grid(row=0, column=8, padx=(4, 0))
        self.fit_button = ttk.Button(primary_toolbar, text="Fit", command=self.fit_graph)
        self.fit_button.grid(row=0, column=9, padx=(10, 0))
        self.zoom_button = ttk.Button(
            primary_toolbar, text="100%", command=self.reset_zoom
        )
        self.zoom_button.grid(row=0, column=10, padx=(4, 0))

        secondary_toolbar = ttk.Frame(toolbar)
        secondary_toolbar.grid(row=1, column=0, sticky="ew", pady=(4, 0))
        secondary_toolbar.columnconfigure(8, weight=1)

        self.load_button = ttk.Button(
            secondary_toolbar, text="Open draft", command=self.load_draft
        )
        self.load_button.grid(row=0, column=0, padx=(0, 0))
        self.save_button = ttk.Button(
            secondary_toolbar, text="Save draft", command=self.save_draft
        )
        self.save_button.grid(row=0, column=1, padx=(6, 0))
        self.rename_button = ttk.Button(
            secondary_toolbar, text="Rename", command=self.rename_node
        )
        self.rename_button.grid(row=0, column=2, padx=(10, 0))
        self.connect_button = ttk.Button(
            secondary_toolbar, text="Connect", command=self.connect_node
        )
        self.connect_button.grid(row=0, column=3, padx=(4, 0))
        self.trigger_button = ttk.Button(
            secondary_toolbar, text="Add trigger", command=self.add_trigger
        )
        self.trigger_button.grid(row=0, column=4, padx=(8, 0))
        self.command_button = ttk.Button(
            secondary_toolbar, text="Add action", command=self.add_command_trigger
        )
        self.command_button.grid(row=0, column=5, padx=(4, 0))
        self.status_var = self._tk.StringVar()
        ttk.Label(toolbar, textvariable=self.status_var).grid(
            row=2, column=0, sticky="w", pady=(4, 0)
        )
        self._action_buttons = (
            self.refresh_button,
            self.coverage_button,
            self.validate_button,
            self.register_button,
            self.add_button,
            self.duplicate_button,
            self.delete_button,
            self.rename_button,
            self.connect_button,
            self.trigger_button,
            self.command_button,
            self.undo_button,
            self.redo_button,
            self.fit_button,
            self.zoom_button,
            self.load_button,
            self.save_button,
        )

    def _build_body(self) -> None:
        ttk = self._ttk
        body = ttk.PanedWindow(self.frame, orient="horizontal")
        body.grid(row=1, column=0, sticky="nsew")

        flow_frame = ttk.LabelFrame(body, text="Production flows")
        flow_frame.rowconfigure(0, weight=1)
        flow_frame.columnconfigure(0, weight=1)
        self.flow_list = self._tk.Listbox(
            flow_frame, width=34, height=12, exportselection=False,
            selectmode="browse", activestyle="dotbox",
        )
        self.flow_list.grid(row=0, column=0, sticky="nsew")
        flow_scroll = ttk.Scrollbar(
            flow_frame, orient="vertical", command=self.flow_list.yview,
        )
        flow_scroll.grid(row=0, column=1, sticky="ns")
        self.flow_list.configure(yscrollcommand=flow_scroll.set)
        self.flow_list.bind("<<ListboxSelect>>", self._on_flow_list_select)
        body.add(flow_frame, weight=1)

        graph_frame = ttk.LabelFrame(body, text="Flow graph · nodes and transitions")
        graph_frame.rowconfigure(1, weight=1)
        graph_frame.columnconfigure(0, weight=1)
        self.graph_hint_var = self._tk.StringVar(value="Select a production flow")
        ttk.Label(
            graph_frame, textvariable=self.graph_hint_var, anchor="w",
        ).grid(row=0, column=0, columnspan=2, sticky="ew", padx=8, pady=(2, 4))
        self.canvas = self._tk.Canvas(
            graph_frame,
            width=680,
            height=560,
            background="#10151b",
            highlightthickness=0,
        )
        self.canvas.grid(row=1, column=0, sticky="nsew")
        self.canvas.bind("<MouseWheel>", self._on_mouse_wheel)
        self.canvas.bind("<Button-4>", lambda event: self._zoom_at(event, 1.12))
        self.canvas.bind("<Button-5>", lambda event: self._zoom_at(event, 1 / 1.12))
        self.canvas.bind("<Button-1>", self._on_canvas_left_down)
        self.canvas.bind("<B1-Motion>", self._drag_node_motion)
        self.canvas.bind("<ButtonRelease-1>", self._stop_node_drag)
        self.canvas.bind("<Button-2>", self._start_pan)
        self.canvas.bind("<B2-Motion>", self._drag_pan)
        self.canvas.bind("<ButtonRelease-2>", self._stop_pan)
        self.canvas.bind("<Configure>", lambda _event: self._draw_graph())
        y_scroll = ttk.Scrollbar(
            graph_frame, orient="vertical", command=self.canvas.yview
        )
        y_scroll.grid(row=1, column=1, sticky="ns")
        x_scroll = ttk.Scrollbar(
            graph_frame, orient="horizontal", command=self.canvas.xview
        )
        x_scroll.grid(row=2, column=0, sticky="ew")
        self.canvas.configure(xscrollcommand=x_scroll.set, yscrollcommand=y_scroll.set)
        body.add(graph_frame, weight=4)

        form_panel = ttk.LabelFrame(body, text="Editable flow definition")
        form_panel.rowconfigure(0, weight=1)
        form_panel.columnconfigure(0, weight=1)
        form_canvas = self._tk.Canvas(form_panel, highlightthickness=0)
        form_canvas.grid(row=0, column=0, sticky="nsew")
        form_scroll = ttk.Scrollbar(
            form_panel, orient="vertical", command=form_canvas.yview
        )
        form_scroll.grid(row=0, column=1, sticky="ns")
        form_canvas.configure(yscrollcommand=form_scroll.set)
        form_frame = ttk.Frame(form_canvas)
        form_frame.columnconfigure(1, weight=1)
        form_frame.rowconfigure(11, weight=1)
        form_frame.rowconfigure(13, weight=1)
        form_window = form_canvas.create_window((0, 0), window=form_frame, anchor="nw")

        def update_form_scroll_region(_event: Any = None) -> None:
            form_canvas.configure(scrollregion=form_canvas.bbox("all"))

        def resize_form_content(event: Any) -> None:
            form_canvas.itemconfigure(form_window, width=event.width)

        form_frame.bind("<Configure>", update_form_scroll_region)
        form_canvas.bind("<Configure>", resize_form_content)
        body.add(form_panel, weight=2)

        self.flow_id_var = self._tk.StringVar()
        self.owner_var = self._tk.StringVar()
        self.initial_var = self._tk.StringVar()
        self._add_entry(form_frame, 0, "Flow ID", self.flow_id_var)
        self._add_entry(form_frame, 1, "Owner", self.owner_var)
        self._add_entry(form_frame, 2, "Initial node", self.initial_var)

        ttk.Label(form_frame, text="Triggers (JSON frames)").grid(
            row=3, column=0, sticky="nw", padx=(6, 6), pady=(8, 2)
        )
        self.triggers_text = self._ScrolledText(form_frame, height=5, width=38, wrap="none")
        self.triggers_text.grid(row=3, column=1, sticky="ew", padx=(0, 6), pady=(8, 2))

        ttk.Separator(form_frame).grid(
            row=4, column=0, columnspan=2, sticky="ew", padx=6, pady=6
        )
        ttk.Label(form_frame, text="Selected node").grid(
            row=5, column=0, sticky="w", padx=(6, 6), pady=2
        )
        self.node_var = self._tk.StringVar()
        self.node_box = ttk.Combobox(
            form_frame, textvariable=self.node_var, state="readonly", width=25
        )
        self.node_box.grid(row=5, column=1, sticky="ew", padx=(0, 6), pady=2)
        self.node_box.bind("<<ComboboxSelected>>", lambda _: self._select_node())

        self.terminal_var = self._tk.BooleanVar(value=False)
        ttk.Checkbutton(
            form_frame, text="Terminal node", variable=self.terminal_var
        ).grid(row=6, column=1, sticky="w", padx=(0, 6), pady=2)
        self.response_pool_var = self._tk.StringVar()
        self.response_template_var = self._tk.StringVar()
        self._add_entry(form_frame, 7, "Response pool", self.response_pool_var)
        self._add_entry(form_frame, 8, "Response template", self.response_template_var)

        gate_frame = ttk.LabelFrame(form_frame, text="Gate / engine variable")
        gate_frame.grid(row=9, column=0, columnspan=2, sticky="ew", padx=6, pady=6)
        gate_frame.columnconfigure(1, weight=1)
        self.gate_type_var = self._tk.StringVar(value="none")
        self.gate_fact_var = self._tk.StringVar()
        self.gate_field_var = self._tk.StringVar()
        self.gate_operator_var = self._tk.StringVar(value="==")
        self.gate_value_var = self._tk.StringVar()
        self.gate_start_var = self._tk.StringVar()
        self.gate_end_var = self._tk.StringVar()
        self.gate_unknown_policy_var = self._tk.StringVar(value="tri_state")
        self._add_combo(gate_frame, 0, "Type", self.gate_type_var, GATE_TYPES)
        self.fact_box = self._add_combo(gate_frame, 1, "Fact", self.gate_fact_var, ())
        self._add_combo(gate_frame, 2, "Operator", self.gate_operator_var, ("==", "~=", ">=", "<=", ">", "<", "contains"))
        self._add_entry(gate_frame, 3, "Field", self.gate_field_var)
        self._add_entry(gate_frame, 4, "Value", self.gate_value_var)
        self._add_entry(gate_frame, 5, "Start hour", self.gate_start_var)
        self._add_entry(gate_frame, 6, "End hour", self.gate_end_var)
        self._add_combo(gate_frame, 7, "Unknown", self.gate_unknown_policy_var, ("tri_state", "pass", "fail"))

        transitions_frame = ttk.LabelFrame(form_frame, text="Transitions")
        transitions_frame.grid(row=10, column=0, columnspan=2, sticky="ew", padx=6, pady=6)
        transitions_frame.columnconfigure(1, weight=1)
        self.transition_vars: dict[str, Any] = {}
        for offset, field in enumerate(TRANSITION_FIELDS):
            variable = self._tk.StringVar()
            self.transition_vars[field] = variable
            ttk.Label(transitions_frame, text=field).grid(
                row=offset, column=0, sticky="w", padx=6, pady=2
            )
            ttk.Entry(transitions_frame, textvariable=variable).grid(
                row=offset, column=1, sticky="ew", padx=(0, 6), pady=2
            )

        accepts_frame = ttk.LabelFrame(form_frame, text="Accepted frames (JSON)")
        accepts_frame.grid(row=11, column=0, columnspan=2, sticky="nsew", padx=6, pady=6)
        accepts_frame.rowconfigure(0, weight=1)
        accepts_frame.columnconfigure(0, weight=1)
        self.accepts_text = self._ScrolledText(accepts_frame, height=7, width=38, wrap="none")
        self.accepts_text.grid(row=0, column=0, sticky="nsew")

        branch_offers_frame = ttk.LabelFrame(form_frame, text="Branch offers (JSON)")
        branch_offers_frame.grid(
            row=12, column=0, columnspan=2, sticky="nsew", padx=6, pady=6
        )
        branch_offers_frame.rowconfigure(0, weight=1)
        branch_offers_frame.columnconfigure(0, weight=1)
        self.branch_offers_text = self._ScrolledText(
            branch_offers_frame, height=7, width=38, wrap="none"
        )
        self.branch_offers_text.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        self.apply_button = ttk.Button(
            form_frame, text="Apply node fields", command=self.apply_node_fields
        )
        self.apply_button.grid(row=13, column=1, sticky="e", padx=6, pady=(0, 6))
        codeblocks_frame = ttk.LabelFrame(form_frame, text="Declarative codeblocks · typed round trip")
        codeblocks_frame.grid(row=14, column=0, columnspan=2, sticky="nsew", padx=6, pady=6)
        codeblocks_frame.rowconfigure(0, weight=1)
        codeblocks_frame.columnconfigure(0, weight=1)
        self.codeblocks_text = self._ScrolledText(
            codeblocks_frame, height=12, width=38, wrap="none"
        )
        self.codeblocks_text.grid(row=0, column=0, sticky="nsew")
        codeblock_buttons = ttk.Frame(codeblocks_frame)
        codeblock_buttons.grid(row=1, column=0, sticky="e", pady=(6, 0))
        self.sync_codeblocks_button = ttk.Button(
            codeblock_buttons, text="Sync from graph", command=self.sync_codeblocks
        )
        self.sync_codeblocks_button.pack(side="left")
        self.validate_codeblocks_button = ttk.Button(
            codeblock_buttons, text="Validate codeblocks", command=self.validate_codeblocks
        )
        self.validate_codeblocks_button.pack(side="left", padx=6)
        self.apply_codeblocks_button = ttk.Button(
            codeblock_buttons, text="Apply codeblocks", command=self.apply_codeblocks
        )
        self.apply_codeblocks_button.pack(side="left")
        self._action_buttons = self._action_buttons + (
            self.apply_button,
            self.sync_codeblocks_button,
            self.validate_codeblocks_button,
            self.apply_codeblocks_button,
        )

    def _add_entry(self, parent: Any, row: int, label: str, variable: Any) -> None:
        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=(6, 6), pady=2
        )
        self._ttk.Entry(parent, textvariable=variable).grid(
            row=row, column=1, sticky="ew", padx=(0, 6), pady=2
        )

    def _add_combo(self, parent: Any, row: int, label: str, variable: Any, values: Any) -> Any:
        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=6, pady=2
        )
        combo = self._ttk.Combobox(
            parent, textvariable=variable, values=values, width=25,
            state="normal",
        )
        combo.grid(row=row, column=1, sticky="ew", padx=(0, 6), pady=2)
        return combo

    def set_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        for button in self._action_buttons:
            button.configure(state=state)
        self.flow_list.configure(state=state)
        self.node_box.configure(state="readonly" if enabled else "disabled")
        self.codeblocks_text.configure(state=state)

    def set_status(self, value: str) -> None:
        self.status_var.set(value)

    def set_catalog(self, catalog: dict[str, Any] | list[dict[str, Any]]) -> None:
        flows = catalog.get("flows", []) if isinstance(catalog, dict) else catalog
        if isinstance(catalog, dict):
            raw_actions = catalog.get("actionCatalog", [])
            self._action_catalog = [
                copy.deepcopy(action) for action in raw_actions
                if isinstance(action, dict) and action.get("id")
            ]
            if not self._action_catalog:
                self._action_catalog = [
                    {"id": str(action), "recognized": True}
                    for action in catalog.get("commandCatalog", [])
                    if str(action)
                ]
            self._command_catalog = [
                str(action.get("id")) for action in self._action_catalog
                if action.get("id")
            ]
            self._trigger_catalog = [
                copy.deepcopy(trigger) for trigger in catalog.get("triggerCatalog", [])
                if isinstance(trigger, dict) and trigger.get("id")
            ]
            self._fact_catalog = [
                copy.deepcopy(fact) for fact in catalog.get("factCatalog", [])
                if isinstance(fact, dict) and fact.get("id")
            ]
            if hasattr(self, "fact_box"):
                self.fact_box.configure(
                    values=[fact["id"] for fact in self._fact_catalog]
                )
            generation = catalog.get("generation", {})
            raw_coverage = generation.get("coverage")
            if not isinstance(raw_coverage, list):
                raw_coverage = catalog.get("capabilityCoverage", [])
            self._coverage = [
                copy.deepcopy(row) for row in raw_coverage
                if isinstance(row, dict)
            ]
        self._catalog = {
            str(flow.get("id")): flow_draft(flow)
            for flow in flows
            if isinstance(flow, dict) and flow.get("id")
        }
        flow_ids = sorted(self._catalog)
        self._flow_id_to_label = {}
        self._flow_label_to_id = {}
        for flow_id in flow_ids:
            label = flow_display_name(flow_id, self._catalog[flow_id])
            if label in self._flow_label_to_id:
                label = f"{label} [{flow_id}]"
            self._flow_id_to_label[flow_id] = label
            self._flow_label_to_id[label] = flow_id
        selected_id = self.flow_var.get() if self.flow_var.get() in self._catalog else (
            flow_ids[0] if flow_ids else ""
        )
        self.flow_list.delete(0, "end")
        for flow_id in flow_ids:
            self.flow_list.insert("end", self._flow_id_to_label[flow_id])
        self.flow_var.set(selected_id)
        if selected_id:
            selected_index = flow_ids.index(selected_id)
            self.flow_list.selection_clear(0, "end")
            self.flow_list.selection_set(selected_index)
            self.flow_list.activate(selected_index)
            self.flow_list.see(selected_index)
        self._select_flow()
        summary = coverage_summary(self._coverage)
        if summary:
            self.set_status(
                f"{len(flow_ids)} production flows loaded · "
                f"coverage generated={summary.get('generated', 0)}"
                f"/{len(self._coverage)}"
            )
        else:
            self.set_status(f"{len(flow_ids)} production flows loaded")

    def show_coverage(self) -> None:
        if not self._coverage:
            self.set_status("No live capability coverage is loaded; refresh registry")
            return
        summary = coverage_summary(self._coverage)
        heading = ", ".join(
            f"{key}={summary[key]}" for key in sorted(summary)
        )
        self._messagebox.showinfo(
            "Semantic capability coverage",
            "Live production capability coverage: " + heading
            + "\n\n" + "\n".join(coverage_lines(self._coverage)),
        )
        self.set_status("Displayed live capability coverage and exact reasons")

    def _on_flow_list_select(self, _event: Any) -> None:
        selection = self.flow_list.curselection()
        if not selection:
            return
        label = str(self.flow_list.get(selection[0]))
        self.flow_var.set(self._flow_label_to_id.get(label, label))
        self._select_flow()

    def _select_flow_list_item(self, flow_id: str) -> None:
        items = self.flow_list.get(0, "end")
        label = self._flow_id_to_label.get(flow_id, flow_id)
        self.flow_list.selection_clear(0, "end")
        for index, item in enumerate(items):
            if str(item) == label:
                self.flow_list.selection_set(index)
                self.flow_list.activate(index)
                self.flow_list.see(index)
                return

    def select_flow(self, flow_id: str) -> None:
        """Open a registered flow selected from the interaction explorer."""

        flow_id = str(flow_id)
        if flow_id not in self._catalog:
            self.set_status(f"Flow is not in the live catalog: {flow_id}")
            return
        self.flow_var.set(flow_id)
        self._select_flow_list_item(flow_id)
        self._select_flow()

    def _select_flow(self) -> None:
        flow = self._catalog.get(self.flow_var.get())
        if flow is None:
            self._draft = None
            self._selected_node = None
            self._draw_graph()
            return
        self._draft = flow_draft(flow)
        authoring_metadata = self._draft.get("_semanticLab")
        self._nested_flows = (
            copy.deepcopy(authoring_metadata.get("nestedFlows", []))
            if isinstance(authoring_metadata, dict)
            and isinstance(authoring_metadata.get("nestedFlows"), list)
            else []
        )
        self._history.reset(flow_draft(self._draft))
        self._node_positions = {}
        self._selected_node = self._draft.get("initial")
        if self._selected_node not in (self._draft.get("nodes") or {}):
            self._selected_node = next(iter(self._draft.get("nodes", {})), None)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()

    def _write_text(self, widget: Any, value: str) -> None:
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", value)

    def _read_text(self, widget: Any) -> str:
        return widget.get("1.0", "end").strip()

    def _read_codeblock_document(self) -> dict[str, Any] | None:
        try:
            document = json.loads(self._read_text(self.codeblocks_text) or "{}")
        except json.JSONDecodeError as error:
            self.set_status(f"Codeblocks JSON is invalid: {error.msg}")
            return None
        if not isinstance(document, dict):
            self.set_status("Codeblocks document must be a JSON object")
            return None
        return document

    def sync_codeblocks(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before syncing codeblocks")
            return
        self._write_text(
            self.codeblocks_text,
            _json_text(flow_to_codeblocks(self._draft, nested_flows=self._nested_flows)),
        )
        self.set_status("Codeblocks synchronized from the visual graph")

    def validate_codeblocks(self) -> dict[str, Any] | None:
        document = self._read_codeblock_document()
        if document is None:
            return None
        report = validate_codeblock_document(
            document,
            known_flow_ids=self._catalog,
        )
        if report["valid"]:
            self.set_status("Codeblocks valid; no flow or worker state changed")
        else:
            message = report["diagnostics"][0]["message"] if report["diagnostics"] else "invalid codeblocks"
            self.set_status(f"Codeblocks rejected: {message}")
        return report

    def apply_codeblocks(self) -> dict[str, Any] | None:
        if not self._draft:
            self.set_status("Select a flow before applying codeblocks")
            return None
        document = self._read_codeblock_document()
        if document is None:
            return None
        before = flow_draft(self._draft)
        result = codeblocks_to_flow(
            document,
            base_flow=self._draft,
            known_flow_ids=self._catalog,
        )
        if result["valid"] is not True or not isinstance(result.get("flow"), dict):
            message = result["diagnostics"][0]["message"] if result["diagnostics"] else "invalid codeblocks"
            self.set_status(f"Codeblocks rejected: {message}")
            return result
        self._draft = flow_draft(result["flow"])
        self._nested_flows = copy.deepcopy(result.get("nestedFlows", []))
        if self._nested_flows:
            self._draft.setdefault("_semanticLab", {})["nestedFlows"] = copy.deepcopy(self._nested_flows)
        elif isinstance(self._draft.get("_semanticLab"), dict):
            self._draft["_semanticLab"].pop("nestedFlows", None)
            if not self._draft["_semanticLab"]:
                self._draft.pop("_semanticLab", None)
        self._selected_node = self._draft.get("initial")
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(
            "Codeblocks applied to the visual graph; validate through the production Registry before registering"
        )
        return result

    def _populate_flow_fields(self) -> None:
        if not self._draft:
            return
        self.flow_id_var.set(str(self._draft.get("id", "")))
        self.owner_var.set(str(self._draft.get("owner", "")))
        self.initial_var.set(str(self._draft.get("initial", "")))
        self._write_text(self.triggers_text, _json_text(self._draft.get("triggers", [])))
        if hasattr(self, "codeblocks_text"):
            self._write_text(
                self.codeblocks_text,
                _json_text(flow_to_codeblocks(self._draft, nested_flows=self._nested_flows)),
            )

    def _populate_node_fields(self) -> None:
        nodes = self._draft.get("nodes", {}) if self._draft else {}
        node = nodes.get(self._selected_node, {}) if isinstance(nodes, dict) else {}
        node_ids = sorted(nodes) if isinstance(nodes, dict) else []
        self.node_box.configure(values=node_ids)
        self.node_var.set(self._selected_node or "")
        self.terminal_var.set(node.get("terminal") is True)
        self.response_pool_var.set(str(node.get("responsePool") or ""))
        self.response_template_var.set(str(node.get("responseTemplate") or ""))
        for field, variable in self.transition_vars.items():
            variable.set(str(node.get(field) or ""))
        self._write_text(self.accepts_text, _json_text(node.get("accepts", [])))
        self._write_text(
            self.branch_offers_text,
            _json_text(node.get("branchOffers", [])),
        )
        gate = node.get("gate") if isinstance(node.get("gate"), dict) else {}
        self.gate_type_var.set(str(gate.get("type") or "none"))
        self.gate_fact_var.set(str(gate.get("fact") or gate.get("subject") or ""))
        self.gate_field_var.set(str(gate.get("field") or ""))
        self.gate_operator_var.set(str(gate.get("operator") or "=="))
        self.gate_value_var.set(str(gate.get("value") if gate.get("value") is not None else ""))
        self.gate_start_var.set(str(gate.get("startHour") if gate.get("startHour") is not None else ""))
        self.gate_end_var.set(str(gate.get("endHour") if gate.get("endHour") is not None else ""))
        self.gate_unknown_policy_var.set(str(gate.get("unknownPolicy") or "tri_state"))

    def _record_history(self, before: dict[str, Any] | None = None) -> None:
        self._history.record(before if before is not None else self._draft or {})

    def _restore_history(self, index: int) -> None:
        snapshot = self._history.snapshot(index)
        if snapshot is None:
            return
        self._draft = flow_draft(snapshot)
        nodes = self._draft.get("nodes", {})
        if self._selected_node not in nodes:
            self._selected_node = self._draft.get("initial")
        if self._selected_node not in nodes:
            self._selected_node = next(iter(nodes), None)
        self._history.move_to(index)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()

    def undo(self) -> None:
        if self._history.index <= 0:
            self.set_status("Nothing to undo")
            return
        self._restore_history(self._history.index - 1)
        self.set_status("Undo")

    def redo(self) -> None:
        if self._history.index + 1 >= len(self._history):
            self.set_status("Nothing to redo")
            return
        self._restore_history(self._history.index + 1)
        self.set_status("Redo")

    def _select_node(self, node_id: str | None = None) -> None:
        selected = node_id or self.node_var.get()
        nodes = self._draft.get("nodes", {}) if self._draft else {}
        if selected not in nodes:
            return
        self._selected_node = selected
        self._populate_node_fields()
        self._draw_graph()

    def _prompt(self, title: str, prompt: str, initial: str = "") -> str | None:
        return self._actions_controller._prompt(title, prompt, initial)

    def _choose_catalog_item(
        self,
        title: str,
        items: list[dict[str, Any]],
        display: Callable[[dict[str, Any]], str],
    ) -> dict[str, Any] | None:
        return self._actions_controller._choose_catalog_item(title, items, display)

    def _commit_history_change(self, before: dict[str, Any]) -> None:
        self._actions_controller._commit_history_change(before)

    def add_node(self) -> None:
        self._actions_controller.add_node()

    def duplicate_node(self) -> None:
        self._actions_controller.duplicate_node()

    def rename_node(self) -> None:
        self._actions_controller.rename_node()

    def delete_node(self) -> None:
        self._actions_controller.delete_node()

    def connect_node(self) -> None:
        self._actions_controller.connect_node()

    def add_trigger(self) -> None:
        self._actions_controller.add_trigger()

    def add_command_trigger(self) -> None:
        self._actions_controller.add_command_trigger()

    def _parse_array(self, widget: Any, label: str) -> list[Any]:
        return self._actions_controller._parse_array(widget, label)

    def _commit_fields(self) -> dict[str, Any] | None:
        return self._actions_controller._commit_fields()

    def apply_node_fields(self) -> None:
        self._actions_controller.apply_node_fields()

    def validate_draft(self) -> None:
        self._actions_controller.validate_draft()

    def register_draft(self) -> None:
        self._actions_controller.register_draft()

    def show_source_report(self, report: dict[str, Any]) -> None:
        self._actions_controller.show_source_report(report)

    def show_dataset_report(self, report: dict[str, Any]) -> None:
        self._actions_controller.show_dataset_report(report)

    def show_validation(self, response: dict[str, Any]) -> None:
        self._actions_controller.show_validation(response)

    def show_registration(self, response: dict[str, Any]) -> None:
        self._actions_controller.show_registration(response)

    def save_draft(self) -> None:
        self._actions_controller.save_draft()

    def load_draft(self) -> None:
        self._actions_controller.load_draft()
    def _canvas_point(self, event: Any) -> tuple[float, float]:
        return self._canvas_controller._canvas_point(event)

    def _on_mouse_wheel(self, event: Any) -> None:
        self._canvas_controller._on_mouse_wheel(event)

    def _zoom_at(self, event: Any, factor: float) -> None:
        self._canvas_controller._zoom_at(event, factor)

    def _start_pan(self, event: Any) -> None:
        self._canvas_controller._start_pan(event)

    def _drag_pan(self, event: Any) -> None:
        self._canvas_controller._drag_pan(event)

    def _stop_pan(self, event: Any) -> None:
        self._canvas_controller._stop_pan(event)

    def _node_id_at(self, event: Any) -> str | None:
        return self._canvas_controller._node_id_at(event)

    def _on_canvas_left_down(self, event: Any) -> None:
        self._canvas_controller._on_canvas_left_down(event)

    def _start_node_drag(self, event: Any, node_id: str) -> None:
        self._canvas_controller._start_node_drag(event, node_id)

    def _drag_node_motion(self, event: Any) -> None:
        self._canvas_controller._drag_node_motion(event)

    def _stop_node_drag(self, event: Any) -> None:
        self._canvas_controller._stop_node_drag(event)

    def reset_zoom(self) -> None:
        self._canvas_controller.reset_zoom()

    def fit_graph(self) -> None:
        self._canvas_controller.fit_graph()

    def _draw_graph(self) -> None:
        self._canvas_controller._draw_graph()
