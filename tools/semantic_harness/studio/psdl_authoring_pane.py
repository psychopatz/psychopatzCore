"""Structured PSDL authoring surface for Semantic Lab.

The pane is a consumer of SemanticLabAuthoringService. It never compiles or
interprets PSDL itself; all edits are sent through the Core service, which
owns validation, normalization, lineage, and package routing.
"""

from __future__ import annotations

import copy
import json
from typing import Any


class PSDLAuthoringPane:
    """Browse and edit Core-routed PSDL records without a second editor format."""

    _JSON_FIELDS = (
        ("when", "Predicate / collection constraints"),
        ("bindings", "Typed bindings / resolvers"),
        ("response", "Dialogue response, turns and nested offers"),
        ("turns", "Turns and participant offers"),
        ("offers", "Semantic affordances"),
        ("transitions", "Transitions"),
        ("entry", "Beat entry predicate"),
        ("maintain", "Beat maintain predicate"),
        ("exit", "Beat exit predicate"),
        ("candidates", "Beat behavior candidates"),
        ("translations", "Realization locale variants"),
        ("forms", "Realization forms"),
        ("metadata", "Source lineage / runtime metadata"),
    )

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        service: Any,
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._messagebox = messagebox
        self.service = service
        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)
        self._sources: list[dict[str, Any]] = []
        self._source_by_label: dict[str, dict[str, Any]] = {}
        self._document: dict[str, Any] | None = None
        self._source: dict[str, Any] | None = None
        self._record: dict[str, Any] | None = None
        self._record_index: int | None = None
        self._editors: dict[str, Any] = {}
        self._status_var = tk.StringVar(value="Refresh to load manifest-routed PSDL sources")
        self._source_var = tk.StringVar()
        self._id_var = tk.StringVar()
        self._kind_var = tk.StringVar(value="dialogue")
        self._owner_var = tk.StringVar()
        self._speaker_var = tk.StringVar(value='["participant"]')
        self._addressee_var = tk.StringVar(value='["participant"]')
        self._target_var = tk.StringVar(value='{"type": "entity.any"}')
        self._slots_var = tk.StringVar(value="{}")
        self._references_var = tk.StringVar(value="{}")
        self._locale_en_var = tk.StringVar()
        self._locale_tl_var = tk.StringVar()
        self._preview_speaker_var = tk.StringVar(value="speaker")
        self._preview_addressee_var = tk.StringVar(value="addressee")
        self._preview_target_var = tk.StringVar(value="target")

        self._build_toolbar()
        self._build_body()
        self.refresh()

    def _build_toolbar(self) -> None:
        ttk = self._ttk
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 5))
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Canonical PSDL source").grid(row=0, column=0, sticky="w")
        self._source_box = ttk.Combobox(
            toolbar, textvariable=self._source_var, state="readonly", width=58
        )
        self._source_box.grid(row=0, column=1, sticky="ew", padx=(6, 6))
        self._source_box.bind("<<ComboboxSelected>>", lambda _event: self._source_changed())
        ttk.Button(toolbar, text="Refresh sources", command=self.refresh).grid(row=0, column=2)
        ttk.Label(toolbar, textvariable=self._status_var).grid(
            row=1, column=0, columnspan=3, sticky="w", pady=(4, 0)
        )

    def _build_body(self) -> None:
        ttk = self._ttk
        left = ttk.LabelFrame(self.frame, text="PSDL records")
        left.grid(row=2, column=0, sticky="nsew", padx=(0, 7))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._record_list = self._tk.Listbox(left, width=34, exportselection=False)
        self._record_list.grid(row=0, column=0, sticky="nsew")
        self._record_list.bind("<<ListboxSelect>>", lambda _event: self._record_changed())
        record_scroll = ttk.Scrollbar(left, orient="vertical", command=self._record_list.yview)
        record_scroll.grid(row=0, column=1, sticky="ns")
        self._record_list.configure(yscrollcommand=record_scroll.set)
        actions = ttk.Frame(left)
        actions.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(5, 0))
        ttk.Button(actions, text="New", command=self.new_record).pack(side="left")
        ttk.Button(actions, text="Duplicate", command=self.duplicate_record).pack(side="left", padx=3)
        ttk.Button(actions, text="Delete", command=self.delete_record).pack(side="left")
        ttk.Button(actions, text="Move up", command=lambda: self.reorder_record(-1)).pack(side="left", padx=(8, 2))
        ttk.Button(actions, text="Move down", command=lambda: self.reorder_record(1)).pack(side="left")

        right = ttk.Frame(self.frame)
        right.grid(row=2, column=1, sticky="nsew")
        right.rowconfigure(1, weight=1)
        right.columnconfigure(0, weight=1)
        identity = ttk.LabelFrame(right, text="Structured identity and participants")
        identity.grid(row=0, column=0, sticky="ew", pady=(0, 5))
        identity.columnconfigure(1, weight=1)
        identity.columnconfigure(3, weight=1)
        self._entry(identity, 0, 0, "Canonical ID", self._id_var, readonly=True)
        self._entry(identity, 0, 2, "Owner", self._owner_var)
        ttk.Label(identity, text="Kind").grid(row=1, column=0, sticky="w", padx=4, pady=2)
        self._kind_box = ttk.Combobox(
            identity, textvariable=self._kind_var, state="readonly",
            values=("dialogue", "behavior", "beat", "realization"), width=18,
        )
        self._kind_box.grid(row=1, column=1, sticky="ew", padx=(0, 5), pady=2)
        self._entry(identity, 1, 2, "Speaker kinds", self._speaker_var)
        self._entry(identity, 2, 0, "Addressee kinds", self._addressee_var)
        self._entry(identity, 2, 2, "Target reference", self._target_var)
        self._entry(identity, 3, 0, "Typed slots", self._slots_var)
        self._entry(identity, 3, 2, "Typed references", self._references_var)
        self._entry(identity, 4, 0, "EN fallback text", self._locale_en_var)
        self._entry(identity, 4, 2, "TL locale text", self._locale_tl_var)

        notebook = ttk.Notebook(right)
        notebook.grid(row=1, column=0, sticky="nsew")
        structured = ttk.Frame(notebook, padding=4)
        preview = ttk.Frame(notebook, padding=4)
        notebook.add(structured, text="Predicates / turns / modules")
        notebook.add(preview, text="Preview / lineage / trace")
        structured.columnconfigure(0, weight=1)
        structured.rowconfigure(0, weight=1)
        fields = ttk.PanedWindow(structured, orient="vertical")
        fields.grid(row=0, column=0, sticky="nsew")
        upper = ttk.Frame(fields)
        lower = ttk.Frame(fields)
        upper.columnconfigure(0, weight=1)
        lower.columnconfigure(0, weight=1)
        fields.add(upper, weight=1)
        fields.add(lower, weight=2)
        for index, (name, label) in enumerate(self._JSON_FIELDS):
            host = upper if index < 5 else lower
            row = index if index < 5 else index - 5
            box = ttk.LabelFrame(host, text=label)
            box.grid(row=row, column=0, sticky="nsew", padx=2, pady=2)
            host.rowconfigure(row, weight=1)
            box.columnconfigure(0, weight=1)
            editor = self._ScrolledText(box, height=4, wrap="none")
            editor.grid(row=0, column=0, sticky="nsew")
            self._editors[name] = editor

        preview.columnconfigure(0, weight=1)
        preview.rowconfigure(2, weight=1)
        context = ttk.LabelFrame(preview, text="Preview actor-neutral context")
        context.grid(row=0, column=0, sticky="ew", pady=(0, 5))
        context.columnconfigure(1, weight=1)
        context.columnconfigure(3, weight=1)
        self._entry(context, 0, 0, "Speaker", self._preview_speaker_var)
        self._entry(context, 0, 2, "Addressee", self._preview_addressee_var)
        self._entry(context, 1, 0, "Target", self._preview_target_var)
        ttk.Label(
            context,
            text="Use the same authored record for player↔NPC, NPC↔NPC, and mixed scenes.",
        ).grid(row=1, column=2, columnspan=2, sticky="w", padx=4)
        preview_buttons = ttk.Frame(preview)
        preview_buttons.grid(row=1, column=0, sticky="ew", pady=(0, 5))
        ttk.Button(preview_buttons, text="Validate / trace", command=self.preview_record).pack(side="left")
        ttk.Button(preview_buttons, text="Write canonical source", command=self.write_source).pack(
            side="left", padx=6
        )
        self._report = self._ScrolledText(preview, wrap="none", state="disabled")
        self._report.grid(row=2, column=0, sticky="nsew")

    def _entry(self, parent: Any, row: int, column: int, label: str, variable: Any, *, readonly: bool = False) -> None:
        self._ttk.Label(parent, text=label).grid(row=row, column=column, sticky="w", padx=4, pady=2)
        entry = self._ttk.Entry(parent, textvariable=variable)
        entry.grid(row=row, column=column + 1, sticky="ew", padx=(0, 5), pady=2)
        if readonly:
            entry.configure(state="readonly")

    @staticmethod
    def _pretty(value: Any) -> str:
        return json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"

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

    def refresh(self) -> None:
        try:
            self._sources = self.service.list_psdl_sources()
        except (OSError, ValueError, KeyError, TypeError) as error:
            self._sources = []
            self._source_by_label = {}
            self._status_var.set(f"PSDL source load failed: {error}")
            return
        labels = []
        self._source_by_label = {}
        for source in self._sources:
            label = f"{source.get('owner')} · {source.get('path')}"
            labels.append(label)
            self._source_by_label[label] = source
        self._source_box.configure(values=labels)
        if labels:
            self._source_var.set(labels[0])
            self._source_changed()
        else:
            self._status_var.set("No manifest-routed PSDL sources found")

    def _source_changed(self) -> None:
        source = self._source_by_label.get(self._source_var.get())
        if not source:
            return
        try:
            document = self.service.load_psdl_source(str(source["sourcePath"]))
        except (OSError, ValueError, KeyError, TypeError) as error:
            self._status_var.set(f"PSDL source load failed: {error}")
            return
        self._source = source
        self._document = document
        self._record = None
        self._render_record_list()
        self._status_var.set(
            f"{source.get('owner')} source · {source.get('recordCount', 0)} records · "
            "Core compiler/IR validation is authoritative"
        )

    def _render_record_list(self) -> None:
        self._record_list.delete(0, "end")
        for record in (self._document or {}).get("records", []):
            self._record_list.insert(
                "end", f"{record.get('kind', 'unknown')} · {record.get('id', '<missing>')}"
            )
        if self._record_list.size():
            self._record_list.selection_set(0)
            self._record_changed()

    def _record_changed(self) -> None:
        selection = self._record_list.curselection()
        records = (self._document or {}).get("records", [])
        if not selection or selection[0] >= len(records):
            return
        self._record_index = int(selection[0])
        self._record = copy.deepcopy(records[self._record_index])
        self._load_record_form(self._record)

    def _load_record_form(self, record: dict[str, Any]) -> None:
        self._id_var.set(str(record.get("id", "")))
        self._kind_var.set(str(record.get("kind", "dialogue")))
        self._owner_var.set(str(record.get("owner") or (self._source or {}).get("owner") or ""))
        participants = record.get("participants") or {}
        self._speaker_var.set(self._pretty(participants.get("speaker", ["participant"])).strip())
        self._addressee_var.set(self._pretty(participants.get("addressee", ["participant"])).strip())
        self._target_var.set(self._pretty(record.get("target", {"type": "entity.any"})).strip())
        self._slots_var.set(self._pretty(record.get("slots", {})).strip())
        self._references_var.set(self._pretty(record.get("references", {})).strip())
        text = record.get("text")
        if isinstance(text, dict):
            self._locale_en_var.set(" ".join(text.get("EN", [])) if isinstance(text.get("EN"), list) else str(text.get("EN", "")))
            self._locale_tl_var.set(" ".join(text.get("TL", [])) if isinstance(text.get("TL"), list) else str(text.get("TL", "")))
        else:
            self._locale_en_var.set("")
            self._locale_tl_var.set("")
        for name, _label in self._JSON_FIELDS:
            self._write_json_editor(name, record.get(name))

    def _form_patch(self) -> dict[str, Any]:
        if self._record is None:
            raise ValueError("Select a PSDL record first")
        patch = copy.deepcopy(self._record)
        patch["kind"] = self._kind_var.get().strip()
        owner = self._owner_var.get().strip()
        if owner:
            patch["owner"] = owner
        patch["participants"] = {
            "speaker": json.loads(self._speaker_var.get()),
            "addressee": json.loads(self._addressee_var.get()),
        }
        patch["target"] = json.loads(self._target_var.get())
        patch["slots"] = json.loads(self._slots_var.get())
        patch["references"] = json.loads(self._references_var.get())
        for name, _label in self._JSON_FIELDS:
            value = self._read_json_editor(name)
            if value is None:
                patch.pop(name, None)
            else:
                patch[name] = value
        if self._locale_en_var.get().strip() or self._locale_tl_var.get().strip():
            patch["text"] = {
                "EN": [self._locale_en_var.get().strip()],
                "TL": [self._locale_tl_var.get().strip()],
            }
        return patch

    def _apply_form(self) -> dict[str, Any]:
        if self._document is None or self._record is None:
            raise ValueError("Select a PSDL record first")
        result = self.service.edit_psdl_record(
            self._document,
            str(self._record["id"]),
            self._form_patch(),
            source_path=str((self._source or {}).get("sourcePath", "")),
        )
        if result.get("ok") is not True:
            diagnostics = result.get("diagnostics") or [{"message": "PSDL edit rejected"}]
            raise ValueError(diagnostics[0].get("message"))
        self._document = result["document"]
        self._record = copy.deepcopy(self._document["records"][self._record_index or 0])
        return result

    def new_record(self) -> None:
        if self._document is None:
            return
        kind = self._kind_var.get() or "dialogue"
        owner = str((self._source or {}).get("owner") or "ProjectHoomans")
        templates = {
            "dialogue": {
                "kind": "dialogue", "id": "dialogue.new_record", "owner": owner,
                "participants": {"speaker": ["participant"], "addressee": ["participant"]},
                "response": {"act": "REPLY", "turns": [{"id": "reply", "text": {"EN": ["New response."], "TL": ["Bagong tugon."]}}]},
            },
            "behavior": {
                "kind": "behavior", "id": "behavior.new_record", "owner": owner,
                "stimuli": ["NPC_SEMANTIC_ACT"], "act": "REPLY", "mode": "one_shot",
                "requiredCapabilities": ["speech"], "outputs": {"speech": {"dialogueAct": "REPLY", "contentTemplateID": "dialogue.new_record"}}, "baseRelevance": 0.5,
            },
            "beat": {
                "kind": "beat", "id": "beat.new_record", "owner": owner,
                "stimuli": ["NPC_SEMANTIC_ACT"], "entry": {"path": "conversation.active", "op": "exists"},
                "maintain": {"path": "conversation.active", "op": "exists"}, "exit": {"path": "conversation.ended", "op": "exists"}, "candidates": [],
            },
            "realization": {
                "kind": "realization", "id": "lexeme.new_record", "owner": "PsychopatzCore",
                "type": "lexeme", "concept": "dialogue.new_record", "forms": {"EN": ["new"], "TL": ["bago"]},
            },
        }
        record = templates[kind]
        try:
            result = self.service.create_psdl_record(
                self._document, record, source_path=str((self._source or {}).get("sourcePath", ""))
            )
        except (OSError, ValueError, TypeError) as error:
            self._status_var.set(f"New PSDL record rejected: {error}")
            return
        if result.get("ok") is True:
            self._document = result["document"]
            self._render_record_list()
            self._status_var.set(f"Created {record['id']} in memory; validate and write explicitly")
        else:
            self._status_var.set("New PSDL record rejected by Core validation")

    def duplicate_record(self) -> None:
        if self._document is None or self._record is None:
            return
        new_id = str(self._record["id"]) + ".copy"
        try:
            result = self.service.duplicate_psdl_record(
                self._document, str(self._record["id"]), new_id,
                source_path=str((self._source or {}).get("sourcePath", "")),
            )
        except (OSError, ValueError, TypeError) as error:
            self._status_var.set(f"Duplicate rejected: {error}")
            return
        if result.get("ok") is True:
            self._document = result["document"]
            self._render_record_list()
            self._status_var.set(f"Duplicated {new_id}; validate and write explicitly")

    def delete_record(self) -> None:
        if self._document is None or self._record is None:
            return
        if not self._messagebox.askyesno("Delete PSDL record", f"Delete {self._record['id']} from this source?"):
            return
        try:
            result = self.service.delete_psdl_record(
                self._document, str(self._record["id"]),
                source_path=str((self._source or {}).get("sourcePath", "")),
            )
        except (OSError, ValueError, TypeError) as error:
            self._status_var.set(f"Delete rejected: {error}")
            return
        if result.get("ok") is True:
            self._document = result["document"]
            self._render_record_list()
            self._status_var.set("Record deleted in memory; write explicitly to persist")

    def reorder_record(self, delta: int) -> None:
        if self._document is None or self._record_index is None:
            return
        records = self._document.get("records", [])
        target = self._record_index + delta
        if target < 0 or target >= len(records):
            return
        ids = [item["id"] for item in records]
        ids[self._record_index], ids[target] = ids[target], ids[self._record_index]
        try:
            result = self.service.reorder_psdl_records(
                self._document, ids, source_path=str((self._source or {}).get("sourcePath", ""))
            )
        except (OSError, ValueError, TypeError) as error:
            self._status_var.set(f"Reorder rejected: {error}")
            return
        if result.get("ok") is True:
            self._document = result["document"]
            self._render_record_list()
            self._record_list.selection_set(target)
            self._record_changed()

    def preview_record(self) -> dict[str, Any] | None:
        try:
            result = self._apply_form()
            current = self._record or {}
            report = {
                "ok": True,
                "source": self._source,
                "previewContext": {
                    "speaker": self._preview_speaker_var.get(),
                    "addressee": self._preview_addressee_var.get(),
                    "target": self._preview_target_var.get(),
                },
                "compiledFingerprint": result.get("compiledFingerprint"),
                "diagnostics": result.get("preview", {}).get("diagnostics", []),
                "trace": [
                    {"stage": "predicate", "value": current.get("when") or current.get("constraints")},
                    {"stage": "beat", "value": current.get("group") if current.get("kind") == "beat" else None},
                    {"stage": "behavior", "value": current.get("id") if current.get("kind") == "behavior" else current.get("respond")},
                    {"stage": "variant", "value": current.get("variants") or (current.get("response") or {}).get("variants")},
                    {"stage": "offer", "value": current.get("offers") or (current.get("response") or {}).get("offers")},
                ],
            }
            self._set_report(report)
            self._status_var.set("PSDL validated; predicate → beat → behavior → variant → offer trace ready")
            return report
        except (OSError, ValueError, TypeError, KeyError) as error:
            report = {"ok": False, "diagnostics": [{"severity": "error", "message": str(error)}]}
            self._set_report(report)
            self._status_var.set(f"PSDL validation rejected: {error}")
            return report

    def write_source(self) -> dict[str, Any]:
        if self._document is None or self._source is None:
            return {"ok": False, "writes": [], "reason": "no_source"}
        report = self.preview_record()
        if not report or report.get("ok") is not True:
            return report or {"ok": False, "writes": []}
        if not self._messagebox.askyesno(
            "Write PSDL source",
            "Write this validated canonical PSDL source? Generated runtime artifacts remain downstream.",
        ):
            return {"ok": False, "cancelled": True, "writes": []}
        written = self.service.write_psdl_source(
            str(self._source["sourcePath"]), self._document, expected_source_fingerprint=None
        )
        self._status_var.set(
            "Canonical PSDL source written; compile downstream artifacts explicitly"
            if written.get("ok") is True else "PSDL source write rejected"
        )
        return written


__all__ = ["PSDLAuthoringPane"]
