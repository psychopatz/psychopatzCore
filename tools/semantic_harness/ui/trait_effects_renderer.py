"""Render production trait and social-profile effects in the workbench."""

from __future__ import annotations

from typing import Any


def format_trait_effect_value(value: Any) -> str:
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return f"{value:+.2f}"
    return str(value)

def flatten_trait_effects(value: Any, prefix: str = "") -> list[str]:
    if not isinstance(value, dict):
        return [
            f"{prefix}: {format_trait_effect_value(value)}"
            if prefix
            else format_trait_effect_value(value)
        ]
    lines: list[str] = []
    for key in sorted(value, key=str):
        label = str(key).replace("_", " ")
        child_prefix = f"{prefix} · {label}" if prefix else label
        lines.extend(flatten_trait_effects(value[key], child_prefix))
    return lines

def write_trait_effects(app: Any, actor: str, lines: list[str]) -> None:
    rendered = "\n".join(lines)
    widget = app.trait_effects_widgets.get(actor)
    if widget is not None:
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", rendered)
        widget.configure(state="disabled")

def render_trait_effects(app: Any) -> None:
    npc_field = app.workbench_control_fields.get("persona.traits")
    selected_npc = npc_field.get_value() if npc_field is not None else []
    selected_npc = selected_npc if isinstance(selected_npc, list) else []
    definitions = {
        str(row.get("id")): row
        for row in app.persona_catalog.get("traits", [])
        if isinstance(row, dict) and row.get("id")
    }
    for definition in tuple(definitions.values()):
        for alias in definition.get("aliases") or []:
            definitions.setdefault(str(alias), definition)
    npc_lines = ["Production registry effects"]
    if not selected_npc:
        npc_lines.append("Select a registered trait to inspect its effects.")
    for trait_id in selected_npc[:8]:
        definition = definitions.get(str(trait_id))
        if not definition:
            npc_lines.append(f"{trait_id}: definition unavailable")
            continue
        label = str(definition.get("label") or trait_id)
        source = str(definition.get("source") or "production")
        npc_lines.append(f"{label} · source: {source}")
        effects = definition.get("effects")
        npc_lines.extend(
            f"  {line}"
            for line in flatten_trait_effects(effects, "effects")
        )
        speech = definition.get("speechStyle")
        if speech:
            npc_lines.extend(
                f"  {line}"
                for line in flatten_trait_effects(speech, "speech style")
            )
    if app.generated_personality_preview and selected_npc:
        values = app.generated_personality_preview
        shown = (
            "compassion",
            "sociability",
            "forgiveness",
            "bravery",
            "aggression",
        )
        preview = " · ".join(
            f"{key} {format_trait_effect_value(values[key])}"
            for key in shown
            if key in values
        )
        if preview:
            npc_lines.append(f"Generated personality preview: {preview}")
    write_trait_effects(app, "npc", npc_lines)

    player_field = app.workbench_control_fields.get("player.traits")
    selected_player = player_field.get_value() if player_field is not None else []
    selected_player = selected_player if isinstance(selected_player, list) else []
    player_projection = app.simulation_projection.get("player", {})
    if not isinstance(player_projection, dict):
        player_projection = {}
    player_profile = app.player_social_profile_preview or (
        player_projection.get("socialProfile")
        or app.persona_catalog.get("playerSocialProfile", {})
    )
    player_lines = ["Production-derived social profile"]
    if not selected_player:
        player_lines.append("Select registered player traits to preview their effects.")
    for key in (
        "orientation",
        "romanceStyle",
        "jealousyStyle",
        "socialStyle",
        "foodPreference",
    ):
        player_lines.append(f"{key}: {player_profile.get(key, 'unknown')}")
    if app.player_trait_fingerprint:
        player_lines.append(f"trait fingerprint: {app.player_trait_fingerprint}")
    if app.player_trait_conflicts:
        player_lines.append(
            "trait conflicts: "
            + ", ".join(str(item) for item in app.player_trait_conflicts[:4])
        )
    write_trait_effects(app, "player", player_lines)
