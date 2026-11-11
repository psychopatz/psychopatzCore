"""Request and render bounded production World Knowledge evidence."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.inspection.rendering import pretty
from ..inspection.world_knowledge import build_world_knowledge_inspector


def inspect_world_knowledge(app: Any) -> None:
    """Render bounded World Knowledge evidence from the live Lua worker."""

    if not app.session.ready or app.busy:
        return
    npc = app.scenario.get("npc", {})
    actor_id = npc.get("coreActorID") or npc.get("actorID")

    def finish(response: dict[str, Any]) -> None:
        view = build_world_knowledge_inspector(response)
        app._set_text(app.world_knowledge_inspector, pretty(view))
        app.trace_tabs.select(app.world_knowledge_frame)
        app._append(
            "SYSTEM",
            "World Knowledge inspection refreshed from the production Lua worker.",
        )

    app._start_operation(
        lambda worker: worker.world_knowledge_inspect(actor_id=actor_id),
        finish,
    )
