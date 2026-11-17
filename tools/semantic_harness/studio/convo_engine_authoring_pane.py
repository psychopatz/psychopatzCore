"""ConvoEngine-native family authoring and trace pane for Semantic Lab.

The pane consumes SemanticLabAuthoringService directly for hierarchical family
browsing, compact family CRUD, reply-outcome editing, registered execute action
selection, separated button-vs-speech simulation, and end-to-end
``affordance -> invoke -> speech -> execute -> result -> reply -> after`` trace.
"""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any

from tools.semantic_harness.codebuilder.convo_engine_fields import (
    describe_unknown_fields,
    list_field_descriptors,
)


class ConvoEngineAuthoringPane:
    """Browse, edit, validate, and trace canonical ConvoEngine exchange families."""

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
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._ScrolledText = scrolled_text
        self._messagebox = messagebox
        self.service = service
        self._field_descriptors = self._load_field_descriptors()
        self.frame = ttk.Frame(parent, padding=6)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(2, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=3)

        self._families: list[dict[str, Any]] = []
        self._filtered_families: list[dict[str, Any]] = []
        self._current_entry: dict[str, Any] | None = None
        self._document: dict[str, Any] | None = None
        self._loaded_fingerprint: str | None = None
        self._editors: dict[str, Any] = {}
        self._action_contracts: list[dict[str, Any]] = []

        self._status_var = tk.StringVar(value="Refresh to load ConvoEngine families")
        self._filter_var = tk.StringVar()
        self._canonical_id_var = tk.StringVar()
        self._kind_var = tk.StringVar(value="dialogue")
        self._namespace_var = tk.StringVar(value="social")
        self._id_var = tk.StringVar(value="new_family")
        self._owner_var = tk.StringVar(value="ProjectHoomans")
        self._speaker_var = tk.StringVar(value='["participant"]')
        self._addressee_var = tk.StringVar(value='["participant"]')
        self._target_var = tk.StringVar(value='{"type": "entity.any"}')
        self._slots_var = tk.StringVar(value="{}")
        self._affordance_label_var = tk.StringVar()
        self._say_single_var = tk.StringVar()
        self._execute_action_var = tk.StringVar()
        self._recommend_pick_var = tk.StringVar()
        self._reply_outcome_var = tk.StringVar(value="valid")
        self._reply_say_var = tk.StringVar()
        self._unknown_fields_var = tk.StringVar(value="(none)")

        self._preview_speaker_var = tk.StringVar(value="player")
        self._preview_addressee_var = tk.StringVar(value="npc")
        self._preview_target_var = tk.StringVar(value="companion")
        self._preview_style_var = tk.StringVar(value="neutral")
        self._preview_locale_var = tk.StringVar(value="EN")
        self._preview_outcome_var = tk.StringVar(value="")
        self._preview_slots_var = tk.StringVar(value="{}")
        self._preview_button_var = tk.StringVar()
        self._preview_speech_var = tk.StringVar()
        self._preview_reply_var = tk.StringVar()

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

    def field_descriptors(self) -> list[dict[str, Any]]:
        return list(self._field_descriptors)

    def _build_toolbar(self) -> None:
        ttk = self._ttk
        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 5))
        toolbar.columnconfigure(1, weight=1)
        ttk.Label(toolbar, text="Filter families (owner / kind / namespace / id)").grid(
            row=0, column=0, sticky="w"
        )
        filter_entry = ttk.Entry(toolbar, textvariable=self._filter_var)
        filter_entry.grid(row=0, column=1, sticky="ew", padx=(6, 6))
        filter_entry.bind("<KeyRelease>", lambda _event: self._apply_filter())
        ttk.Button(toolbar, text="Refresh families", command=self.refresh).grid(row=0, column=2)
        ttk.Button(toolbar, text="Run ConvoEngine Integrity Audit", command=self.run_integrity_audit).grid(
            row=0, column=3, padx=(6, 0)
        )
        ttk.Label(toolbar, textvariable=self._status_var).grid(
            row=1, column=0, columnspan=4, sticky="w", pady=(4, 0)
        )

    def _build_body(self) -> None:
        ttk = self._ttk
        left = ttk.LabelFrame(self.frame, text="ConvoEngine families")
        left.grid(row=2, column=0, sticky="nsew", padx=(0, 7))
        left.rowconfigure(0, weight=1)
        left.columnconfigure(0, weight=1)
        self._family_list = self._tk.Listbox(left, width=40, exportselection=False)
        self._family_list.grid(row=0, column=0, sticky="nsew")
        self._family_list.bind("<<ListboxSelect>>", lambda _event: self._family_selected())
        scroll = ttk.Scrollbar(left, orient="vertical", command=self._family_list.yview)
        scroll.grid(row=0, column=1, sticky="ns")
        self._family_list.configure(yscrollcommand=scroll.set)

        actions = ttk.Frame(left)
        actions.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(5, 0))
        ttk.Button(actions, text="New family", command=self.new_family).pack(side="left")
        ttk.Button(actions, text="Duplicate", command=self.duplicate_family).pack(side="left", padx=3)
        ttk.Button(actions, text="Delete", command=self.delete_family).pack(side="left")

        right = ttk.Frame(self.frame)
        right.grid(row=2, column=1, sticky="nsew")
        right.rowconfigure(1, weight=1)
        right.columnconfigure(0, weight=1)

        identity = ttk.LabelFrame(right, text="Family identity, participants & compact controls")
        identity.grid(row=0, column=0, sticky="ew", pady=(0, 5))
        for col in (1, 3):
            identity.columnconfigure(col, weight=1)

        self._entry(identity, 0, 0, "Canonical ID", self._canonical_id_var, readonly=True)
        self._entry(identity, 0, 2, "Owner", self._owner_var)
        ttk.Label(identity, text="Kind").grid(row=1, column=0, sticky="w", padx=4, pady=2)
        self._kind_box = ttk.Combobox(
            identity,
            textvariable=self._kind_var,
            state="readonly",
            values=("dialogue", "behavior", "beat", "realization"),
            width=18,
        )
        self._kind_box.grid(row=1, column=1, sticky="ew", padx=(0, 5), pady=2)
        self._entry(identity, 1, 2, "Namespace", self._namespace_var)
        self._entry(identity, 2, 0, "Family ID", self._id_var)
        self._entry(identity, 2, 2, "Slots JSON", self._slots_var)
        self._entry(identity, 3, 0, "Speaker kinds", self._speaker_var)
        self._entry(identity, 3, 2, "Addressee kinds", self._addressee_var)
        self._entry(identity, 4, 0, "UI-only affordance label", self._affordance_label_var)
        self._entry(identity, 4, 2, "Direct single say / key 1", self._say_single_var)

        ttk.Label(identity, text="Execute contract").grid(row=5, column=0, sticky="w", padx=4, pady=2)
        self._execute_box = ttk.Combobox(identity, textvariable=self._execute_action_var, width=24)
        self._execute_box.grid(row=5, column=1, sticky="ew", padx=(0, 5), pady=2)
        ttk.Label(identity, text="Recommend family").grid(row=5, column=2, sticky="w", padx=4, pady=2)
        rec_row = ttk.Frame(identity)
        rec_row.grid(row=5, column=3, sticky="ew", padx=(0, 5), pady=2)
        rec_row.columnconfigure(0, weight=1)
        self._recommend_box = ttk.Combobox(rec_row, textvariable=self._recommend_pick_var, width=22)
        self._recommend_box.grid(row=0, column=0, sticky="ew")
        ttk.Button(rec_row, text="+Recommend", command=self.add_recommendation).grid(row=0, column=1, padx=(4, 0))

        self._entry(identity, 6, 0, "Reply outcome name", self._reply_outcome_var)
        reply_row = ttk.Frame(identity)
        reply_row.grid(row=6, column=2, columnspan=2, sticky="ew", padx=4, pady=2)
        reply_row.columnconfigure(1, weight=1)
        ttk.Label(reply_row, text="Reply say").grid(row=0, column=0, sticky="w", padx=(0, 4))
        ttk.Entry(reply_row, textvariable=self._reply_say_var).grid(row=0, column=1, sticky="ew")
        ttk.Button(reply_row, text="Set reply", command=self.set_reply_outcome).grid(row=0, column=2, padx=(4, 2))
        ttk.Button(reply_row, text="Del reply", command=self.delete_reply_outcome).grid(row=0, column=3)
        self._entry(identity, 7, 0, "Extra / preserved fields", self._unknown_fields_var, readonly=True)

        notebook = ttk.Notebook(right)
        notebook.grid(row=1, column=0, sticky="nsew")
        structured = ttk.Frame(notebook, padding=4)
        preview = ttk.Frame(notebook, padding=4)
        notebook.add(structured, text="Exchange family structure")
        notebook.add(preview, text="Simulation / trace")

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
            editor = self._ScrolledText(box, height=4, wrap="none")
            editor.grid(row=0, column=0, sticky="nsew")
            self._editors[name] = editor

        preview.columnconfigure(0, weight=1)
        preview.rowconfigure(3, weight=1)
        ctx = ttk.LabelFrame(preview, text="Actor-neutral simulation context (player<->NPC or NPC<->NPC)")
        ctx.grid(row=0, column=0, sticky="ew", pady=(0, 5))
        for col in (1, 3):
            ctx.columnconfigure(col, weight=1)
        self._entry(ctx, 0, 0, "Speaker", self._preview_speaker_var)
        self._entry(ctx, 0, 2, "Addressee", self._preview_addressee_var)
        self._entry(ctx, 1, 0, "Target", self._preview_target_var)
        self._entry(ctx, 1, 2, "Style", self._preview_style_var)
        self._entry(ctx, 2, 0, "Locale", self._preview_locale_var)
        self._entry(ctx, 2, 2, "Result outcome override", self._preview_outcome_var)
        self._entry(ctx, 3, 0, "Slot values JSON", self._preview_slots_var)

        separated = ttk.LabelFrame(preview, text="Separated button label vs spoken action vs reply")
        separated.grid(row=1, column=0, sticky="ew", pady=(0, 5))
        separated.columnconfigure(1, weight=1)
        self._entry(separated, 0, 0, "UI Button (button_label)", self._preview_button_var, readonly=True)
        self._entry(separated, 1, 0, "Initiating Speech (spoken_action)", self._preview_speech_var, readonly=True)
        self._entry(separated, 2, 0, "Selected Reply (response)", self._preview_reply_var, readonly=True)

        preview_buttons = ttk.Frame(preview)
        preview_buttons.grid(row=2, column=0, sticky="ew", pady=(0, 5))
        ttk.Button(preview_buttons, text="Validate & trace", command=self.preview_record).pack(side="left")
        ttk.Button(preview_buttons, text="Write canonical source", command=self.write_source).pack(
            side="left", padx=6
        )
        self._report = self._ScrolledText(preview, wrap="none", state="disabled")
        self._report.grid(row=3, column=0, sticky="nsew")

    def _entry(
        self,
        parent: Any,
        row: int,
        column: int,
        label: str,
        variable: Any,
        *,
        readonly: bool = False,
    ) -> None:
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
        contract_ids = [item["id"] for item in self._action_contracts]
        self._execute_box.configure(values=contract_ids)
        self._recommend_box.configure(values=[item["canonicalID"] for item in self._families])
        self._apply_filter()

    def _apply_filter(self) -> None:
        needle = self._filter_var.get().strip().lower()
        self._family_list.delete(0, "end")
        self._filtered_families = [
            item
            for item in self._families
            if not needle
            or needle in str(item.get("canonicalID", "")).lower()
            or needle in str(item.get("owner", "")).lower()
            or needle in str(item.get("kind", "")).lower()
            or needle in str(item.get("path", "")).lower()
        ]
        for item in self._filtered_families:
            self._family_list.insert(
                "end",
                f"[{item['owner']}] {item['kind']} · {item['canonicalID']}",
            )
        if self._filtered_families:
            self._family_list.selection_set(0)
            self._family_selected()
        else:
            self._status_var.set("No ConvoEngine families match filter")

    def _family_selected(self) -> None:
        selection = self._family_list.curselection()
        if not selection or int(selection[0]) >= len(self._filtered_families):
            return
        entry = self._filtered_families[int(selection[0])]
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
        self._document = document
        self._loaded_fingerprint = loaded_fp
        self._load_family_form(document)
        self._status_var.set(
            f"{entry['owner']} · {entry['canonicalID']} ({entry['path']})"
        )

    def _load_family_form(self, doc: dict[str, Any]) -> None:
        ns = doc.get("namespace") or ""
        fid = str(doc.get("id") or "")
        self._canonical_id_var.set(f"{ns}.{fid}" if ns else fid)
        self._kind_var.set(str(doc.get("kind") or "dialogue"))
        self._namespace_var.set(str(ns))
        self._id_var.set(fid)
        self._owner_var.set(str(doc.get("owner") or (self._current_entry or {}).get("owner") or ""))
        participants = doc.get("participants") or {}
        self._speaker_var.set(self._pretty(participants.get("speaker", ["participant"])).strip())
        self._addressee_var.set(self._pretty(participants.get("addressee", ["participant"])).strip())
        self._target_var.set(self._pretty(doc.get("target", {"type": "entity.any"})).strip())
        self._slots_var.set(self._pretty(doc.get("slots", {})).strip())

        aff = doc.get("affordance")
        if isinstance(aff, dict):
            lbl = aff.get("label")
            self._affordance_label_var.set(lbl if isinstance(lbl, str) else "")
        else:
            self._affordance_label_var.set("")

        say = doc.get("say")
        self._say_single_var.set(say if isinstance(say, str) else "")
        exe = doc.get("execute")
        self._execute_action_var.set(
            exe.get("use", "") if isinstance(exe, dict) else (exe if isinstance(exe, str) else "")
        )
        for descriptor in self._field_descriptors:
            name = str(descriptor["name"])
            self._write_json_editor(name, doc.get(name))
        unknown = describe_unknown_fields(doc)
        self._unknown_fields_var.set(", ".join(unknown.keys()) if unknown else "(none)")

    def _form_document(self) -> dict[str, Any]:
        if self._document is None:
            raise ValueError("Select or create a ConvoEngine family first")
        doc = copy.deepcopy(self._document)
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
        for descriptor in self._field_descriptors:
            name = str(descriptor["name"])
            value = self._read_json_editor(name)
            if value is None:
                doc.pop(name, None)
            else:
                doc[name] = value

        single_say = self._say_single_var.get().strip()
        if single_say and "say" not in doc:
            doc["say"] = single_say
        aff_label = self._affordance_label_var.get().strip()
        if aff_label:
            aff_obj = copy.deepcopy(doc.get("affordance") or {})
            if isinstance(aff_obj, dict) and isinstance(aff_obj.get("label"), str | type(None)):
                aff_obj["label"] = aff_label
                doc["affordance"] = aff_obj
        exe_action = self._execute_action_var.get().strip()
        if exe_action:
            exe_obj = doc.get("execute")
            if isinstance(exe_obj, dict):
                exe_obj["use"] = exe_action
            elif not exe_obj:
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
        self._status_var.set(f"Updated reply.{outcome}; validate and write explicitly")

    def delete_reply_outcome(self) -> None:
        if self._document is None:
            return
        outcome = self._reply_outcome_var.get().strip()
        reply = self._read_json_editor("reply") or {}
        if isinstance(reply, dict) and outcome in reply:
            reply.pop(outcome)
            self._write_json_editor("reply", reply or None)
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
        self._status_var.set(f"Duplicated as {dup['id']} in memory; set target path & write")

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
            slot_values = json.loads(self._preview_slots_var.get() or "{}")
            report = self.service.dispatch_operation(
                "convo.simulate",
                {
                    "document": doc,
                    "sourcePath": (self._current_entry or {}).get("sourcePath"),
                    "speaker": self._preview_speaker_var.get().strip() or "player",
                    "addressee": self._preview_addressee_var.get().strip() or "npc",
                    "npcTarget": self._preview_target_var.get().strip() or None,
                    "slotValues": slot_values,
                    "style": self._preview_style_var.get().strip() or "neutral",
                    "locale": self._preview_locale_var.get().strip() or "EN",
                    "resultOutcome": self._preview_outcome_var.get().strip() or None,
                },
            )
            btn = report.get("buttonPreview") or {}
            speech = report.get("initiatingSpeechPreview") or {}
            rep = (report.get("replyPreview") or {}).get("speech") or {}
            self._preview_button_var.set(str(btn.get("renderedLabel") or ""))
            self._preview_speech_var.set(str(speech.get("renderedText") or ""))
            self._preview_reply_var.set(str(rep.get("renderedText") or ""))
            self._set_report(report)
            self._status_var.set(
                "ConvoEngine validated & traced (affordance -> speech -> execute -> result -> reply)"
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
            self.refresh()
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
