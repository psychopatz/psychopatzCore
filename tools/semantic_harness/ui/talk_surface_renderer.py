"""Render native Talk choices and bounded production evidence."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from .suggestion_projection import npc_message_text


def render_talk_choices(app: Any, choices: Any) -> None:
    """Render the worker's production choice surface without reclassifying it."""

    if not isinstance(choices, list):
        choices = []
    for button in app.talk_choice_buttons:
        button.destroy()
    app.talk_choice_buttons = []
    visible = [
        choice
        for choice in choices
        if isinstance(choice, dict) and isinstance(choice.get("frame"), dict)
    ]
    if not visible:
        label = app._ttk.Label(
            app.talk_choices_frame,
            text="Start Talk to load the production landing choices.",
        )
        label.grid(row=0, column=0, columnspan=3, sticky="w", padx=6, pady=4)
        app.talk_choice_buttons.append(label)
        return
    for index, choice in enumerate(visible):
        frame = choice["frame"]
        text = str(
            choice.get("text")
            or choice.get("label")
            or frame.get("labelFallback")
            or frame.get("textFallback")
            or choice.get("id")
            or "choice"
        )
        button = app._ttk.Button(
            app.talk_choices_frame,
            text=text,
            command=lambda selected=frame: app._click_talk_choice(selected),
        )
        button.grid(
            row=index // 3,
            column=index % 3,
            sticky="ew",
            padx=3,
            pady=3,
        )
        if choice.get("enabled") is False:
            button.configure(state="disabled")
        app.talk_choice_buttons.append(button)


def format_talk_start(result: dict[str, Any]) -> str:
    start = result.get("start") or {}
    target = start.get("target") or {}
    opening = start.get("opening") or {}
    choices = opening.get("choices") or []
    lines = [
        "Native Talk parity",
        "",
        f"Target: {target.get('label') or 'unknown'}",
        f"Production target type: {target.get('targetType') or 'unknown'}",
        f"Tactical class: {target.get('tacticalClass') or 'unknown'}",
        f"Audience: {target.get('audience') or 'unknown'}",
        f"Route: {target.get('route') or 'unknown'}",
        f"Route reason: {target.get('routeReason') or 'unknown'}",
        f"Availability: {(target.get('availability') or {}).get('reason') or 'available'}",
        f"Hostile: {'yes' if target.get('hostile') else 'no'}",
        f"Hostile inline integration: {'available' if target.get('hostileInlineAvailable') else 'not loaded in worker'}",
        f"Relationship ID: {target.get('relationshipID') or 'unknown'}",
        f"Trader overlay: {'enabled' if ((start.get('integration') or {}).get('traderOverlay') or {}).get('enabled') else 'disabled'}",
        "",
        f"Opening node: {opening.get('nodeID') or 'unknown'}",
        "Opening flavor:",
    ]
    opening_messages = opening.get("messages") or []
    for message in opening_messages:
        if isinstance(message, dict) and message.get("speaker") == "npc":
            lines.append(f"  NPC: {npc_message_text(message)}")
    if not opening_messages:
        lines.append("  —")
    lines.append("Opening choices:")
    for choice in choices:
        if isinstance(choice, dict):
            status = "available" if choice.get("enabled") else "locked"
            lines.append(
                f"  - {choice.get('id') or 'unknown'} [{status}] "
                f"{choice.get('text') or choice.get('textKey') or ''}"
            )
    observation = result.get("observation") or {}
    lines.extend(
        (
            "",
            f"First response: {observation.get('npcResponse') or '—'}",
            f"Graph: {(observation.get('runtimeGraphPath') or {}).get('kind') or '—'}",
            "",
            "Production evidence:",
            pretty(
                {
                    "schema": result.get("schema"),
                    "start": start,
                    "observation": observation,
                }
            ),
        )
    )
    return "\n".join(lines)


def format_talk_matrix(result: dict[str, Any]) -> str:
    rows = result.get("rows") if isinstance(result, dict) else None
    if not isinstance(rows, list) or not rows:
        return pretty(result)
    lines = [
        f"Talk parity · {result.get('schema', 'production matrix')}",
        f"First utterance: {result.get('utterance') or 'hello'}",
        "",
        "Target | Production type | Audience | Route | Availability | Provider | NPC response | Graph",
        "-------|------------------|----------|-------|--------------|----------|---------------|------",
    ]
    for row in rows:
        if not isinstance(row, dict):
            continue
        target = row.get("target") or {}
        graph = row.get("runtimeGraphPath") or {}
        availability = target.get("availability") or {}
        integration = target.get("integration") or {}
        trader = integration.get("traderOverlay") or {}
        lines.append(
            " | ".join(
                (
                    str(target.get("label") or row.get("label") or "unknown"),
                    str(target.get("targetType") or "unknown"),
                    str(target.get("audience") or "unknown"),
                    str(target.get("route") or "unknown"),
                    str(availability.get("reason") or "available"),
                    "trader" if trader.get("enabled") else "—",
                    str(row.get("npcResponse") or "—").replace("\n", " ")[:72],
                    str(graph.get("kind") or "—"),
                )
            )
        )
        choices = row.get("semanticHubChoices") or []
        if choices:
            lines.append(
                "  choices: "
                + ", ".join(
                    str(item.get("label") or item.get("id"))
                    for item in choices[:6]
                    if isinstance(item, dict)
                )
            )
    lines.extend(("", "Production evidence:", pretty(result)))
    return "\n".join(lines)
