"""Coordinate relationship preview projection and async worker updates."""

from __future__ import annotations

from concurrent.futures import Future
from typing import Any

from tools.semantic_harness.runtime.config import ConfigurationError
from tools.semantic_harness.process import HarnessError

def set_relationship_preview_from_projection(self) -> None:
    if self.relationship_preview_var is None:
        return
    proposal = self.simulation_projection.get("relationship", {})
    if not isinstance(proposal, dict):
        proposal = {}
    standing = str(proposal.get("standing") or "unknown").upper()
    reason = str(proposal.get("reason") or "production resolver")
    bond = proposal.get("bond") or {}
    bond_class = bond.get("class") if isinstance(bond, dict) else "none"
    self.relationship_preview_var.set(
        f"Live preview: {standing} · {reason} · durable bond: {bond_class or 'none'}"
    )

def on_relationship_slider_changed(self, *_args: Any) -> None:
    if self.closed or not self.worker_ready or self.busy:
        return
    # The field dirty callback already coalesces this edit into the one
    # production CONFIG boundary. A second preview request used to race
    # that CONFIG and made slider edits look stale while adding latency.
    self._schedule_workbench_auto_apply()
    if self.auto_replay_var is not None and self.auto_replay_var.get():
        if self._auto_replay_after is not None:
            try:
                self.root.after_cancel(self._auto_replay_after)
            except self._tk.TclError:
                pass
        self._auto_replay_after = self.root.after(
            650, self.apply_and_replay
        )

def request_relationship_preview(self) -> None:
    self._relationship_preview_after = None
    if self.closed or not self.worker_ready or self.busy:
        return
    if self._relationship_preview_future is not None:
        if not self._relationship_preview_future.done():
            self._relationship_preview_after = self.root.after(
                140, self._request_relationship_preview
            )
            return
    values = {}
    for key in ("approval", "respect", "familiarity"):
        field = self.workbench_control_fields.get(f"relationship.{key}")
        if field is not None:
            values[key] = field.get_value()
    try:
        future = self.session.submit(
            lambda worker: worker.relationship_preview(values)
        )
    except (HarnessError, RuntimeError):
        return
    self._relationship_preview_future = future
    self._poll_relationship_preview(future)

def poll_relationship_preview(self, future: Future[Any]) -> None:
    if self.closed:
        return
    if not future.done():
        self.root.after(25, self._poll_relationship_preview, future)
        return
    try:
        result = future.result()
        value = result.value if hasattr(result, "value") else result
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        self._set_text(self.trace, str(error))
        return
    preview = value if isinstance(value, dict) else {}
    if self.relationship_preview_var is not None:
        standing = str(preview.get("standing") or "unknown").upper()
        reason = str(preview.get("reason") or "production resolver")
        bond = preview.get("bond") or {}
        bond_class = bond.get("class") if isinstance(bond, dict) else "none"
        self.relationship_preview_var.set(
            f"Live preview: {standing} · {reason} · durable bond: {bond_class or 'none'}"
        )
    self._set_relationship_preview_fields(preview)

def set_relationship_preview_fields(self, preview: dict[str, Any]) -> None:
    relationship = {
        "approval": preview.get("approval"),
        "respect": preview.get("respect"),
        "familiarity": preview.get("familiarity"),
    }
    proposal = preview.get("proposal") or {}
    if isinstance(proposal, dict):
        proposal = dict(proposal)
        proposal["compatible"] = proposal.get("compatible")
        proposal["bond"] = preview.get("bond")
    projection = dict(self.simulation_projection)
    projection["relationship"] = {
        **(projection.get("relationship") or {}),
        **relationship,
        "standing": preview.get("standing"),
        "reason": preview.get("reason"),
        "bond": preview.get("bond"),
        "compatible": proposal.get("compatible") if isinstance(proposal, dict) else None,
        "eligible": proposal.get("eligible") if isinstance(proposal, dict) else None,
        "cooldownRemaining": proposal.get("cooldownRemaining") if isinstance(proposal, dict) else 0,
        "thresholds": proposal.get("thresholds") if isinstance(proposal, dict) else {},
    }
    self.simulation_projection = projection
    try:
        for control_id in (
            "relationship.state",
            "relationship.bond",
            "relationship.friendBondProgress",
            "relationship.romanceCompatibility",
            "relationship.proposalThreshold",
            "relationship.proposalCooldown",
            "relationship.proposalAvailable",
        ):
            field = self.workbench_control_fields.get(control_id)
            control = next(
                (item for item in self.workbench_controls if item.get("id") == control_id),
                None,
            )
            if field is not None and control is not None:
                field.set_value(self._scenario_control_value(control, self.scenario))
    finally:
        self.simulation_projection = projection


__all__ = [
    "on_relationship_slider_changed",
    "poll_relationship_preview",
    "request_relationship_preview",
    "set_relationship_preview_fields",
    "set_relationship_preview_from_projection",
]
