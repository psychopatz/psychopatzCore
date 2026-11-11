"""Render projected social context and missing relationship state."""

from __future__ import annotations

def refresh_social_context_summary(self) -> None:
    if self.relationship_context_summary is None:
        return
    social = self.social_context_projection
    if not isinstance(social, dict) or not social:
        self._set_text(
            self.relationship_context_summary,
            "No production social context has been projected yet.",
        )
        return
    lines = self._social_context_lines(social)
    overrides = self.runtime_relationship_override_projection
    if isinstance(overrides, dict) and overrides:
        override = next(
            (
                item
                for item in overrides.values()
                if isinstance(item, dict)
            ),
            None,
        )
        if isinstance(override, dict):
            lines.extend(
                [
                    "Runtime-only relationship override",
                    f"  source {override.get('source') or 'MISSING'} · "
                    f"owner {override.get('owner') or 'MISSING'} · "
                    f"resettable={override.get('resettable', 'MISSING')}",
                ]
            )
    self._set_text(self.relationship_context_summary, "\n".join(lines))


def refresh_relationship_missing_state(self) -> None:
    """Mark save-backed relationship controls when production data is absent."""

    personal = self.social_context_projection.get("personalRelationship")
    personal = personal if isinstance(personal, dict) else {}
    missing = self.save_backed_mode and personal.get("source") == "MISSING"
    for control_id in (
        "relationship.approval",
        "relationship.respect",
        "relationship.familiarity",
    ):
        field = self.workbench_control_fields.get(control_id)
        if field is not None:
            field.set_missing_state(missing)



__all__ = ["refresh_social_context_summary", "refresh_relationship_missing_state"]
