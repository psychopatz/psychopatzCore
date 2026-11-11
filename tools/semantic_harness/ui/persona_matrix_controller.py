"""Production-backed persona and context comparison actions."""

from __future__ import annotations

from copy import deepcopy
from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from tools.semantic_harness.runtime.scenario import merge


def inspect_persona_matrix(app: Any) -> None:
    """Run a small production-backed persona A/B matrix in one worker."""

    if not app.session.ready or app.busy:
        return
    base = deepcopy(app.scenario)
    dimension = app.matrix_dimension_var.get() or "persona"
    rows = [
        merge(
            base,
            {"runtime": {"semanticLabMatrixLabel": f"A / baseline · {dimension}"}},
        )
    ]

    def add_relationship_variants(
        field: str, values: tuple[tuple[str, int], ...]
    ) -> None:
        rows.extend(
            merge(
                base,
                {
                    "runtime": {
                        "semanticLabMatrixLabel": f"{label} · {dimension}"
                    },
                    "npc": {"relationship": {field: value}},
                },
            )
            for label, value in values
        )

    if dimension == "approval":
        add_relationship_variants("approval", (("B / low", -80), ("C / high", 80)))
    elif dimension == "respect":
        add_relationship_variants("respect", (("B / low", -60), ("C / high", 70)))
    elif dimension == "familiarity":
        add_relationship_variants(
            "familiarity", (("B / low", 5), ("C / high", 100))
        )
    elif dimension == "bond":
        for label, relationship in (
            ("B / mother", {"relationshipKind": "mother"}),
            ("C / lover", {"relationshipKind": "lover"}),
        ):
            rows.append(
                merge(
                    base,
                    {
                        "runtime": {
                            "semanticLabMatrixLabel": f"{label} · {dimension}"
                        },
                        "npc": {"startingRelationship": relationship},
                    },
                )
            )
    elif dimension == "language":
        for label, language in (("B / EN", "EN"), ("C / TL", "TL")):
            rows.append(
                merge(
                    base,
                    {
                        "runtime": {
                            "semanticLabMatrixLabel": f"{label} · {dimension}",
                            "language": language,
                        }
                    },
                )
            )
    else:
        rows.extend(
            [
                merge(
                    base,
                    {
                        "runtime": {"semanticLabMatrixLabel": "B / warm · persona"},
                        "npc": {
                            "traits": ["pnc_friendly"],
                            "personality": {
                                "socialStyle": "friendly",
                                "compassion": 0.9,
                                "sociability": 0.9,
                                "aggression": 0.1,
                            },
                        },
                    },
                ),
                merge(
                    base,
                    {
                        "runtime": {
                            "semanticLabMatrixLabel": "C / guarded · persona"
                        },
                        "npc": {
                            "traits": ["pnc_reserved"],
                            "personality": {
                                "socialStyle": "withdrawn",
                                "compassion": 0.1,
                                "sociability": 0.2,
                                "aggression": 0.9,
                            },
                        },
                    },
                ),
            ]
        )

    value = app._comparison_utterance()
    app.compare_utterance_var.set(value)

    def finish(result: dict[str, Any]) -> None:
        app._set_text(app.compare_output, format_compare_result(result))
        app.trace_tabs.select(app.compare_frame)
        app.compare_tabs.select(app.compare_context_frame)
        app._append(
            "SYSTEM",
            f"Comparison by {dimension} completed through the real Lua worker: {value}",
        )

    app._start_operation(
        lambda worker: worker.context_matrix(rows, text=value, maximum=3),
        finish,
    )


def format_compare_result(result: dict[str, Any]) -> str:
    """Render the bounded matrix as an understandable A/B/C comparison."""

    rows = result.get("rows") if isinstance(result, dict) else None
    if not isinstance(rows, list) or not rows:
        return pretty(result)
    lines = [
        f"Compare · {result.get('schema', 'production matrix')}",
        "",
        "Case | NPC response | Standing | Durable bond | Speech style | Graph",
        "-----|---------------|----------|--------------|--------------|------",
    ]
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            continue
        relationship = row.get("relationship") or {}
        bond = relationship.get("bond") or {}
        speech = row.get("speechStyleContext") or {}
        graph = row.get("runtimeGraphPath") or {}
        label = row.get("label") or chr(ord("A") + index)
        response = str(row.get("npcResponse") or "").replace("\n", " ")
        style = str(speech.get("variant") or speech.get("schema") or "—")
        graph_kind = str(graph.get("kind") or "—")
        lines.append(
            " | ".join(
                (
                    str(label),
                    response[:80],
                    str(relationship.get("standing") or "unknown"),
                    str(bond.get("class") or "none"),
                    style,
                    graph_kind,
                )
            )
        )
        choices = row.get("semanticHubChoices") or []
        lines.append(
            f"  choices: {', '.join(str(item.get('label') or item.get('id')) for item in choices[:4] if isinstance(item, dict)) or 'none'}"
        )
    lines.extend(("", "Full production evidence:", pretty(result)))
    return "\n".join(lines)
