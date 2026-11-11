"""Catalog, selection, and structure projection actions."""

from __future__ import annotations

from copy import deepcopy
import json
from typing import Any

from .model import _behavior_content_refs, _flatten_predicate, _pretty


class CatalogActionsMixin:
    def set_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        for widget in (
            self.refresh_button,
            self.clone_button,
            self.new_button,
            self.open_button,
            self.save_button,
            self.validate_button,
            self.preview_button,
            self.register_button,
            self.review_promotion_button,
            self.promote_button,
            self.open_speech_content_button,
            self.open_flavor_content_button,
            self.review_behavior_button,
            self.promote_behavior_button,
        ):
            widget.configure(state=state)

    def set_catalog(self, response: dict[str, Any] | None) -> None:
        self._catalog = response if isinstance(response, dict) else {}
        self._beats = [
            deepcopy(item) for item in self._catalog.get("beats", [])
            if isinstance(item, dict)
        ]
        self._behaviors = [
            deepcopy(item) for item in self._catalog.get("behaviors", [])
            if isinstance(item, dict)
        ]
        self._beat_by_id = {
            str(item.get("id")): item for item in self._beats if item.get("id")
        }
        self._behavior_by_id = {
            str(item.get("id")): item
            for item in self._behaviors if item.get("id")
        }
        self.beat_list.delete(0, "end")
        for item in self._beats:
            self.beat_list.insert("end", str(item.get("id") or "?"))
        self.behavior_list.delete(0, "end")
        for item in self._behaviors:
            self.behavior_list.insert("end", str(item.get("id") or "?"))
        self._set_status(
            f"Loaded {len(self._beats)} situations and {len(self._behaviors)} behaviors.",
            "CATALOG",
        )
        if self._beats:
            self.beat_list.selection_set(0)
            self._beat_selected()

    def _set_status(self, text: str, kind: str | None = None) -> None:
        if kind is not None:
            self._status_kind = kind
            self.provenance_var.set(kind)
        self.status_var.set(text)

    def _beat_selected(self, _event: Any = None) -> None:
        selected = self.beat_list.curselection()
        if not selected or selected[0] >= len(self._beats):
            return
        value = deepcopy(self._beats[selected[0]])
        self._draft_source_id = str(value.get("id") or "")
        self._canonical_source = None
        try:
            canonical = self._on_load_canonical(self._draft_source_id)
            if isinstance(canonical, dict):
                self._canonical_source = canonical
        except Exception as exc:
            self._set_status(
                f"Loaded runtime beat, but canonical source lookup failed: {exc}",
                "CANONICAL_SOURCE_ERROR",
            )
        self._load_beat(value)
        fingerprint = (
            str(self._canonical_source.get("sourceFingerprint") or "")[:12]
            if isinstance(self._canonical_source, dict)
            else ""
        )
        self._set_status(
            f"Loaded canonical production beat {self._draft_source_id}"
            + (f" · source {fingerprint}" if fingerprint else ""),
            "CANONICAL",
        )

    def _behavior_selected(self, _event: Any = None) -> None:
        selected = self.behavior_list.curselection()
        if not selected or selected[0] >= len(self._behaviors):
            return
        value = deepcopy(self._behaviors[selected[0]])
        self._selected_behavior = value
        self._behavior_canonical_source = None
        try:
            canonical = self._on_load_canonical(str(value.get("id") or ""))
            if isinstance(canonical, dict):
                self._behavior_canonical_source = canonical
        except Exception:
            self._behavior_canonical_source = None
        self.behavior_text.delete("1.0", "end")
        self.behavior_text.insert("1.0", _pretty(value))
        refs = _behavior_content_refs(value)
        outputs = value.get("outputs") if isinstance(value.get("outputs"), dict) else {}
        self.behavior_status_var.set(
            " · ".join(
                [
                    f"Canonical behavior {value.get('id', '?')}",
                    f"mode={value.get('mode', '?')}",
                    "stimuli=" + ",".join(value.get("stimuli") or []),
                    "capabilities=" + ",".join(
                        value.get("requiredCapabilities") or []
                    ),
                    "outputs=" + ",".join(sorted(outputs)),
                    (
                        "content=" + ",".join(sorted(refs.values()))
                        if refs else "content=none"
                    ),
                ]
            )
        )
        self.open_speech_content_button.configure(
            state="normal" if "speech" in refs else "disabled"
        )
        self.open_flavor_content_button.configure(
            state="normal" if "flavor" in refs else "disabled"
        )
        can_promote = isinstance(self._behavior_canonical_source, dict)
        self.review_behavior_button.configure(
            state="normal" if can_promote else "disabled"
        )
        self.promote_behavior_button.configure(
            state="normal" if can_promote else "disabled"
        )

    def _load_beat(self, value: dict[str, Any]) -> None:
        self.beat_id_var.set(str(value.get("id") or ""))
        self.owner_var.set(str(value.get("owner") or "ProjectHoomans"))
        self.group_var.set(str(value.get("group") or ""))
        self.stimuli_var.set(", ".join(value.get("stimuli") or []))
        self.relevance_var.set(str(value.get("baseRelevance", 0.5)))
        self.max_turns_var.set(str(value.get("maxTurns", 0)))
        self.cooldown_var.set(str(value.get("cooldownTurns", 0)))
        for name in ("entry", "maintain", "exit"):
            _tree, raw = self.predicate_widgets[name]
            raw.delete("1.0", "end")
            raw.insert("1.0", _pretty(value.get(name) or {}))
            self._refresh_predicate_tree(name)
        self.candidates_text.delete("1.0", "end")
        self.candidates_text.insert(
            "1.0", _pretty(value.get("candidates") or [])
        )
        self._refresh_candidate_tree()
        self.raw_beat.delete("1.0", "end")
        self.raw_beat.insert("1.0", _pretty(value))

    def _json_from(self, widget: Any, label: str) -> Any:
        raw = widget.get("1.0", "end").strip()
        try:
            return json.loads(raw or "{}")
        except json.JSONDecodeError as exc:
            raise ValueError(f"{label}: {exc.msg} at line {exc.lineno}") from exc

    def collect_draft(self) -> dict[str, Any]:
        candidates = self._json_from(self.candidates_text, "Candidates")
        if not isinstance(candidates, list):
            raise ValueError("Candidates must be a JSON list.")
        stimuli = [
            item.strip()
            for item in self.stimuli_var.get().split(",")
            if item.strip()
        ]
        if not stimuli:
            raise ValueError("At least one typed stimulus is required.")
        result: dict[str, Any] = {
            "id": self.beat_id_var.get().strip(),
            "version": 1,
            "owner": self.owner_var.get().strip() or "SemanticLab",
            "stimuli": stimuli,
            "entry": self._json_from(
                self.predicate_widgets["entry"][1], "Entry"
            ),
            "maintain": self._json_from(
                self.predicate_widgets["maintain"][1], "Maintain"
            ),
            "exit": self._json_from(
                self.predicate_widgets["exit"][1], "Exit"
            ),
            "candidates": candidates,
            "baseRelevance": float(self.relevance_var.get().strip()),
            "maxTurns": int(self.max_turns_var.get().strip()),
            "cooldownTurns": int(self.cooldown_var.get().strip()),
        }
        group = self.group_var.get().strip()
        if group:
            result["group"] = group
        return result

    def _refresh_predicate_tree(self, name: str) -> None:
        tree, raw = self.predicate_widgets[name]
        tree.delete(*tree.get_children())
        try:
            value = json.loads(raw.get("1.0", "end").strip() or "{}")
            rows = _flatten_predicate(value)
        except Exception as exc:
            rows = [("root", "INVALID", str(exc))]
        for node, condition, expected in rows:
            tree.insert("", "end", text=node, values=(condition, expected))

    def _candidate_behavior_selected(self, _event: Any = None) -> None:
        selected = self.candidate_tree.selection()
        if not selected:
            return
        behavior_id = str(self.candidate_tree.item(selected[0], "text") or "")
        if behavior_id and behavior_id != "?":
            self.select_behavior(behavior_id)

    def select_behavior(self, behavior_id: str) -> bool:
        for index, item in enumerate(self._behaviors):
            if item.get("id") == behavior_id:
                self.behavior_list.selection_clear(0, "end")
                self.behavior_list.selection_set(index)
                self.behavior_list.see(index)
                self._behavior_selected()
                return True
        return False

    def _refresh_candidate_tree(self) -> None:
        self.candidate_tree.delete(*self.candidate_tree.get_children())
        try:
            values = json.loads(
                self.candidates_text.get("1.0", "end").strip() or "[]"
            )
        except Exception:
            values = []
        if not isinstance(values, list):
            return
        for row in values:
            if isinstance(row, dict):
                self.candidate_tree.insert(
                    "",
                    "end",
                    text=str(row.get("behavior") or "?"),
                    values=(row.get("relevance"),),
                )
