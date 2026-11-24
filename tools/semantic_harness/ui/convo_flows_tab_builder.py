"""Dedicated 'Convo Flows' tab for inspecting all `.convo` flows, offers, and variants."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from ..codebuilder.convo_flow_inspector import (
    collect_repo_convo_flows,
    format_flow_report,
)


def _resolve_repo_root(app: Any) -> Path | None:
    for attr in ("provider_repo_root", "project_root", "repo_root"):
        val = getattr(app, attr, None)
        if val:
            return Path(val)
    ctx = getattr(app, "context", None)
    if ctx is not None:
        for attr in ("provider_root", "repo_root", "project_root"):
            val = getattr(ctx, attr, None)
            if val:
                return Path(val)
    return None


def build_convo_flows_tab(app: Any, parent: Any) -> dict[str, Any]:
    """Build the dedicated Convo Flows & Variants browser inside `parent`."""
    tk = app._tk
    ttk = app._ttk
    scrolled_text = app._ScrolledText

    parent.rowconfigure(1, weight=1)
    parent.columnconfigure(0, weight=1)

    toolbar = ttk.Frame(parent, padding=(0, 0, 0, 6))
    toolbar.grid(row=0, column=0, sticky="ew")
    toolbar.columnconfigure(3, weight=1)

    filter_var = tk.StringVar(value="")
    script_var = tk.StringVar(value="ALL")
    status_var = tk.StringVar(value="No .convo flows loaded")

    ttk.Label(toolbar, text="Filter:").grid(row=0, column=0, padx=(0, 4))
    filter_entry = ttk.Entry(toolbar, textvariable=filter_var, width=28)
    filter_entry.grid(row=0, column=1, padx=(0, 8))

    ttk.Label(toolbar, text="Script:").grid(row=0, column=2, padx=(0, 4))
    script_combo = ttk.Combobox(
        toolbar,
        textvariable=script_var,
        state="readonly",
        width=30,
        values=("ALL",),
    )
    script_combo.grid(row=0, column=3, sticky="w", padx=(0, 8))

    refresh_btn = ttk.Button(toolbar, text="Reload .convo")
    refresh_btn.grid(row=0, column=4, padx=(0, 8))
    ttk.Label(toolbar, textvariable=status_var).grid(row=0, column=5, sticky="e")

    panes = ttk.PanedWindow(parent, orient="horizontal")
    panes.grid(row=1, column=0, sticky="nsew")

    left = ttk.Frame(panes)
    left.rowconfigure(0, weight=1)
    left.columnconfigure(0, weight=1)
    right = ttk.Frame(panes)
    right.rowconfigure(0, weight=1)
    right.columnconfigure(0, weight=1)
    panes.add(left, weight=2)
    panes.add(right, weight=3)

    columns = ("kind", "variants", "offers", "script")
    tree = ttk.Treeview(left, columns=columns, show="tree headings")
    tree.heading("#0", text="Flow / Beat / Pool ID")
    tree.heading("kind", text="Kind")
    tree.heading("variants", text="Variants")
    tree.heading("offers", text="Offers")
    tree.heading("script", text="Script")
    tree.column("#0", width=260, stretch=True)
    tree.column("kind", width=55, anchor="center", stretch=False)
    tree.column("variants", width=65, anchor="center", stretch=False)
    tree.column("offers", width=55, anchor="center", stretch=False)
    tree.column("script", width=160, stretch=True)
    tree.grid(row=0, column=0, sticky="nsew")

    yscroll = ttk.Scrollbar(left, orient="vertical", command=tree.yview)
    yscroll.grid(row=0, column=1, sticky="ns")
    tree.configure(yscrollcommand=yscroll.set)

    detail_text = scrolled_text(right, wrap="word", state="disabled")
    detail_text.grid(row=0, column=0, sticky="nsew")

    state: dict[str, Any] = {
        "flows": [],
        "by_iid": {},
        "tree": tree,
        "detail_text": detail_text,
        "filter_var": filter_var,
        "script_var": script_var,
        "status_var": status_var,
    }

    def set_detail(content: str) -> None:
        detail_text.configure(state="normal")
        detail_text.delete("1.0", "end")
        detail_text.insert("1.0", content)
        detail_text.configure(state="disabled")

    def render_tree(*_args: Any) -> None:
        for item in tree.get_children():
            tree.delete(item)
        state["by_iid"].clear()
        needle = filter_var.get().strip().lower()
        chosen_script = script_var.get()
        shown = 0
        for idx, flow in enumerate(state["flows"]):
            if chosen_script and chosen_script != "ALL" and flow["scriptName"] != chosen_script:
                continue
            if needle:
                haystack = " ".join([
                    flow["poolId"],
                    flow["scriptName"],
                    flow["kind"],
                    " ".join(v["variant"] + " " + v["text"] for v in flow["variants"]),
                ]).lower()
                if needle not in haystack:
                    continue
            iid = f"flow_{idx}"
            tree.insert(
                "",
                "end",
                iid=iid,
                text=flow["poolId"],
                values=(
                    flow["kind"],
                    len(flow["variants"]),
                    len(flow["offers"]),
                    flow["scriptName"],
                ),
            )
            state["by_iid"][iid] = flow
            shown += 1
        status_var.set(f"Showing {shown} / {len(state['flows'])} flows")
        if shown == 0:
            set_detail("No matching .convo flows.")

    def on_select(_event: Any = None) -> None:
        sel = tree.selection()
        if not sel:
            return
        flow = state["by_iid"].get(sel[0])
        if flow:
            set_detail(format_flow_report(flow))

    def reload_flows() -> list[dict[str, Any]]:
        repo_root = _resolve_repo_root(app)
        flows = collect_repo_convo_flows(repo_root) if repo_root else []
        state["flows"] = flows
        scripts = sorted({f["scriptName"] for f in flows})
        script_combo.configure(values=("ALL", *scripts))
        if script_var.get() not in ("ALL", *scripts):
            script_var.set("ALL")
        render_tree()
        if flows:
            first_iids = tree.get_children()
            if first_iids:
                tree.selection_set(first_iids[0])
                on_select()
        return flows

    refresh_btn.configure(command=reload_flows)
    tree.bind("<<TreeviewSelect>>", on_select)
    filter_var.trace_add("write", render_tree)
    script_combo.bind("<<ComboboxSelected>>", render_tree)

    state["reload"] = reload_flows
    app.convo_flows_view = state
    reload_flows()
    return state
