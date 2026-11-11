"""Read-only ConversationBlock graph view for the Simulation tab."""

from __future__ import annotations

import copy
from typing import Any

from .flow_editor.canvas import FlowEditorCanvasController
from .flow_editor.model import conversation_graph_diagnostics, conversation_graph_model


class ConversationGraphPane:
    """Render the live developer graph through the existing Flow canvas."""

    def __init__(
        self,
        parent: Any,
        tk_module: Any,
        ttk: Any,
        on_click: Any | None = None,
        on_diagnostics: Any | None = None,
    ) -> None:
        self._tk = tk_module
        self._ttk = ttk
        self._draft: dict[str, Any] | None = None
        self._selected_node: str | None = None
        self._node_positions: dict[str, tuple[float, float]] = {}
        self._zoom = 1.0
        self._pan = (24.0, 42.0)
        self._drag_node = None
        self._drag_anchor = None
        self._drag_origin = None
        self._pan_anchor = None
        self._pan_origin = None
        self.graph_box_height = 150.0
        self._fitted_graph_id: str | None = None
        self._on_click = on_click
        self._on_diagnostics = on_diagnostics
        self.frame = ttk.Frame(parent, padding=4)
        self.frame.grid(row=0, column=0, sticky="nsew")
        self.frame.rowconfigure(1, weight=1)
        self.frame.columnconfigure(0, weight=1)

        toolbar = ttk.Frame(self.frame)
        toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 4))
        toolbar.columnconfigure(0, weight=1)
        self.graph_hint_var = tk_module.StringVar(
            value=(
                "Runtime Flow, Hub, and ConversationBlock paths appear here."
            )
        )
        ttk.Label(toolbar, textvariable=self.graph_hint_var, anchor="w").grid(
            row=0, column=0, sticky="ew"
        )
        self.fit_button = ttk.Button(toolbar, text="Fit", command=self.fit_graph)
        self.fit_button.grid(row=0, column=1, padx=(6, 0))
        self.zoom_button = ttk.Button(
            toolbar, text="100%", command=self.reset_zoom
        )
        self.zoom_button.grid(row=0, column=2, padx=(4, 0))
        self.diagnostics_button = ttk.Button(
            toolbar, text="Diagnostics", command=self.show_diagnostics
        )
        self.diagnostics_button.grid(row=0, column=3, padx=(4, 0))
        self.clear_button = ttk.Button(
            toolbar, text="Clear graph", command=self.clear_graph
        )
        self.clear_button.grid(row=0, column=4, padx=(4, 0))

        graph_frame = ttk.Frame(self.frame)
        graph_frame.grid(row=1, column=0, sticky="nsew")
        graph_frame.rowconfigure(0, weight=1)
        graph_frame.columnconfigure(0, weight=1)
        self.canvas = tk_module.Canvas(
            graph_frame,
            width=720,
            height=600,
            background="#10151b",
            highlightthickness=0,
        )
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.canvas.bind("<MouseWheel>", self._on_mouse_wheel)
        self.canvas.bind("<Button-4>", lambda event: self._zoom_at(event, 1.12))
        self.canvas.bind("<Button-5>", lambda event: self._zoom_at(event, 1 / 1.12))
        self.canvas.bind("<Button-2>", self._start_pan)
        self.canvas.bind("<B2-Motion>", self._drag_pan)
        self.canvas.bind("<ButtonRelease-2>", self._stop_pan)
        self.canvas.bind("<Configure>", lambda _event: self._draw_graph())
        y_scroll = ttk.Scrollbar(graph_frame, orient="vertical", command=self.canvas.yview)
        y_scroll.grid(row=0, column=1, sticky="ns")
        x_scroll = ttk.Scrollbar(graph_frame, orient="horizontal", command=self.canvas.xview)
        x_scroll.grid(row=1, column=0, sticky="ew")
        self.canvas.configure(
            xscrollcommand=x_scroll.set,
            yscrollcommand=y_scroll.set,
        )
        self._canvas_controller = FlowEditorCanvasController(self)
        self.canvas.bind(
            "<Button-1>", self._canvas_controller._on_canvas_left_down
        )

    def graph_model(self) -> dict[str, Any]:
        if not self._draft:
            raise ValueError("No selected authored ConversationBlock")
        return conversation_graph_model(self._draft)

    def set_graph(self, graph: dict[str, Any] | None) -> None:
        graph = copy.deepcopy(graph) if isinstance(graph, dict) else None
        graph_id = graph and str(graph.get("graphID") or "") or None
        changed = graph_id != self._fitted_graph_id
        if graph_id != (self._draft or {}).get("graphID"):
            self._node_positions = {}
        self._draft = graph
        self._draw_graph()
        if graph is None:
            self._fitted_graph_id = None
            self.graph_hint_var.set(
                "No retained runtime dialogue graph."
            )
            return
        graph_kind = str(graph.get("graphKind") or "runtime")
        self.graph_hint_var.set(
            f"Retained {graph_kind} graph · {graph_id or 'active graph'}"
        )
        if graph is not None and changed:
            self._fitted_graph_id = graph_id
            self.frame.after_idle(self.fit_graph)

    def clear_graph(self) -> None:
        """Explicitly clear the presentation-only retained graph."""

        self.set_graph(None)

    def set_enabled(self, _enabled: bool) -> None:
        """The Simulation graph is intentionally read-only."""

    def handle_graph_click(self, edge_id: str) -> bool:
        graph = self._draft or {}
        edge = next(
            (item for item in graph.get("edges", [])
             if isinstance(item, dict) and str(item.get("id")) == str(edge_id)),
            None,
        )
        if not edge or edge.get("clickable") is not True:
            return False
        frame = edge.get("frame")
        if not isinstance(frame, dict) or not callable(self._on_click):
            return False
        return self._on_click(frame) is True

    def show_diagnostics(self) -> None:
        if self._draft is not None and callable(self._on_diagnostics):
            self._on_diagnostics(conversation_graph_diagnostics(self._draft))

    def reset_zoom(self) -> None:
        self._canvas_controller.reset_zoom()

    def fit_graph(self) -> None:
        self._canvas_controller.fit_graph()

    def _draw_graph(self) -> None:
        self._canvas_controller._draw_graph()

    def _on_mouse_wheel(self, event: Any) -> None:
        self._canvas_controller._on_mouse_wheel(event)

    def _zoom_at(self, event: Any, factor: float) -> None:
        self._canvas_controller._zoom_at(event, factor)

    def _start_pan(self, event: Any) -> None:
        self._canvas_controller._start_pan(event)

    def _drag_pan(self, event: Any) -> None:
        self._canvas_controller._drag_pan(event)

    def _stop_pan(self, event: Any) -> None:
        self._canvas_controller._stop_pan(event)
