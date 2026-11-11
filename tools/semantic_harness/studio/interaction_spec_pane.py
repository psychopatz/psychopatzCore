"""Tk form for composing one canonical typed InteractionSpec."""

from __future__ import annotations

import hashlib
import json
import re
from typing import Any, Callable


class InteractionSpecPane:
    """Create, preview, approve, and generate a configured interaction."""

    def __init__(
        self,
        parent: Any,
        tk: Any,
        ttk: Any,
        scrolled_text: Any,
        messagebox: Any,
        *,
        on_preview: Callable[[dict[str, Any]], dict[str, Any]],
        on_generate: Callable[[dict[str, Any]], Any],
        on_inspect: Callable[[], Any],
    ) -> None:
        self._tk = tk
        self._ttk = ttk
        self._messagebox = messagebox
        self._on_preview = on_preview
        self._on_generate = on_generate
        self._on_inspect = on_inspect
        self._actions: dict[str, dict[str, Any]] = {}
        self._last_preview: dict[str, Any] | None = None
        self._preview_key: str | None = None
        self._approved_key: str | None = None

        self.frame = ttk.Frame(parent, padding=8)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)
        self.frame.columnconfigure(1, weight=2)

        self._id_var = tk.StringVar(value="pnc.lab.new_interaction")
        self._utterance_var = tk.StringVar(value="stay with me")
        self._negative_var = tk.StringVar(value="don't stay with me")
        self._action_var = tk.StringVar()
        self._pool_var = tk.StringVar(value="semantic.lab.new_interaction")
        self._english_var = tk.StringVar(value="Okay, I will do that.")
        self._tagalog_var = tk.StringVar(value="Sige, gagawin ko iyon.")
        self._status_var = tk.StringVar(value="Load the live capability catalog to compose an interaction.")

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 6))
        ttk.Label(toolbar, text="Configured interaction · typed blocks").pack(side="left")
        ttk.Label(toolbar, textvariable=self._status_var).pack(side="right")

        form = ttk.LabelFrame(self.frame, text="Block instances")
        form.grid(row=1, column=0, sticky="nsew", padx=(0, 8))
        form.columnconfigure(1, weight=1)
        self._add_entry(form, 0, "Spec ID", self._id_var)
        self._add_entry(form, 1, "Positive utterance", self._utterance_var)
        self._add_entry(form, 2, "Negative utterance", self._negative_var)
        self._ttk.Label(form, text="Capability").grid(row=3, column=0, sticky="w", padx=6, pady=2)
        self._action_box = ttk.Combobox(form, textvariable=self._action_var, state="readonly")
        self._action_box.grid(row=3, column=1, sticky="ew", padx=(0, 6), pady=2)
        self._add_entry(form, 4, "Response pool", self._pool_var)
        self._add_entry(form, 5, "EN response", self._english_var)
        self._add_entry(form, 6, "TL response", self._tagalog_var)
        ttk.Label(
            form,
            text="The form creates language.trigger → gameplay_actions.capability → dialogue_responses.response_pool typed edges.",
            wraplength=360,
            justify="left",
        ).grid(row=7, column=0, columnspan=2, sticky="w", padx=6, pady=(10, 6))

        report_frame = ttk.LabelFrame(self.frame, text="Generated Lua preview and approval")
        report_frame.grid(row=1, column=1, sticky="nsew")
        report_frame.rowconfigure(0, weight=1)
        report_frame.columnconfigure(0, weight=1)
        self._report = scrolled_text(report_frame, wrap="none", state="disabled")
        self._report.grid(row=0, column=0, sticky="nsew")

        actions = ttk.Frame(self.frame)
        actions.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(6, 0))
        self._preview_button = ttk.Button(actions, text="Preview generated Lua", command=self.preview)
        self._preview_button.pack(side="left")
        self._approve_button = ttk.Button(actions, text="Approve", command=self.approve)
        self._approve_button.pack(side="left", padx=6)
        self._generate_button = ttk.Button(actions, text="Generate + restart worker", command=self.generate)
        self._generate_button.pack(side="left")
        self._inspect_button = ttk.Button(actions, text="Inspect live dialogue", command=on_inspect)
        self._inspect_button.pack(side="right")
        self._buttons = (
            self._preview_button,
            self._approve_button,
            self._generate_button,
            self._inspect_button,
        )

    def _add_entry(self, parent: Any, row: int, label: str, variable: Any) -> None:
        self._ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=6, pady=2)
        self._ttk.Entry(parent, textvariable=variable).grid(row=row, column=1, sticky="ew", padx=(0, 6), pady=2)

    def set_production_catalog(self, catalog: dict[str, Any] | None) -> None:
        self._actions = {}
        for action in (catalog or {}).get("actionCatalog", []):
            if not isinstance(action, dict) or not action.get("id"):
                continue
            capability_id = str(action.get("bindingID") or action.get("capabilityID") or action["id"])
            frame = action.get("frame") if isinstance(action.get("frame"), dict) else {}
            self._actions[str(action["id"])] = {
                "capabilityID": capability_id,
                "action": str(frame.get("action") or action["id"]),
            }
        values = sorted(self._actions)
        self._action_box.configure(values=values)
        if self._action_var.get() not in self._actions:
            self._action_var.set(values[0] if values else "")
        self._status_var.set(f"{len(values)} registered capabilities available")

    def _spec(self) -> dict[str, Any]:
        action = self._actions.get(self._action_var.get().strip())
        if not action:
            raise ValueError("select a registered capability")
        spec_id = self._id_var.get().strip()
        slug = re.sub(r"[^a-z0-9]+", "_", spec_id.lower()).strip("_") or "interaction"
        response_key = "UI_PNC_Conversation_Semantic_" + "".join(
            word[:1].upper() + word[1:] for word in slug.split("_")
        ) + "Accepted"
        return {
            "schema": "semantic.interaction_spec.v1",
            "id": spec_id,
            "owner": "SemanticLab",
            "blocks": [
                {
                    "id": "trigger",
                    "type": "language.trigger",
                    "parameters": {
                        "utterance": self._utterance_var.get().strip(),
                        "negativeUtterance": self._negative_var.get().strip(),
                        "frame": {
                            "intent": "REQUEST",
                            "speechAct": "REQUEST",
                            "action": action["action"],
                        },
                    },
                },
                {
                    "id": "capability",
                    "type": "gameplay_actions.capability",
                    "parameters": {
                        "capabilityID": action["capabilityID"],
                        "action": action["action"],
                    },
                },
                {
                    "id": "response",
                    "type": "dialogue_responses.response_pool",
                    "parameters": {
                        "poolID": self._pool_var.get().strip(),
                        "variants": [{
                            "id": "accepted",
                            "key": response_key,
                            "translations": {
                                "EN": self._english_var.get().strip(),
                                "TL": self._tagalog_var.get().strip(),
                            },
                        }],
                    },
                },
            ],
            "connections": [
                {"from": "trigger", "to": "capability", "type": "semantic"},
                {"from": "capability", "to": "response", "type": "response"},
            ],
        }

    def _key(self, spec: dict[str, Any]) -> str:
        return hashlib.sha256(json.dumps(spec, sort_keys=True).encode("utf-8")).hexdigest()

    def preview(self) -> dict[str, Any] | None:
        try:
            spec = self._spec()
        except ValueError as error:
            self._status_var.set(str(error))
            return None
        report = self._on_preview(spec)
        self._set_report(report)
        self._last_preview = report
        self._preview_key = self._key(spec)
        self._approved_key = None
        self._status_var.set(
            "Canonical source + generated Lua/EN-TL diff is ready; no files written."
            if report.get("ok") is True else "Interaction spec rejected; no files written."
        )
        return report

    def approve(self) -> bool:
        if not self._last_preview or self._last_preview.get("ok") is not True:
            self._status_var.set("Preview a valid interaction before approval")
            return False
        try:
            spec = self._spec()
        except ValueError as error:
            self._status_var.set(str(error))
            return False
        if self._key(spec) != self._preview_key:
            self._status_var.set("Interaction changed; preview again before approval")
            return False
        if not self._messagebox.askyesno(
            "Approve Semantic Lab interaction",
            "Approve this typed interaction and write its canonical source plus generated Lua/EN/TL artifacts?",
        ):
            self._status_var.set("Approval cancelled; preview remains unchanged")
            return False
        self._approved_key = self._preview_key
        self._status_var.set("Interaction approved; generation is enabled.")
        return True

    def generate(self) -> None:
        try:
            spec = self._spec()
        except ValueError as error:
            self._status_var.set(str(error))
            return
        if not self._approved_key or self._approved_key != self._key(spec):
            self._status_var.set("Approve the current generated preview first")
            return
        self._on_generate(spec)

    def show_generation(self, report: dict[str, Any]) -> None:
        self._set_report(report)
        self._last_preview = report
        self._approved_key = None
        if report.get("ok") is True:
            self._status_var.set(
                "Canonical source and artifacts generated; Lua worker restart requested."
            )
        else:
            self._status_var.set("Generation failed; no worker restart was requested.")

    def _set_report(self, value: Any) -> None:
        self._report.configure(state="normal")
        self._report.delete("1.0", "end")
        self._report.insert("1.0", json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
        self._report.configure(state="disabled")

    def set_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        for button in self._buttons:
            button.configure(state=state)
        self._action_box.configure(state="readonly" if enabled else "disabled")
