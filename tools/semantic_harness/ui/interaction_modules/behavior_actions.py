"""Behavior structural promotion and Dialogue Content bridge actions."""

from __future__ import annotations

import json
from typing import Any

from .model import _behavior_content_refs


class BehaviorActionsMixin:
    def _behavior_promotion_payload(
        self,
    ) -> tuple[str, dict[str, Any], str | None] | None:
        value = self._behavior_json()
        canonical = self._behavior_canonical_source
        if value is None:
            return None
        if not isinstance(canonical, dict):
            self._messagebox.showerror(
                "Behavior promotion",
                "Select an existing canonical behavior before promotion.",
            )
            return None
        record_id = str(canonical.get("id") or "")
        if value.get("id") != record_id:
            self._messagebox.showerror(
                "Behavior promotion",
                "Behavior ID no longer matches the canonical source record.",
            )
            return None
        fingerprint = str(canonical.get("sourceFingerprint") or "") or None
        return record_id, value, fingerprint

    def preview_behavior_promotion(self) -> None:
        payload = self._behavior_promotion_payload()
        if payload is not None:
            self._on_preview_promotion(*payload)

    def promote_behavior_canonical(self) -> None:
        payload = self._behavior_promotion_payload()
        if payload is None:
            return
        record_id, value, fingerprint = payload
        if not self._messagebox.askyesno(
            "Promote canonical behavior",
            f"Write structural behavior {record_id} through CodeBuilder? "
            "Dialogue wording remains owned by Dialogue Content.",
        ):
            return
        self._on_promote(record_id, value, fingerprint)

    def open_behavior_content(self, kind: str) -> None:
        value = self._behavior_json()
        if value is None:
            return
        refs = _behavior_content_refs(value)
        content_id = refs.get(kind)
        if not content_id:
            self._messagebox.showinfo(
                "Interaction content",
                f"This behavior has no {kind} Dialogue Content reference.",
            )
            return
        self._on_open_content(content_id)

    def _behavior_json(self) -> dict[str, Any] | None:
        try:
            value = json.loads(
                self.behavior_text.get("1.0", "end").strip() or "{}"
            )
            if not isinstance(value, dict):
                raise ValueError("Behavior must be a JSON object.")
            return value
        except Exception as exc:
            self._messagebox.showerror("Behavior draft", str(exc))
            return None

    def validate_behavior(self) -> None:
        value = self._behavior_json()
        if value is not None:
            self._on_validate_behavior(value)

    def register_behavior(self) -> None:
        value = self._behavior_json()
        if value is not None:
            self._on_register_behavior(value)

    def show_behavior_validation(self, result: dict[str, Any]) -> None:
        self._set_preview(result)
        self.behavior_status_var.set(
            "Behavior valid"
            if result.get("valid")
            else f"Behavior invalid · {result.get('reason', 'unknown')}"
        )

    def show_behavior_registration(self, result: dict[str, Any]) -> None:
        self._set_preview(result)
        if result.get("registered"):
            self.set_catalog(result)
            self.behavior_status_var.set("Behavior registered in worker")
        else:
            self.behavior_status_var.set(
                f"Behavior registration failed · {result.get('reason', 'unknown')}"
            )
