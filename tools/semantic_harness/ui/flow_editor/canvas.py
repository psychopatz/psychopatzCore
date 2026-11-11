"""Canvas interaction and rendering controller for the Flow Editor pane."""

from __future__ import annotations

from typing import Any

from .model import (
    graph_transform,
    graph_inverse,
    graph_render_mode,
    flow_display_name,
    flow_graph_model,
    conversation_graph_model,
)


class FlowEditorCanvasController:
    """Own canvas projection and pointer interaction while preserving pane state."""

    def __init__(self, pane: Any) -> None:
        object.__setattr__(self, "pane", pane)

    def __getattr__(self, name: str) -> Any:
        return getattr(self.pane, name)

    def __setattr__(self, name: str, value: Any) -> None:
        if name == "pane":
            object.__setattr__(self, name, value)
            return
        setattr(self.pane, name, value)

    def _canvas_point(self, event: Any) -> tuple[float, float]:
        canvasx = getattr(self.canvas, "canvasx", None)
        canvasy = getattr(self.canvas, "canvasy", None)
        return (
            float(canvasx(event.x) if canvasx else event.x),
            float(canvasy(event.y) if canvasy else event.y),
        )

    def _on_mouse_wheel(self, event: Any) -> None:
        delta = getattr(event, "delta", 0)
        self._zoom_at(event, 1.12 if delta > 0 else 1 / 1.12)

    def _zoom_at(self, event: Any, factor: float) -> None:
        point = self._canvas_point(event)
        old_zoom = self._zoom
        new_zoom = max(0.35, min(2.5, old_zoom * factor))
        if new_zoom == old_zoom:
            return
        model_point = graph_inverse(point, old_zoom, self._pan)
        self._zoom = new_zoom
        self._pan = (
            point[0] - model_point[0] * new_zoom,
            point[1] - model_point[1] * new_zoom,
        )
        self.zoom_button.configure(text=f"{round(new_zoom * 100):d}%")
        self._draw_graph()

    def _start_pan(self, event: Any) -> None:
        self._pan_anchor = self._canvas_point(event)
        self._pan_origin = self._pan

    def _drag_pan(self, event: Any) -> None:
        if self._pan_anchor is None or self._pan_origin is None:
            return
        point = self._canvas_point(event)
        self._pan = (
            self._pan_origin[0] + point[0] - self._pan_anchor[0],
            self._pan_origin[1] + point[1] - self._pan_anchor[1],
        )
        self._draw_graph()

    def _stop_pan(self, _event: Any) -> None:
        self._pan_anchor = None
        self._pan_origin = None

    def _node_id_at(self, event: Any) -> str | None:
        """Resolve a left-click to a node without relying on item bindings."""

        point = self._canvas_point(event)
        items = self.canvas.find_overlapping(
            point[0] - 2, point[1] - 2, point[0] + 2, point[1] + 2,
        )
        for item_id in reversed(items):
            for tag in self.canvas.gettags(item_id):
                if tag.startswith("node:"):
                    return tag[5:]
        return None

    def _edge_id_at(self, event: Any) -> str | None:
        """Resolve a graph edge tag without changing Flow Editor selection."""

        point = self._canvas_point(event)
        items = self.canvas.find_overlapping(
            point[0] - 5, point[1] - 5, point[0] + 5, point[1] + 5,
        )
        for item_id in reversed(items):
            for tag in self.canvas.gettags(item_id):
                if tag.startswith("edge:"):
                    return tag[5:]
        return None

    def _on_canvas_left_down(self, event: Any) -> None:
        edge_id = self._edge_id_at(event)
        handler = getattr(self.pane, "handle_graph_click", None)
        if edge_id is not None and callable(handler):
            handler(edge_id)
            return
        node_id = self._node_id_at(event)
        if node_id is not None:
            self._start_node_drag(event, node_id)

    def _start_node_drag(self, event: Any, node_id: str) -> None:
        self._select_node(node_id)
        self._drag_node = node_id
        self._drag_anchor = graph_inverse(self._canvas_point(event), self._zoom, self._pan)
        self._drag_origin = self._node_positions.get(node_id, self._drag_anchor)

    def _drag_node_motion(self, event: Any) -> None:
        if not self._drag_node or self._drag_anchor is None:
            return
        current = graph_inverse(self._canvas_point(event), self._zoom, self._pan)
        origin = self._drag_origin or self._drag_anchor
        self._node_positions[self._drag_node] = (
            origin[0] + current[0] - self._drag_anchor[0],
            origin[1] + current[1] - self._drag_anchor[1],
        )
        self._draw_graph()

    def _stop_node_drag(self, _event: Any) -> None:
        self._drag_node = None
        self._drag_anchor = None
        self._drag_origin = None

    def reset_zoom(self) -> None:
        self._zoom = 1.0
        self._pan = (24.0, 42.0)
        self.zoom_button.configure(text="100%")
        self._draw_graph()

    def fit_graph(self) -> None:
        if not self._node_positions:
            return
        width = max(1.0, float(self.canvas.winfo_width() or 680))
        height = max(1.0, float(self.canvas.winfo_height() or 560))
        min_x = min(point[0] for point in self._node_positions.values())
        min_y = min(point[1] for point in self._node_positions.values())
        box_height = float(getattr(self, "graph_box_height", 82.0))
        max_x = max(point[0] + 245 for point in self._node_positions.values())
        max_y = max(point[1] + box_height for point in self._node_positions.values())
        self._zoom = max(0.35, min(2.5, min((width - 50) / (max_x - min_x), (height - 70) / (max_y - min_y))))
        self._pan = (
            (width - (max_x - min_x) * self._zoom) / 2 - min_x * self._zoom,
            (height - (max_y - min_y) * self._zoom) / 2 - min_y * self._zoom,
        )
        self.zoom_button.configure(text=f"{round(self._zoom * 100):d}%")
        self._draw_graph()

    def _draw_graph(self) -> None:
        self.canvas.delete("all")
        if not self._draft:
            self.graph_hint_var.set("Select a production flow")
            self.canvas.configure(scrollregion=(0, 0, 720, 600))
            return
        try:
            model = (
                self.pane.graph_model()
                if callable(getattr(self.pane, "graph_model", None))
                else flow_graph_model(self._draft)
            )
        except ValueError as error:
            self.graph_hint_var.set(str(error))
            self.canvas.configure(scrollregion=(0, 0, 720, 600))
            return

        is_authored_conversation = model.get("graphKind") == "conversation_block"
        is_runtime_graph = model.get("graphKind") in {
            "conversation_block", "semantic_flow", "semantic_hub",
        }
        is_conversation = is_runtime_graph
        display_name = (
            str(model.get("title") or model.get("blockID") or "ConversationBlock")
            if is_runtime_graph
            else flow_display_name(model["flowID"], self._draft)
        )
        workflow = (
            f"  ·  {model['workflowKind']}"
            if not is_conversation
            and model.get("generated") and model.get("workflowKind")
            else ""
        )
        if is_authored_conversation:
            self.graph_hint_var.set(
                f"{display_name}  ·  {model.get('categoryID') or ''}  ·  "
                f"{len(model['nodes'])} authored nodes  ·  "
                f"zoom {round(self._zoom * 100)}%  ·  middle-drag map"
            )
        elif is_runtime_graph:
            self.graph_hint_var.set(
                f"{display_name}  ·  {model.get('graphKind')}  ·  "
                f"{len(model['nodes'])} runtime nodes  ·  "
                f"zoom {round(self._zoom * 100)}%  ·  middle-drag map"
            )
        else:
            self.graph_hint_var.set(
                f"{display_name}{workflow}  ·  triggers {len(model['triggers'])}  ·  "
                f"zoom {round(self._zoom * 100)}%  ·  left-drag nodes · middle-drag map"
            )
        nodes = model["nodes"]
        box_width = 245.0
        box_height = float(getattr(self, "graph_box_height", 150.0 if is_conversation else 82.0))
        render_mode = graph_render_mode(self._zoom)
        # Geometry is zoomed, but text must remain legible and stay inside the
        # now-smaller node rectangle.  At low zoom the graph is intentionally
        # an overview: branches remain visible while secondary metadata is
        # omitted until the user zooms back in.
        font_size = max(7, min(16, int(round(11 * self._zoom))))
        small_font_size = max(6, font_size - 1)
        padding = max(4.0, 10.0 * self._zoom)
        title_gap = max(9.0, 34.0 * self._zoom)
        status_gap = max(18.0, 59.0 * self._zoom)
        edge_aliases = {
            "next": "N",
            "onMatch": "M",
            "onRefuse": "R",
            "onUnrelated": "U",
            "onPass": "P",
            "onFail": "F",
            "onUnknown": "?",
        }

        def edge_color(field: str, edge: dict[str, Any]) -> str:
            if is_conversation:
                return {
                    "available": "#78c091",
                    "locked": "#e18d83",
                    "future": "#66727f",
                    "root_exit": "#e7c56d",
                    "completed": "#b58bd4",
                }.get(str(edge.get("state") or "future"), "#6fa8dc")
            if field == "onPass":
                return "#78c091"
            if field == "onFail":
                return "#e18d83"
            if field == "onUnknown":
                return "#e7c56d"
            if field.startswith("result:"):
                outcome = field.split(":", 1)[1]
                return {
                    "queued": "#78c091",
                    "rejected": "#e18d83",
                    "failed": "#d99b7b",
                }.get(outcome, "#b58bd4")
            return "#6fa8dc"

        def compact_text(value: Any, max_chars: int) -> str:
            text = str(value)
            if len(text) <= max_chars:
                return text
            if max_chars <= 1:
                return "…"
            return text[:max_chars - 1] + "…"

        def text_capacity(width: float, size: int) -> int:
            # Tk's default font is approximately 0.6em wide for these labels.
            return max(1, int(max(1.0, width - (padding * 2)) / (size * 0.6)))

        positions: dict[str, tuple[float, float]] = {}
        if is_conversation:
            levels: dict[str, int] = {str(model.get("initial")): 0}
            pending = [str(model.get("initial"))]
            while pending:
                source = pending.pop(0)
                for edge in model["edges"]:
                    if edge["fromNodeID"] != source or not edge.get("internal"):
                        continue
                    target = edge["toNodeID"]
                    if target not in levels:
                        levels[target] = levels[source] + 1
                        pending.append(target)
            grouped: dict[int, list[str]] = {}
            for node in nodes:
                node_id = str(node["id"])
                grouped.setdefault(levels.get(node_id, 0), []).append(node_id)
            for level, node_ids in grouped.items():
                for index, node_id in enumerate(sorted(node_ids)):
                    positions[node_id] = (
                        500 + (index - (len(node_ids) - 1) / 2) * 330,
                        42 + level * 190,
                    )
        for index, node in enumerate(nodes):
            if node["id"] in self._node_positions:
                positions[node["id"]] = self._node_positions[node["id"]]
            elif node["id"] not in positions:
                positions[node["id"]] = (70 + (index % 3) * 330, 82 + (index // 3) * 150)
        self._node_positions = positions

        def screen(point: tuple[float, float]) -> tuple[float, float]:
            return graph_transform(point, self._zoom, self._pan)

        for edge_index, edge in enumerate(model["edges"]):
            source = positions.get(edge["fromNodeID"])
            target = positions.get(edge["toNodeID"])
            color = edge_color(edge["field"], edge)
            if source and target:
                if target[0] >= source[0]:
                    start = (source[0] + box_width, source[1] + box_height / 2)
                    finish = (target[0], target[1] + box_height / 2)
                else:
                    start = (source[0], source[1] + box_height / 2)
                    finish = (target[0] + box_width, target[1] + box_height / 2)
                sx, sy = screen(start)
                tx, ty = screen(finish)
                lane = (edge_index % 3 - 1) * 10 * self._zoom
                edge_tags = (
                    (f"edge:{edge['id']}",)
                    if is_conversation and edge.get("id") else ()
                )
                self.canvas.create_line(
                    sx, sy, (sx + tx) / 2 + lane, (sy + ty) / 2 + lane, tx, ty,
                    fill=color, arrow="last", width=max(1, int(2 * self._zoom)),
                    tags=edge_tags,
                )
                if is_conversation or render_mode != "overview":
                    label = (
                        edge.get("label") or edge.get("choiceID") or edge["field"]
                        if is_conversation
                        else edge["field"] if render_mode == "detail"
                        else edge_aliases.get(edge["field"], "R")
                    )
                    self.canvas.create_text(
                        (sx + tx) / 2 + lane, (sy + ty) / 2 + lane,
                        fill=color, text=label, font=("TkDefaultFont", small_font_size),
                    )
            elif source:
                # Exit branches leave the card in their own vertical lane so
                # their labels never sit on top of a neighboring node.
                source_exits = sum(
                    1 for prior in model["edges"][:edge_index]
                    if prior["fromNodeID"] == edge["fromNodeID"]
                    and not prior["internal"]
                )
                lane_offset = (-1 if source_exits % 2 == 0 else 1) * (
                    box_height / 2 + 24 + (source_exits // 2) * 26
                )
                start = (source[0] + box_width, source[1] + box_height / 2)
                end = (
                    source[0] + box_width + 90,
                    source[1] + box_height / 2 + lane_offset,
                )
                sx, sy = screen(start)
                tx, ty = screen(end)
                edge_tags = (
                    (f"edge:{edge['id']}",)
                    if is_conversation and edge.get("id") else ()
                )
                self.canvas.create_line(
                    sx, sy, tx, ty, fill="#ffb4ab",
                    arrow="last", width=max(1, int(2 * self._zoom)),
                    tags=edge_tags,
                )
                if is_conversation or render_mode != "overview":
                    field = edge["field"] if render_mode == "detail" else edge_aliases.get(edge["field"], "R")
                    if is_conversation:
                        field = edge.get("label") or edge.get("choiceID") or field
                    target = compact_text(edge["toNodeID"], 12 if render_mode == "compact" else 24)
                    self.canvas.create_text(
                        tx + max(4.0, 8.0 * self._zoom), ty, anchor="w", fill="#ffb4ab",
                        text=f"{field} → {target}", font=("TkDefaultFont", small_font_size),
                    )

        for node in nodes:
            x, y = screen(positions[node["id"]])
            width = box_width * self._zoom
            height = box_height * self._zoom
            selected = node["id"] == self._selected_node
            if is_conversation:
                state = str(node.get("state") or "future")
                state_colors = {
                    "current": ("#604d2a", "#f0c674"),
                    "available": ("#214d3b", "#78c091"),
                    "locked": ("#542d35", "#e18d83"),
                    "visited": ("#243d58", "#6fa8dc"),
                    "completed": ("#3b2850", "#b58bd4"),
                    "future": ("#202b36", "#66727f"),
                }
                fill, outline = state_colors.get(state, state_colors["future"])
                if selected:
                    fill, outline = "#604d2a", "#f0c674"
                tag = f"node:{node['id']}"
                self.canvas.create_rectangle(
                    x, y, x + width, y + height,
                    fill=fill, outline=outline,
                    width=max(1, int(2 * self._zoom)), tags=(tag,),
                )
                title_chars = text_capacity(width, font_size)
                title = compact_text(node.get("title") or node["id"], title_chars)
                # Conversation cards prioritize authored dialogue over
                # canonical IDs. Let Tk wrap the localized NPC text inside
                # the card instead of replacing it with an ellipsis.
                text = str(node.get("npcText") or "")
                choices = []
                for choice in node.get("choices") or []:
                    label = str(choice.get("text") or choice.get("id") or "")
                    choices.append(("[locked] " if choice.get("locked") else "[available] ") + label)
                choice_text = compact_text("  ".join(choices), title_chars * 2)
                self.canvas.create_text(
                    x + padding, y + padding, anchor="nw", fill="#ffffff",
                    text=title, font=("TkDefaultFont", font_size),
                    width=max(1, width - padding * 2), tags=(tag,),
                )
                self.canvas.create_text(
                    x + padding, y + title_gap, anchor="nw", fill="#d7e0e8",
                    text=text, font=("TkDefaultFont", small_font_size),
                    width=max(1, width - padding * 2), tags=(tag,),
                )
                self.canvas.create_text(
                    x + padding, y + max(74.0, status_gap), anchor="nw",
                    fill="#9bd3ae", text=compact_text(
                        f"{state.upper()} · {choice_text}", title_chars * 2
                    ), font=("TkDefaultFont", small_font_size),
                    width=max(1, width - padding * 2), tags=(tag,),
                )
                continue
            fill = "#604d2a" if selected else "#202b36"
            outline = "#f0c674" if selected else "#6fa8dc"
            if node["terminal"] and not selected:
                fill = "#1f473d"
            tag = f"node:{node['id']}"
            self.canvas.create_rectangle(
                x, y, x + width, y + height,
                fill=fill, outline=outline, width=max(1, int(2 * self._zoom)),
                tags=(tag,),
            )
            gate = node.get("gate") or {}
            gate_label = gate.get("fact") or gate.get("type") or "no gate"
            suffix = "terminal" if node["terminal"] else f"accepts {len(node['accepts'])}"
            title_chars = text_capacity(width, font_size)
            self.canvas.create_text(
                x + padding, y + padding, anchor="nw", fill="#ffffff",
                text=compact_text(node["id"], title_chars),
                font=("TkDefaultFont", font_size), width=max(1, width - padding * 2),
                tags=(tag,),
            )
            if render_mode == "overview":
                status = "T" if node["terminal"] else f"A{len(node['accepts'])}"
                if gate:
                    status += " · G"
                self.canvas.create_text(
                    x + padding, y + status_gap, anchor="nw", fill="#9bd3ae",
                    text=status, font=("TkDefaultFont", small_font_size),
                    width=max(1, width - padding * 2), tags=(tag,),
                )
            else:
                pool = node.get("responsePool") or node.get("responseTemplate") or "no response pool"
                pool_chars = text_capacity(width, small_font_size)
                self.canvas.create_text(
                    x + padding, y + title_gap, anchor="nw", fill="#b9c8d6",
                    text=compact_text(pool, pool_chars),
                    font=("TkDefaultFont", small_font_size), width=max(1, width - padding * 2),
                    tags=(tag,),
                )
                action = node.get("action") if isinstance(node.get("action"), dict) else {}
                action_label = action.get("capabilityID") or action.get("route")
                suffix = f"{suffix} · {action_label}" if action_label else suffix
                suffix_chars = text_capacity(width, small_font_size)
                self.canvas.create_text(
                    x + padding, y + status_gap, anchor="nw", fill="#9bd3ae",
                    text=compact_text(f"{suffix} · {gate_label}", suffix_chars),
                    font=("TkDefaultFont", small_font_size), width=max(1, width - padding * 2),
                    tags=(tag,),
                )
            if node["id"] == model["initial"]:
                self.canvas.create_text(
                    x - max(5.0, 10.0 * self._zoom), y + max(8.0, 16.0 * self._zoom),
                    anchor="e", fill="#f0c674", text="I" if render_mode == "overview" else "initial",
                    font=("TkDefaultFont", small_font_size),
                )

        width = max(720, int(max((screen((x + box_width, y + box_height))[0] for x, y in positions.values()), default=720) + 80))
        height = max(600, int(max((screen((x + box_width, y + box_height))[1] for x, y in positions.values()), default=600) + 80))
        self.canvas.configure(scrollregion=(-500, -300, width, height))
