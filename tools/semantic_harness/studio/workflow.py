"""In-app Semantic Lab workflow over the shared authoring service."""

from __future__ import annotations

import json
import re
from typing import Any, Callable

from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.interaction_spec import graph_block, graph_connection


class SemanticLabWorkflowPane:
    """Select a canonical source, compose blocks, and approve one build."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: SemanticLabAuthoringService,
        *,
        on_generate: Callable[[str, list[str], dict[str, Any] | None], Any],
        on_inspect: Callable[[], Any],
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._messagebox = messagebox
        self.service = service
        self._on_generate = on_generate
        self._on_inspect = on_inspect
        self._production_catalog: dict[str, Any] | None = None
        self._sources: list[dict[str, Any]] = []
        self._blocks: list[dict[str, Any]] = []
        self._graph_blocks: list[dict[str, Any]] = []
        self._graph_connections: list[dict[str, Any]] = []
        self._last_preview: dict[str, Any] | None = None
        self._preview_key: str | None = None
        self._approved_key: str | None = None
        self._last_spec: dict[str, Any] | None = None

        self.frame = ttk.Frame(parent, padding=8)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=2)

        self._source_var = tk.StringVar()
        self._query_var = tk.StringVar()
        self._spec_id_var = tk.StringVar(value="pnc.lab.former_job")
        self._mode_var = tk.StringVar(value="registered capability")
        self._utterance_var = tk.StringVar(value="what was your old job")
        self._negative_var = tk.StringVar(value="do not ask about my old job")
        self._kind_var = tk.StringVar(value="former_job")
        self._pool_var = tk.StringVar(value="semantic.lab.former_job")
        self._english_var = tk.StringVar(value="I worked as %1 before all this.")
        self._tagalog_var = tk.StringVar(value="Nagtrabaho ako bilang %1 bago ang lahat ng ito.")
        self._status_var = tk.StringVar(value="Select a canonical dataset to begin.")

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Dataset").grid(row=0, column=0, padx=(0, 6))
        self._source_box = ttk.Combobox(
            toolbar,
            textvariable=self._source_var,
            state="readonly",
            width=28,
        )
        self._source_box.grid(row=0, column=1, sticky="ew")
        self._source_box.bind("<<ComboboxSelected>>", lambda _event: self._selection_changed())
        self._refresh_button = ttk.Button(toolbar, text="Refresh sources", command=self.refresh)
        self._refresh_button.grid(row=0, column=2, padx=(6, 0))
        ttk.Label(toolbar, text="Graph kind").grid(row=0, column=3, padx=(14, 6))
        self._mode_box = ttk.Combobox(
            toolbar,
            textvariable=self._mode_var,
            state="readonly",
            values=("registered capability", "NPC backstory"),
            width=20,
        )
        self._mode_box.grid(row=0, column=4)
        self._mode_box.bind("<<ComboboxSelected>>", lambda _event: self._mode_changed())
        ttk.Label(toolbar, text="Block search").grid(row=0, column=5, padx=(14, 6))
        self._query_entry = ttk.Entry(toolbar, textvariable=self._query_var, width=24)
        self._query_entry.grid(row=0, column=6)
        self._search_button = ttk.Button(toolbar, text="Search", command=self.search_blocks)
        self._search_button.grid(row=0, column=7, padx=(6, 0))
        self._status = ttk.Label(self.frame, textvariable=self._status_var)
        self._status.grid(row=1, column=0, columnspan=2, sticky="w", pady=(0, 6))

        left = ttk.LabelFrame(self.frame, text="Compose reusable blocks")
        left.grid(row=2, column=0, sticky="nsew", padx=(0, 8))
        left.rowconfigure(0, weight=1)
        left.rowconfigure(2, weight=1)
        left.columnconfigure(0, weight=1)
        self._block_list = tk.Listbox(
            left,
            width=48,
            exportselection=False,
            selectmode="extended",
        )
        self._block_list.grid(row=0, column=0, sticky="nsew")
        block_scroll = ttk.Scrollbar(left, orient="vertical", command=self._block_list.yview)
        block_scroll.grid(row=0, column=1, sticky="ns")
        self._block_list.configure(yscrollcommand=block_scroll.set)

        palette_actions = ttk.Frame(left)
        palette_actions.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(4, 0))
        self._add_node_button = ttk.Button(
            palette_actions, text="Add selected block", command=self.add_node
        )
        self._add_node_button.pack(side="left")
        self._starter_backstory_button = ttk.Button(
            palette_actions, text="New backstory graph", command=self.new_backstory_graph
        )
        self._starter_backstory_button.pack(side="left", padx=4)
        self._starter_capability_button = ttk.Button(
            palette_actions, text="New capability graph", command=self.new_capability_graph
        )
        self._starter_capability_button.pack(side="left")

        graph_frame = ttk.LabelFrame(left, text="Typed graph · select a node or edge to edit")
        graph_frame.grid(row=2, column=0, columnspan=2, sticky="nsew", pady=(6, 0))
        graph_frame.rowconfigure(0, weight=1)
        graph_frame.columnconfigure(0, weight=1)
        graph_frame.columnconfigure(1, weight=1)
        self._node_list = tk.Listbox(graph_frame, height=8, exportselection=False)
        self._node_list.grid(row=0, column=0, sticky="nsew", padx=(4, 2), pady=4)
        self._node_list.bind("<<ListboxSelect>>", lambda _event: self._node_selected())
        self._edge_list = tk.Listbox(graph_frame, height=8, exportselection=False)
        self._edge_list.grid(row=0, column=1, sticky="nsew", padx=(2, 4), pady=4)
        self._edge_list.bind("<<ListboxSelect>>", lambda _event: self._edge_selected())
        graph_actions = ttk.Frame(graph_frame)
        graph_actions.grid(row=1, column=0, columnspan=2, sticky="ew", padx=4, pady=(0, 4))
        self._remove_node_button = ttk.Button(graph_actions, text="Remove node", command=self.remove_node)
        self._remove_node_button.pack(side="left")
        self._connect_button = ttk.Button(graph_actions, text="Connect selected nodes", command=self.connect_nodes)
        self._connect_button.pack(side="left", padx=4)
        self._disconnect_button = ttk.Button(graph_actions, text="Disconnect selected edge", command=self.disconnect_edge)
        self._disconnect_button.pack(side="left")

        parameters = ttk.LabelFrame(left, text="Grounded interaction parameters")
        parameters.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(6, 0))
        parameters.columnconfigure(1, weight=1)
        self._add_entry(parameters, 0, "Spec ID", self._spec_id_var)
        self._add_entry(parameters, 1, "Utterance", self._utterance_var)
        self._add_entry(parameters, 2, "Negative utterance", self._negative_var)
        ttk.Label(parameters, text="Backstory kind").grid(row=3, column=0, sticky="w", padx=6, pady=2)
        self._kind_box = ttk.Combobox(
            parameters,
            textvariable=self._kind_var,
            state="readonly",
            values=("former_job", "hometown", "education", "hobby", "family_background", "value", "survival_origin", "fear", "tragedy", "date_of_birth"),
        )
        self._kind_box.grid(row=3, column=1, sticky="ew", padx=(0, 6), pady=2)
        self._add_entry(parameters, 4, "Response pool", self._pool_var)
        self._add_entry(parameters, 5, "EN response", self._english_var)
        self._add_entry(parameters, 6, "TL response", self._tagalog_var)
        self._node_params_var = tk.StringVar(value="{}")
        self._add_entry(parameters, 7, "Selected node JSON", self._node_params_var)
        self._apply_node_button = ttk.Button(
            parameters, text="Apply node JSON", command=self.apply_node_parameters
        )
        self._apply_node_button.grid(row=8, column=1, sticky="e", padx=(0, 6), pady=2)

        right = ttk.LabelFrame(self.frame, text="Workflow contract and generated-source preview")
        right.grid(row=2, column=1, sticky="nsew")
        right.rowconfigure(0, weight=1)
        right.columnconfigure(0, weight=1)
        self._report = scrolled_text(right, wrap="none", state="disabled")
        self._report.grid(row=0, column=0, sticky="nsew")

        actions = ttk.Frame(self.frame)
        actions.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(6, 0))
        self._validate_button = ttk.Button(
            actions, text="Validate composition", command=self.validate_composition,
        )
        self._validate_button.pack(side="left")
        self._preview_button = ttk.Button(
            actions, text="Preview generated source", command=self.preview_source,
        )
        self._preview_button.pack(side="left", padx=6)
        self._approve_button = ttk.Button(
            actions, text="Approve generation", command=self.approve_generation,
        )
        self._approve_button.pack(side="left")
        self._generate_button = ttk.Button(
            actions, text="Generate + restart worker", command=self.generate,
        )
        self._generate_button.pack(side="left", padx=6)
        self._inspect_button = ttk.Button(
            actions, text="Inspect live dialogue", command=self._on_inspect,
        )
        self._inspect_button.pack(side="right")
        self._buttons = (
            self._refresh_button,
            self._search_button,
            self._mode_box,
            self._add_node_button,
            self._starter_backstory_button,
            self._starter_capability_button,
            self._remove_node_button,
            self._connect_button,
            self._disconnect_button,
            self._apply_node_button,
            self._validate_button,
            self._preview_button,
            self._approve_button,
            self._generate_button,
            self._inspect_button,
        )
        self._enabled = True
        self.refresh()

    def _add_entry(self, parent: Any, row: int, label: str, variable: Any) -> None:
        """Add one editable parameter row to the workflow composer."""

        self._ttk.Label(parent, text=label).grid(
            row=row, column=0, sticky="w", padx=6, pady=2
        )
        self._ttk.Entry(parent, textvariable=variable).grid(
            row=row, column=1, sticky="ew", padx=(0, 6), pady=2
        )

    def _set_report(self, value: Any) -> None:
        self._report.configure(state="normal")
        self._report.delete("1.0", "end")
        self._report.insert("1.0", json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
        self._report.configure(state="disabled")

    def _selection_key(self) -> str:
        return json.dumps(
            {
                "datasetID": self._source_var.get().strip(),
                "blockIDs": self._selected_block_ids(),
                "spec": self._compose_spec(raise_errors=False),
            },
            sort_keys=True,
        )

    def _selected_block_ids(self) -> list[str]:
        if self._graph_blocks:
            return [str(block.get("type")) for block in self._graph_blocks]
        return [self._blocks[index]["id"] for index in self._block_list.curselection()]

    def _selected_palette_block(self) -> dict[str, Any] | None:
        selection = self._block_list.curselection()
        return self._blocks[selection[0]] if selection else None

    @staticmethod
    def _unique_id(existing: list[dict[str, Any]], stem: str) -> str:
        used = {str(block.get("id")) for block in existing}
        if stem not in used:
            return stem
        index = 2
        while f"{stem}{index}" in used:
            index += 1
        return f"{stem}{index}"

    def _default_node_parameters(
        self, block_type: str, definition: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        definition = definition if isinstance(definition, dict) else {}
        if block_type == "language.trigger":
            frame = definition.get("frame") if isinstance(definition.get("frame"), dict) else {}
            return {
                "utterance": self._utterance_var.get().strip(),
                "negativeUtterance": self._negative_var.get().strip(),
                "frame": {"intent": "REQUEST", "speechAct": "REQUEST", "action": str(frame.get("action") or "STAY")},
            }
        if block_type == "language.backstory_subject":
            kind = self._kind_var.get().strip() or "former_job"
            return {
                "backstoryKind": kind,
                "factProvider": "npc_backstory",
                "topicID": f"backstory.{kind}",
                "disclosure": "server_authorized",
            }
        if block_type == "memory.backstory_fact":
            return {"providerID": "npc_backstory", "subject": "NPC_BACKSTORY", "authority": "server", "immutable": True, "privacy": "private"}
        if block_type == "gameplay_actions.capability":
            frame = definition.get("frame") if isinstance(definition.get("frame"), dict) else {}
            return {
                "capabilityID": str(definition.get("bindingID") or definition.get("capabilityID") or definition.get("id") or ""),
                "action": str(frame.get("action") or definition.get("id") or "STAY"),
            }
        if block_type == "world_facts.engine_fact":
            return {"factID": str(definition.get("id") or "world.time.week")}
        if block_type == "conditions.gate":
            return {"type": "pnc:fact", "factBlockID": "engine_fact", "operator": ">=", "value": 1}
        if block_type == "dialogue_responses.response_pool":
            return {
                "poolID": self._pool_var.get().strip(),
                "variants": [{
                    "id": "answer",
                    "key": "UI_PNC_Conversation_SemanticLabResponse",
                    "translations": {
                        "EN": self._english_var.get().strip(),
                        "TL": self._tagalog_var.get().strip(),
                    },
                    "translationArgs": {"content": "fact_content"},
                }],
            }
        return {}

    @staticmethod
    def _node_type_for_palette(palette: dict[str, Any]) -> tuple[str, dict[str, Any]]:
        block_id = str(palette.get("id", ""))
        if block_id.startswith(("action:", "quest:")):
            return "gameplay_actions.capability", palette.get("definition", {})
        if block_id.startswith("fact:"):
            return "world_facts.engine_fact", palette.get("definition", {})
        if block_id.startswith("event:"):
            return "world_facts.engine_event", palette.get("definition", {})
        return block_id, {}

    def add_node(self) -> None:
        palette = self._selected_palette_block()
        if not palette:
            self._status_var.set("Select a registered block from the palette first")
            return
        block_type, definition = self._node_type_for_palette(palette)
        stem = {
            "language.trigger": "trigger",
            "language.backstory_subject": "backstory",
            "memory.backstory_fact": "fact",
            "dialogue_responses.response_pool": "response",
            "gameplay_actions.capability": "capability",
            "world_facts.engine_fact": "engine_fact",
            "conditions.gate": "gate",
        }.get(block_type, re.sub(r"[^a-z0-9]+", "_", block_type).strip("_") or "block")
        node = graph_block(
            self._unique_id(self._graph_blocks, stem),
            block_type,
            self._default_node_parameters(block_type, definition),
        )
        self._graph_blocks.append(node)
        self._refresh_graph_lists()
        self._status_var.set(f"Added {node['id']} · connect typed ports before validation")

    def remove_node(self) -> None:
        selection = self._node_list.curselection()
        if not selection:
            self._status_var.set("Select a graph node to remove")
            return
        node_id = self._graph_blocks[selection[0]]["id"]
        self._graph_blocks = [block for block in self._graph_blocks if block.get("id") != node_id]
        self._graph_connections = [edge for edge in self._graph_connections if edge.get("from") != node_id and edge.get("to") != node_id]
        self._refresh_graph_lists()
        self._invalidate_composition("Node removed; validate the updated graph")

    def connect_nodes(self) -> None:
        selection = self._node_list.curselection()
        if len(selection) != 2:
            self._status_var.set("Select exactly two nodes in source-to-target order")
            return
        source = self._graph_blocks[selection[0]]
        target = self._graph_blocks[selection[1]]
        contracts = {
            ("language.trigger", "language.backstory_subject"): "semantic",
            ("language.trigger", "gameplay_actions.capability"): "semantic",
            ("language.backstory_subject", "memory.backstory_fact"): "fact",
            ("memory.backstory_fact", "dialogue_responses.response_pool"): "response",
            ("gameplay_actions.capability", "dialogue_responses.response_pool"): "response",
            ("world_facts.engine_fact", "conditions.gate"): "fact",
            ("conditions.gate", "gameplay_actions.capability"): "gate",
            ("language.backstory_subject", "context.conversation_state"): "context",
            ("language.backstory_subject", "memory.knowledge"): "knowledge",
        }
        edge_type = contracts.get((source["type"], target["type"]))
        if not edge_type:
            self._status_var.set(f"No registered typed port from {source['type']} to {target['type']}")
            return
        edge = graph_connection(source["id"], target["id"], edge_type)
        if any(existing.get("from") == edge["from"] and existing.get("to") == edge["to"] for existing in self._graph_connections):
            self._status_var.set("That typed edge is already connected")
            return
        self._graph_connections.append(edge)
        self._refresh_graph_lists()
        self._invalidate_composition("Connection changed; validate the updated graph")

    def disconnect_edge(self) -> None:
        selection = self._edge_list.curselection()
        if not selection:
            self._status_var.set("Select an edge to disconnect")
            return
        del self._graph_connections[selection[0]]
        self._refresh_graph_lists()
        self._invalidate_composition("Connection removed; validate the updated graph")

    def _refresh_graph_lists(self) -> None:
        self._node_list.delete(0, "end")
        for block in self._graph_blocks:
            self._node_list.insert("end", f"{block['id']} · {block['type']}")
        self._edge_list.delete(0, "end")
        for edge in self._graph_connections:
            self._edge_list.insert("end", f"{edge.get('from')} --{edge.get('type')}--> {edge.get('to')}")

    def _node_selected(self) -> None:
        selection = self._node_list.curselection()
        if selection:
            self._node_params_var.set(json.dumps(self._graph_blocks[selection[0]].get("parameters", {}), ensure_ascii=False, sort_keys=True))

    def _edge_selected(self) -> None:
        selection = self._edge_list.curselection()
        if selection:
            self._status_var.set(f"Selected edge {self._edge_list.get(selection[0])}")

    def apply_node_parameters(self) -> None:
        selection = self._node_list.curselection()
        if not selection:
            self._status_var.set("Select a graph node before editing its parameters")
            return
        try:
            parameters = json.loads(self._node_params_var.get())
        except json.JSONDecodeError as error:
            self._status_var.set(f"Node JSON is invalid: {error}")
            return
        if not isinstance(parameters, dict):
            self._status_var.set("Node JSON must be an object")
            return
        self._graph_blocks[selection[0]]["parameters"] = parameters
        self._refresh_graph_lists()
        self._node_list.selection_set(selection[0])
        self._invalidate_composition("Node parameters changed; validate the updated graph")

    def _invalidate_composition(self, message: str) -> None:
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None
        self._last_spec = None
        self._status_var.set(message)

    def _mode_changed(self) -> None:
        self._invalidate_composition("Graph kind changed; start a new typed graph")

    def _new_graph(self, kind: str) -> None:
        self._graph_blocks = []
        self._graph_connections = []
        self._mode_var.set(kind)
        wanted_source = (
            "grounded_personal"
            if kind == "NPC backstory"
            else "semantic_flows"
        )
        source_ids = [str(source.get("id")) for source in self._sources]
        if wanted_source in source_ids:
            self._source_var.set(wanted_source)
        self._refresh_graph_lists()
        self._invalidate_composition(f"Empty {kind} graph ready; add and connect registered blocks")

    def new_backstory_graph(self) -> None:
        self._new_graph("NPC backstory")

    def new_capability_graph(self) -> None:
        self._new_graph("registered capability")

    def _compose_spec(self, *, raise_errors: bool = True) -> dict[str, Any] | None:
        """Materialize the editable graph into the canonical typed spec."""

        source_id = self._source_var.get().strip()
        if not self._graph_blocks:
            if raise_errors:
                raise ValueError("add at least one registered block to the graph")
            return None
        if self._mode_var.get() == "NPC backstory" and source_id != "grounded_personal":
            if raise_errors:
                raise ValueError("NPC backstory graphs require the grounded personal dialogue source")
            return None
        if self._mode_var.get() == "registered capability" and source_id == "grounded_personal":
            if raise_errors:
                raise ValueError("registered capability graphs require the semantic flows source")
            return None
        spec_id = self._spec_id_var.get().strip()
        if not spec_id:
            if raise_errors:
                raise ValueError("Spec ID is required")
            return None
        return {
            "schema": "semantic.interaction_spec.v1",
            "id": spec_id,
            "owner": "SemanticLab",
            "blocks": [
                {
                    "id": str(block["id"]),
                    "type": str(block["type"]),
                    "parameters": json.loads(json.dumps(block.get("parameters", {}), ensure_ascii=False)),
                }
                for block in self._graph_blocks
            ],
            "connections": [dict(connection) for connection in self._graph_connections],
        }

    def _selection_changed(self) -> None:
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None
        self._last_spec = None
        self._status_var.set(f"Selected {self._source_var.get().strip()}; compose blocks and validate.")

    def refresh(self) -> None:
        self._sources = self.service.list_workflow_datasets()
        source_ids = [str(source["id"]) for source in self._sources]
        self._source_box.configure(values=source_ids)
        if self._source_var.get() not in source_ids:
            self._source_var.set(source_ids[0] if source_ids else "")
        self.search_blocks()
        self._status_var.set(
            f"{len(self._sources)} generation-ready datasets; select blocks for composition."
        )

    def set_production_catalog(self, catalog: dict[str, Any] | None) -> None:
        self._production_catalog = catalog if isinstance(catalog, dict) else None
        self.search_blocks()

    def search_blocks(self) -> None:
        self._blocks = self.service.search_semantic_blocks(
            self._query_var.get().strip(),
            production_catalog=self._production_catalog,
            limit=128,
        )
        self._block_list.delete(0, "end")
        for block in self._blocks:
            self._block_list.insert(
                "end",
                f"{block.get('category', '?')} · {block.get('label', block.get('id', '?'))}",
            )
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None

    def validate_composition(self) -> dict[str, Any] | None:
        source_id = self._source_var.get().strip()
        if not source_id:
            self._status_var.set("Select a generation-ready dataset first")
            return None
        report = self.service.validate_workflow_selection(
            source_id,
            self._selected_block_ids(),
            production_catalog=self._production_catalog,
        )
        try:
            spec = self._compose_spec()
            composition = self.service.validate_interaction_spec(
                spec,
                production_catalog=self._production_catalog,
            )
            report["composition"] = composition
            report["ok"] = report.get("ok") is True and composition.get("ok") is True
            report.setdefault("diagnostics", []).extend(composition.get("diagnostics", []))
            self._last_spec = spec
        except ValueError as error:
            report["ok"] = False
            report.setdefault("diagnostics", []).append({"severity": "error", "message": str(error)})
            self._last_spec = None
        self._set_report(report)
        self._last_preview = None
        self._preview_key = None
        self._approved_key = None
        if report.get("ok") is True:
            self._status_var.set("Composition valid; preview the generated source before approval.")
        else:
            self._status_var.set("Composition rejected; resolve the reported dataset/block errors.")
        return report

    def preview_source(self) -> dict[str, Any] | None:
        source_id = self._source_var.get().strip()
        if not source_id:
            self._status_var.set("Select a generation-ready dataset first")
            return None
        try:
            spec = self._compose_spec()
        except ValueError as error:
            report = {
                "ok": False,
                "type": "semantic_lab_workflow_preview",
                "workflow": {"datasetID": source_id, "blockIDs": self._selected_block_ids()},
                "diagnostics": [{"severity": "error", "message": str(error)}],
                "previewOnly": True,
                "effectFree": True,
                "writes": [],
            }
            spec = None
        else:
            report = self.service.preview_workflow(
                source_id,
                self._selected_block_ids(),
                production_catalog=self._production_catalog,
                interaction_spec=spec,
            )
        self._last_spec = spec
        self._set_report(report)
        self._last_preview = report
        self._preview_key = self._selection_key()
        self._approved_key = None
        if report.get("ok") is True:
            self._status_var.set("Generated Lua/EN-TL/manifest preview is ready for approval; no files written.")
        else:
            self._status_var.set("Generated-source preview rejected; no files written.")
        return report

    def approve_generation(self) -> bool:
        if not self._last_preview or self._last_preview.get("ok") is not True:
            self._status_var.set("Preview a valid workflow before approval")
            return False
        if self._selection_key() != self._preview_key:
            self._status_var.set("Selection changed; preview again before approval")
            return False
        generated_paths = self._last_preview.get("sourcePreview", {}).get("generatedPaths", [])
        if not self._messagebox.askyesno(
            "Approve Semantic Lab generation",
            "Approve the validated workflow to write its generated Lua, EN/TL, and manifests?\n\n"
            + "\n".join(str(path) for path in generated_paths[:8]),
        ):
            self._status_var.set("Generation approval cancelled; preview remains unchanged")
            return False
        self._approved_key = self._selection_key()
        self._status_var.set("Workflow approved; generate to write artifacts and restart the worker.")
        return True

    def generate(self) -> None:
        if self._approved_key != self._selection_key():
            self._status_var.set("Approve the current generated-source preview first")
            return
        self._on_generate(
            self._source_var.get().strip(),
            self._selected_block_ids(),
            self._last_spec,
        )

    def show_generation(self, report: dict[str, Any]) -> None:
        self._set_report(report)
        self._last_preview = report
        self._preview_key = None
        self._approved_key = None
        if report.get("ok") is True:
            self._status_var.set("Artifacts generated; worker restart requested. Inspect live dialogue when ready.")
        else:
            self._status_var.set("Generation failed; no worker restart was requested.")

    def set_enabled(self, enabled: bool) -> None:
        self._enabled = enabled
        state = "normal" if enabled else "disabled"
        readonly = "readonly" if enabled else "disabled"
        self._source_box.configure(state=readonly)
        self._mode_box.configure(state=readonly)
        self._query_entry.configure(state=state)
        self._block_list.configure(state=state)
        self._node_list.configure(state=state)
        self._edge_list.configure(state=state)
        for button in self._buttons:
            button.configure(state=state)
