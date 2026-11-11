"""Situation draft validation, preview, persistence, and promotion actions."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .model import _pretty


class DraftActionsMixin:
    def _set_preview(self, value: Any) -> None:
        self.preview_output.configure(state="normal")
        self.preview_output.delete("1.0", "end")
        self.preview_output.insert("1.0", _pretty(value))
        self.preview_output.configure(state="disabled")

    def _safe_draft(self) -> dict[str, Any] | None:
        try:
            value = self.collect_draft()
        except Exception as exc:
            self._messagebox.showerror("Beat draft", str(exc))
            return None
        self.raw_beat.delete("1.0", "end")
        self.raw_beat.insert("1.0", _pretty(value))
        if self._status_kind == "CANONICAL":
            self._set_status(
                "Draft based on production. Validate or preview before registering.",
                "DRAFT_FROM_PRODUCTION",
            )
        return value

    def validate_draft(self) -> None:
        value = self._safe_draft()
        if value is not None:
            self._on_validate(value)

    def preview_draft(self) -> None:
        value = self._safe_draft()
        text = self.preview_text_var.get().strip()
        if value is None:
            return
        if not text:
            self._messagebox.showerror(
                "Beat preview", "Enter a preview utterance."
            )
            return
        self._on_preview(value, text)

    def register_draft(self) -> None:
        value = self._safe_draft()
        if value is not None:
            self._on_register(value)

    def show_validation(self, result: dict[str, Any]) -> None:
        self._set_preview(result)
        if result.get("valid"):
            self._set_status("Draft is valid in production Lua.", "DRAFT_VALID")
        else:
            self._set_status(
                f"Draft rejected: {result.get('reason', 'unknown')}",
                "DRAFT_INVALID",
            )

    def show_preview(self, result: dict[str, Any]) -> None:
        self._set_preview(result)
        if result.get("previewed"):
            selected = (result.get("draft") or {}).get("selectedBehavior") or {}
            self._set_status(
                "Draft previewed through production semantics"
                + (f" · {selected.get('id')}" if selected.get("id") else ""),
                "DRAFT_PREVIEW",
            )
        else:
            self._set_status(
                f"Preview unavailable: {result.get('reason') or result.get('error')}",
                "DRAFT_PREVIEW_FAILED",
            )

    def show_registration(self, result: dict[str, Any]) -> None:
        self._set_preview(result)
        if result.get("registered"):
            self.set_catalog(result)
            definition = result.get("definition") or {}
            beat_id = str(definition.get("id") or "")
            if beat_id:
                self.select_beat(beat_id)
            self._set_status(
                f"Worker-local beat registered: {beat_id}",
                "WORKER_REGISTERED",
            )
        else:
            self._set_status(
                f"Registration failed: {result.get('reason', 'unknown')}",
                "REGISTER_FAILED",
            )

    def select_beat(self, beat_id: str) -> None:
        for index, item in enumerate(self._beats):
            if item.get("id") == beat_id:
                self.beat_list.selection_clear(0, "end")
                self.beat_list.selection_set(index)
                self.beat_list.see(index)
                self._beat_selected()
                return

    def clone_selected(self) -> None:
        try:
            value = self.collect_draft()
        except Exception as exc:
            self._messagebox.showerror("Clone beat", str(exc))
            return
        source_id = str(value.get("id") or "beat.draft")
        value["id"] = source_id + ".draft"
        value["owner"] = "SemanticLab"
        self._draft_source_id = source_id
        self._canonical_source = None
        self._load_beat(value)
        self._set_status(
            f"Draft cloned from {source_id}.", "DRAFT_FROM_PRODUCTION"
        )

    def new_beat(self) -> None:
        behavior = next(
            (
                str(item.get("id"))
                for item in self._behaviors
                if item.get("mode") == "beat" and item.get("id")
            ),
            "behavior.warn",
        )
        value = {
            "id": "beat.lab_new",
            "version": 1,
            "owner": "SemanticLab",
            "group": "beat_group.social_primary",
            "stimuli": ["HUMAN_UTTERANCE"],
            "baseRelevance": 0.5,
            "entry": {
                "path": "stimulus.semantic.intent",
                "op": "eq",
                "value": "GREET",
            },
            "maintain": {"path": "scene.ended", "op": "falsy"},
            "exit": {"path": "beat.turnsInBeat", "op": "gte", "value": 2},
            "candidates": [{"behavior": behavior, "relevance": 0.5}],
            "maxTurns": 2,
            "cooldownTurns": 1,
        }
        self._draft_source_id = None
        self._canonical_source = None
        self._load_beat(value)
        self._set_status("New worker draft.", "DRAFT")

    def apply_raw_beat(self) -> None:
        try:
            value = self._json_from(self.raw_beat, "Raw beat")
            if not isinstance(value, dict):
                raise ValueError("Raw beat must be a JSON object.")
        except Exception as exc:
            self._messagebox.showerror("Raw beat", str(exc))
            return
        self._load_beat(value)
        self._set_status("Applied raw beat JSON to draft.", "DRAFT")

    def save_draft(self) -> None:
        value = self._safe_draft()
        if value is None:
            return
        path = self._filedialog.asksaveasfilename(
            title="Save beat draft",
            defaultextension=".json",
            filetypes=(("JSON", "*.json"), ("All files", "*.*")),
        )
        if not path:
            return
        Path(path).write_text(_pretty(value) + "\n", encoding="utf-8")
        self._set_status(f"Saved draft: {path}", self._status_kind)

    def open_draft(self) -> None:
        path = self._filedialog.askopenfilename(
            title="Open beat draft",
            filetypes=(("JSON", "*.json"), ("All files", "*.*")),
        )
        if not path:
            return
        try:
            value = json.loads(Path(path).read_text(encoding="utf-8"))
            if not isinstance(value, dict):
                raise ValueError("Draft must contain one JSON object.")
        except Exception as exc:
            self._messagebox.showerror("Open beat draft", str(exc))
            return
        self._draft_source_id = None
        self._canonical_source = None
        self._load_beat(value)
        self._set_status(f"Opened draft: {path}", "DRAFT")

    def _promotion_payload(
        self,
    ) -> tuple[str, dict[str, Any], str | None] | None:
        value = self._safe_draft()
        if value is None:
            return None
        canonical = self._canonical_source
        if not isinstance(canonical, dict):
            self._messagebox.showerror(
                "Canonical promotion",
                "Promotion is only available for a draft opened directly from "
                "an existing canonical beat. Save new/cloned drafts for review "
                "until canonical translations are authored.",
            )
            return None
        record_id = str(canonical.get("id") or "")
        if not record_id or value.get("id") != record_id:
            self._messagebox.showerror(
                "Canonical promotion",
                "The draft ID no longer matches its canonical source record.",
            )
            return None
        fingerprint = str(canonical.get("sourceFingerprint") or "") or None
        return record_id, value, fingerprint

    def preview_promotion(self) -> None:
        payload = self._promotion_payload()
        if payload is None:
            return
        self._on_preview_promotion(*payload)

    def promote_canonical(self) -> None:
        payload = self._promotion_payload()
        if payload is None:
            return
        record_id, value, fingerprint = payload
        if not self._messagebox.askyesno(
            "Promote canonical beat",
            f"Write {record_id} back through the canonical Conversation "
            "CodeBuilder source and regenerate its runtime/translation outputs?",
        ):
            return
        self._on_promote(record_id, value, fingerprint)

    def show_promotion_preview(self, result: dict[str, Any]) -> None:
        self._set_preview(result)
        if result.get("ok"):
            changed = result.get("changedGeneratedPaths") or []
            self._set_status(
                f"Canonical diff ready · {len(changed)} generated artifact(s) change.",
                "CANONICAL_REVIEW",
            )
        else:
            self._set_status(
                "Canonical review failed: "
                + str(result.get("reason") or result.get("diagnostics") or "unknown"),
                "CANONICAL_REVIEW_FAILED",
            )

    def show_promotion_result(self, result: dict[str, Any]) -> None:
        self._set_preview(result)
        if result.get("ok"):
            self._set_status(
                "Canonical source written and Conversation artifacts regenerated; "
                "reloading worker.",
                "CANONICAL_PROMOTED",
            )
        else:
            self._set_status(
                "Canonical promotion failed: "
                + str(result.get("reason") or result.get("diagnostics") or "unknown"),
                "CANONICAL_PROMOTION_FAILED",
            )
