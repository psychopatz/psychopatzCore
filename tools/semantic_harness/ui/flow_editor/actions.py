"""Mutation and authoring actions for the Semantic Lab Flow Editor."""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any, Callable

from tools.semantic_harness.codebuilder.blocks import TRANSITION_FIELDS
from .model import flow_draft, _json_text


class FlowEditorActions:
    """Own graph mutations and explicit authoring/report actions for one pane."""

    def __init__(self, pane: Any) -> None:
        object.__setattr__(self, "pane", pane)

    def __getattr__(self, name: str) -> Any:
        return getattr(self.pane, name)

    def __setattr__(self, name: str, value: Any) -> None:
        if name == "pane":
            object.__setattr__(self, name, value)
            return
        setattr(self.pane, name, value)

    def _prompt(self, title: str, prompt: str, initial: str = "") -> str | None:
        from tkinter import simpledialog

        return simpledialog.askstring(title, prompt, initialvalue=initial, parent=self.frame)

    def _choose_catalog_item(
        self,
        title: str,
        items: list[dict[str, Any]],
        display: Callable[[dict[str, Any]], str],
    ) -> dict[str, Any] | None:
        """Show a small searchable-by-selection catalog picker."""

        if not items:
            return None
        window = self._tk.Toplevel(self.frame)
        window.title(title)
        window.transient(self.frame.winfo_toplevel())
        window.geometry("620x360")
        window.columnconfigure(0, weight=1)
        window.rowconfigure(0, weight=1)
        listbox = self._tk.Listbox(window, activestyle="dotbox", selectmode="browse")
        listbox.grid(row=0, column=0, sticky="nsew", padx=(8, 0), pady=8)
        scrollbar = self._ttk.Scrollbar(window, orient="vertical", command=listbox.yview)
        scrollbar.grid(row=0, column=1, sticky="ns", padx=(0, 8), pady=8)
        listbox.configure(yscrollcommand=scrollbar.set)
        for item in items:
            listbox.insert("end", display(item))
        listbox.selection_set(0)
        listbox.activate(0)
        selected: dict[str, Any] = {"item": None}

        def accept(_event: Any = None) -> None:
            selection = listbox.curselection()
            if selection:
                selected["item"] = items[selection[0]]
            window.destroy()

        def cancel(_event: Any = None) -> None:
            window.destroy()

        buttons = self._ttk.Frame(window)
        buttons.grid(row=1, column=0, columnspan=2, sticky="e", padx=8, pady=(0, 8))
        self._ttk.Button(buttons, text="Add", command=accept).pack(side="left", padx=(0, 6))
        self._ttk.Button(buttons, text="Cancel", command=cancel).pack(side="left")
        listbox.bind("<Double-Button-1>", accept)
        window.bind("<Return>", accept)
        window.bind("<Escape>", cancel)
        window.protocol("WM_DELETE_WINDOW", cancel)
        window.grab_set()
        listbox.focus_set()
        self.frame.wait_window(window)
        return selected["item"]

    def _commit_history_change(self, before: dict[str, Any]) -> None:
        self._record_history(before)
        self._history.append(self._draft or {})

    def add_node(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before adding a node")
            return
        nodes = self._draft.setdefault("nodes", {})
        initial = "node_1"
        candidate = self._prompt("Add node", "Node ID", initial)
        node_id = (candidate or "").strip()
        if not node_id:
            return
        if node_id in nodes:
            self.set_status(f"Node already exists: {node_id}")
            return
        before = flow_draft(self._draft)
        nodes[node_id] = {
            "terminal": True,
            "accepts": [],
            "responsePool": None,
            "responseTemplate": None,
        }
        if self._selected_node in nodes and self._selected_node != node_id:
            source = nodes[self._selected_node]
            if source.get("terminal") is True:
                source["terminal"] = False
            if not source.get("onMatch") and not source.get("next"):
                source["onMatch"] = node_id
        self._selected_node = node_id
        self._commit_history_change(before)
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Added node {node_id}")

    def duplicate_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a node before duplicating")
            return
        nodes = self._draft["nodes"]
        source = nodes[self._selected_node]
        candidate = self._prompt("Duplicate node", "New node ID", f"{self._selected_node}_copy")
        node_id = (candidate or "").strip()
        if not node_id or node_id in nodes:
            return
        before = flow_draft(self._draft)
        nodes[node_id] = flow_draft(source)
        self._selected_node = node_id
        self._commit_history_change(before)
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Duplicated node as {node_id}")

    def rename_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a node before renaming")
            return
        old_id = self._selected_node
        candidate = self._prompt("Rename node", "New node ID", old_id)
        new_id = (candidate or "").strip()
        if not new_id or new_id == old_id or new_id in self._draft["nodes"]:
            return
        before = flow_draft(self._draft)
        nodes = self._draft["nodes"]
        nodes[new_id] = nodes.pop(old_id)
        nodes[new_id]["id"] = new_id
        for node in nodes.values():
            for field in TRANSITION_FIELDS:
                if node.get(field) == old_id:
                    node[field] = new_id
        if self._draft.get("initial") == old_id:
            self._draft["initial"] = new_id
        self._selected_node = new_id
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Renamed node to {new_id}")

    def delete_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a node before deleting")
            return
        if len(self._draft["nodes"]) <= 1:
            self.set_status("A flow must retain at least one node")
            return
        node_id = self._selected_node
        before = flow_draft(self._draft)
        self._draft["nodes"].pop(node_id, None)
        for node in self._draft["nodes"].values():
            for field in TRANSITION_FIELDS:
                if node.get(field) == node_id:
                    node.pop(field, None)
        if self._draft.get("initial") == node_id:
            self._draft["initial"] = sorted(self._draft["nodes"])[0]
        self._selected_node = self._draft.get("initial")
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Deleted node {node_id}")

    def connect_node(self) -> None:
        if not self._draft or self._selected_node not in self._draft.get("nodes", {}):
            self.set_status("Select a source node before connecting")
            return
        target = self._prompt("Connect node", "Target node or exit (cancel/resume/suspend)")
        field = self._prompt("Connect node", "Transition field", "onMatch")
        target = (target or "").strip()
        field = (field or "").strip()
        if not target or field not in TRANSITION_FIELDS:
            return
        if target not in self._draft["nodes"] and target not in ("cancel", "resume", "suspend"):
            self.set_status(f"Unknown target: {target}")
            return
        before = flow_draft(self._draft)
        self._draft["nodes"][self._selected_node][field] = target
        self._commit_history_change(before)
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Connected {self._selected_node}.{field} → {target}")

    def add_trigger(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before adding a trigger")
            return
        frame: dict[str, Any] | None = None
        selected_trigger: dict[str, Any] | None = None
        if self._trigger_catalog:
            custom = {
                "id": "<custom>",
                "label": "Custom JSON frame",
                "frame": None,
            }
            selected_trigger = self._choose_catalog_item(
                "Add semantic trigger",
                self._trigger_catalog + [custom],
                lambda item: (
                    f"{item['id']}  ·  {item.get('label', '')}"
                    if item.get("id") != "<custom>"
                    else item["label"]
                ),
            )
            if selected_trigger is None:
                return
            if selected_trigger.get("id") != "<custom>":
                candidate = selected_trigger.get("frame")
                frame = copy.deepcopy(candidate) if isinstance(candidate, dict) else None

        if frame is None:
            raw = self._prompt(
                "Add trigger frame",
                "Trigger JSON (include intent/speechAct/action/subject)",
                '{"intent":"GREET","speechAct":"GREET"}',
            )
            if not raw:
                return
            try:
                frame = json.loads(raw)
            except json.JSONDecodeError as error:
                self.set_status(f"Trigger JSON is invalid: {error.msg}")
                return
        if not isinstance(frame, dict) or not frame:
            self.set_status("Trigger must be a non-empty JSON object")
            return
        before = flow_draft(self._draft)
        self._draft.setdefault("triggers", []).append(frame)
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._draw_graph()
        self.set_status(
            f"Trigger {selected_trigger.get('id')} added; validate before registering"
            if selected_trigger and selected_trigger.get("id") != "<custom>"
            else "Trigger added; validate before registering"
        )

    def add_command_trigger(self) -> None:
        if not self._draft:
            self.set_status("Select a flow before adding an action trigger")
            return
        selected_action: dict[str, Any] | None = None
        if self._action_catalog:
            selected_action = self._choose_catalog_item(
                "Add semantic action trigger",
                self._action_catalog,
                lambda item: (
                    f"{item['id']}  ·  "
                    f"{', '.join(item.get('transports', [])) or 'policy only'}"
                    + (
                        f"  ·  {item['binding'].get('id')}"
                        f" → {item['binding'].get('commandID')}"
                        if isinstance(item.get('binding'), dict)
                        else "  ·  recognition only"
                    )
                ),
            )
            if selected_action is None:
                return
            action = str(selected_action.get("id", "")).upper()
        else:
            default = self._command_catalog[0] if self._command_catalog else "FOLLOW"
            action = self._prompt(
                "Add semantic action trigger",
                "Action (from the live semantic capability catalog)",
                default,
            )
            action = (action or "").strip().upper()
            if not action:
                return
        if self._command_catalog and action not in self._command_catalog:
            self.set_status(f"Unknown command action: {action}")
            return
        action_frame = (
            copy.deepcopy(selected_action.get("frame"))
            if selected_action and isinstance(selected_action.get("frame"), dict)
            else {
                "intent": "REQUEST",
                "speechAct": "REQUEST",
                "action": action,
            }
        )
        before = flow_draft(self._draft)
        self._draft.setdefault("triggers", []).append(action_frame)
        self._commit_history_change(before)
        self._populate_flow_fields()
        self._draw_graph()
        binding = selected_action.get("binding") if selected_action else None
        if isinstance(binding, dict):
            self.set_status(
                f"Trigger {action} added; binding {binding.get('id')} → "
                f"{binding.get('handlerID')} ({binding.get('commandID')}); "
                "trigger only—Preview never dispatches"
            )
        else:
            self.set_status(
                f"Trigger {action} added; recognition only—no executable binding"
            )

    def _parse_array(self, widget: Any, label: str) -> list[Any]:
        try:
            value = json.loads(self._read_text(widget) or "[]")
        except json.JSONDecodeError as error:
            raise ValueError(f"{label} is not valid JSON: {error.msg}") from error
        if not isinstance(value, list):
            raise ValueError(f"{label} must be a JSON array")
        return value

    def _commit_fields(self) -> dict[str, Any] | None:
        if not self._draft:
            self.set_status("Select a production flow or open a draft first")
            return None
        before = flow_draft(self._draft)
        draft = flow_draft(self._draft)
        flow_id = self.flow_id_var.get().strip()
        owner = self.owner_var.get().strip()
        initial = self.initial_var.get().strip()
        if not flow_id or not owner or not initial:
            self.set_status("Flow ID, owner, and initial node are required")
            return None
        try:
            triggers = self._parse_array(self.triggers_text, "Triggers")
            accepts = self._parse_array(self.accepts_text, "Accepted frames")
            branch_offers = self._parse_array(
                self.branch_offers_text, "Branch offers"
            )
        except ValueError as error:
            self.set_status(str(error))
            return None
        draft["id"] = flow_id
        draft["owner"] = owner
        draft["initial"] = initial
        draft["triggers"] = triggers
        nodes = draft.setdefault("nodes", {})
        if self._selected_node not in nodes:
            self.set_status("Select a valid node before applying fields")
            return None
        node = nodes[self._selected_node]
        node["terminal"] = self.terminal_var.get() is True
        node["responsePool"] = self.response_pool_var.get().strip() or None
        node["responseTemplate"] = self.response_template_var.get().strip() or None
        for field, variable in self.transition_vars.items():
            value = variable.get().strip()
            if value:
                node[field] = value
            else:
                node.pop(field, None)
        node["accepts"] = accepts
        node["branchOffers"] = branch_offers
        gate_type = self.gate_type_var.get().strip() or "none"
        if gate_type == "none":
            node.pop("gate", None)
        else:
            gate = copy.deepcopy(node.get("gate")) if isinstance(node.get("gate"), dict) else {}
            gate["type"] = gate_type
            fact = self.gate_fact_var.get().strip()
            field = self.gate_field_var.get().strip()
            operator = self.gate_operator_var.get().strip()
            value = self.gate_value_var.get().strip()
            start_hour = self.gate_start_var.get().strip()
            end_hour = self.gate_end_var.get().strip()
            unknown_policy = self.gate_unknown_policy_var.get().strip()
            if fact:
                gate["fact"] = fact
            elif gate_type == "pnc:fact":
                gate.pop("fact", None)
            if field:
                gate["field"] = field
            else:
                gate.pop("field", None)
            if operator:
                gate["operator"] = operator
            if value:
                gate["value"] = value
            else:
                gate.pop("value", None)
            for key, raw in (("startHour", start_hour), ("endHour", end_hour)):
                if raw:
                    try:
                        gate[key] = float(raw)
                    except ValueError:
                        self.set_status(f"{key} must be numeric")
                        return None
                else:
                    gate.pop(key, None)
            if unknown_policy in ("pass", "fail"):
                gate["unknownPolicy"] = unknown_policy
            else:
                gate.pop("unknownPolicy", None)
            node["gate"] = gate
        self._draft = draft
        if draft != before:
            self._commit_history_change(before)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        return draft

    def apply_node_fields(self) -> None:
        if self._commit_fields() is not None:
            self.set_status("Draft fields applied; validate before registering")

    def validate_draft(self) -> None:
        draft = self._commit_fields()
        if draft is not None:
            self._on_validate(flow_draft(draft))

    def register_draft(self) -> None:
        draft = self._commit_fields()
        if draft is None:
            return
        if draft.get("workflowKind") and draft.get("id") in self._catalog:
            self.set_status(
                "Generated flow is regeneration-owned; rename or duplicate "
                "the draft before authored registration"
            )
            return
        self._on_register(flow_draft(draft))

    def show_source_report(self, report: dict[str, Any]) -> None:
        if report.get("ok") is True:
            writes = report.get("writes") or []
            if writes:
                self.set_status(
                    "Generated and ready for worker restart "
                    f"({len(writes)} files written)"
                )
                return
            self.set_status(
                "Compiler preview valid; no files written "
                f"({len(report.get('generatedPaths', []))} planned paths)"
            )
        else:
            diagnostics = report.get("diagnostics") or []
            message = diagnostics[0].get("message") if diagnostics else "invalid source"
            self.set_status(f"Compiler preview rejected: {message}")

    def show_dataset_report(self, report: dict[str, Any]) -> None:
        review = report.get("candidateReview") or {}
        summary = review.get("summary") or {}
        collisions = review.get("collisions") or []
        artifact_diffs = report.get("artifactDiffs") or []
        writes = report.get("writes") or []
        changed = sum(
            1 for row in artifact_diffs
            if isinstance(row, dict) and row.get("status") != "unchanged"
        )
        if report.get("ok") is True:
            write_status = (
                f"{len(writes)} files written; worker restart required"
                if writes else "no files written"
            )
            self.set_status(
                "Dataset preview valid; "
                f"{summary.get('approved', 0)} approved, "
                f"{summary.get('rejected', 0)} rejected, "
                f"{len(collisions)} collisions, {changed} artifact diffs, {write_status}"
            )
            return
        diagnostics = report.get("diagnostics") or []
        message = diagnostics[0].get("message") if diagnostics else "invalid dataset"
        self.set_status(
            "Dataset preview rejected; "
            f"{summary.get('rejected', 0)} rejected, {len(collisions)} collisions, "
            f"{changed} artifact diffs: {message}"
        )

    def show_validation(self, response: dict[str, Any]) -> None:
        if response.get("valid") is True:
            normalized = response.get("definition")
            if isinstance(normalized, dict):
                self._draft = flow_draft(normalized)
                self._history.reset(flow_draft(self._draft))
                self._populate_flow_fields()
                self._populate_node_fields()
                self._draw_graph()
            self.set_status("Production Registry.Validate: valid")
        else:
            self.set_status(f"Production Registry.Validate: {response.get('reason', 'invalid')}")

    def show_registration(self, response: dict[str, Any]) -> None:
        if response.get("registered") is True:
            self.set_catalog(response)
            definition = response.get("definition") or {}
            flow_id = str(definition.get("id", self.flow_var.get()))
            self.flow_var.set(flow_id)
            self._select_flow_list_item(flow_id)
            self._select_flow()
            self.set_status(
                f"Registered {definition.get('id', 'flow')} through production Registry"
            )
        else:
            self.set_status(
                f"Register rejected: {response.get('reason', 'unknown error')}"
            )

    def save_draft(self) -> None:
        draft = self._commit_fields()
        if draft is None:
            return
        filename = self._filedialog.asksaveasfilename(
            title="Save semantic flow draft",
            defaultextension=".json",
            filetypes=[("Flow definitions", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        if self._nested_flows:
            draft.setdefault("_semanticLab", {})["nestedFlows"] = copy.deepcopy(self._nested_flows)
        try:
            Path(filename).write_text(
                json.dumps(draft, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
        except OSError as error:
            self._messagebox.showerror("Flow draft error", str(error))
            return
        self.set_status(f"Saved draft {Path(filename).name}")

    def load_draft(self) -> None:
        filename = self._filedialog.askopenfilename(
            title="Open semantic flow draft",
            filetypes=[("Flow definitions", "*.json"), ("All files", "*")],
        )
        if not filename:
            return
        try:
            loaded = json.loads(Path(filename).read_text(encoding="utf-8"))
            if not isinstance(loaded, dict) or not isinstance(loaded.get("nodes"), dict):
                raise ValueError("flow draft must contain an object-valued nodes field")
        except (OSError, ValueError, json.JSONDecodeError) as error:
            self._messagebox.showerror("Flow draft error", str(error))
            return
        self._draft = flow_draft(loaded)
        authoring_metadata = loaded.get("_semanticLab")
        self._nested_flows = (
            copy.deepcopy(authoring_metadata.get("nestedFlows", []))
            if isinstance(authoring_metadata, dict)
            and isinstance(authoring_metadata.get("nestedFlows"), list)
            else []
        )
        self._history.reset(flow_draft(self._draft))
        self._node_positions = {}
        self.flow_var.set(str(loaded.get("id", "draft")))
        self.flow_list.selection_clear(0, "end")
        self._selected_node = loaded.get("initial")
        if self._selected_node not in loaded.get("nodes", {}):
            self._selected_node = next(iter(loaded.get("nodes", {})), None)
        self._populate_flow_fields()
        self._populate_node_fields()
        self._draw_graph()
        self.set_status(f"Opened draft {Path(filename).name}; validate before registering")
