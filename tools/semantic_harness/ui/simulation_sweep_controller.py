"""Controller logic for the Simulation Quality Sweep UI tab."""

from __future__ import annotations

import json
from typing import Any

from tools.semantic_harness.testing.sweep_service import DialogueQualitySweepService


def on_sweep_plan(app: Any) -> None:
    """Plan a sweep and update UI estimates."""
    strategy = str(app.sweep_strategy_var.get() or "smoke")
    sweep_id = str(app.sweep_id_var.get() or "dialogue_sweep_v1")

    active_worker = app.worker if getattr(app, "worker_ready", False) and getattr(app, "worker", None) else None
    service = DialogueQualitySweepService()
    try:
        inventory = None
        if hasattr(app, "simulation_control_catalog") and app.simulation_control_catalog:
            from tools.semantic_harness.testing.sweep_dimensions import extract_dimension_inventory
            inventory = extract_dimension_inventory(
                control_catalog=app.simulation_control_catalog,
                persona_catalog=getattr(app, "persona_catalog", None),
            )
        elif active_worker is not None:
            from tools.semantic_harness.testing.sweep_dimensions import extract_dimension_inventory
            inventory = extract_dimension_inventory(active_worker)

        plan = service.plan_sweep(
            strategy=strategy,
            sweep_id=sweep_id,
            inventory=inventory,
            worker=active_worker,
        )
        app.current_sweep_plan = plan
        app.sweep_estimate_var.set(
            f"Planned {plan.total_cases} cases across {plan.estimated_batches} batch(es)."
        )
        app.sweep_status_var.set(f"Plan ready: {plan.plan_digest[:8]}")
        app._refresh_sweep_feedback(f"Plan generated: {plan.total_cases} cases.")
    except Exception as exc:
        app.sweep_status_var.set(f"Plan error: {exc}")
        if hasattr(app, "_messagebox"):
            app._messagebox.showerror("Quality Sweep", f"Planning failed: {exc}")


def on_sweep_run(app: Any) -> None:
    """Execute or resume sweep batches."""
    if not hasattr(app, "current_sweep_plan") or app.current_sweep_plan is None:
        on_sweep_plan(app)
        if not hasattr(app, "current_sweep_plan") or app.current_sweep_plan is None:
            return

    plan = app.current_sweep_plan
    service = DialogueQualitySweepService()

    app.sweep_status_var.set("Running batches…")
    app.sweep_cancel_requested = False

    def is_cancelled() -> bool:
        return getattr(app, "sweep_cancel_requested", False)

    def on_progress(batch: Any, manifest: Any) -> None:
        pct = (manifest.completed_cases / max(1, manifest.total_cases)) * 100
        app.sweep_progress_var.set(pct)
        app.sweep_status_var.set(
            f"Batch {batch.batch_id} {batch.status} ({manifest.completed_cases}/{manifest.total_cases} cases)"
        )
        if hasattr(app, "root"):
            app.root.update_idletasks()

    try:
        inventory = None
        if hasattr(app, "simulation_control_catalog") and app.simulation_control_catalog:
            from tools.semantic_harness.testing.sweep_dimensions import extract_dimension_inventory
            inventory = extract_dimension_inventory(
                control_catalog=app.simulation_control_catalog,
                persona_catalog=getattr(app, "persona_catalog", None),
            )

        manifest = service.run_sweep(
            plan,
            inventory=inventory,
            is_cancelled=is_cancelled,
            progress_callback=on_progress,
        )
        app.current_sweep_manifest = manifest
        app.sweep_status_var.set(
            f"Complete: {manifest.completed_cases} passed, {manifest.failed_cases} failed."
        )
        on_sweep_refresh(app)
    except Exception as exc:
        app.sweep_status_var.set(f"Run error: {exc}")
        if hasattr(app, "_messagebox"):
            app._messagebox.showerror("Quality Sweep", f"Run failed: {exc}")


def on_sweep_cancel(app: Any) -> None:
    """Request cancellation of running sweep."""
    app.sweep_cancel_requested = True
    app.sweep_status_var.set("Cancelling…")


def on_sweep_refresh(app: Any) -> None:
    """Load cluster report and populate UI treeview."""
    sweep_id = str(app.sweep_id_var.get() or "dialogue_sweep_v1")
    service = DialogueQualitySweepService()

    try:
        report = service.generate_cluster_report(sweep_id)
        app.current_cluster_report = report

        # Clear existing items
        for item in app.sweep_cluster_tree.get_children():
            app.sweep_cluster_tree.delete(item)

        for c in report.clusters:
            app.sweep_cluster_tree.insert(
                "",
                "end",
                iid=c.cluster_id,
                values=(
                    c.severity,
                    c.primary_flag,
                    c.count,
                    c.canonical_source_owner,
                    c.cluster_id,
                ),
            )

        app.sweep_report_summary_var.set(
            f"Total rows: {report.total_rows} · Flagged: {report.flagged_rows} · "
            f"Clusters: {report.total_clusters}"
        )
    except Exception as exc:
        app.sweep_report_summary_var.set(f"Could not load report: {exc}")


def on_sweep_cluster_select(app: Any) -> None:
    """Show details and representative examples for selected cluster."""
    selected = app.sweep_cluster_tree.selection()
    if not selected:
        return
    cluster_id = selected[0]
    report = getattr(app, "current_cluster_report", None)
    if not report:
        return

    cluster = next((c for c in report.clusters if c.cluster_id == cluster_id), None)
    if not cluster:
        return

    app.selected_sweep_cluster = cluster

    text_widget = app.sweep_details_text
    text_widget.configure(state="normal")
    text_widget.delete("1.0", "end")

    header = (
        f"Cluster: {cluster.cluster_id}\n"
        f"Flag: {cluster.primary_flag} [{cluster.severity} / {cluster.confidence}]\n"
        f"Count: {cluster.count} affected sentence(s)\n"
        f"Source Owner: {cluster.canonical_source_owner}\n"
        f"Remedy: {cluster.suggested_remedy}\n"
        f"{'='*60}\n\n"
        f"Representative Examples:\n"
    )
    text_widget.insert("end", header)

    for i, ex in enumerate(cluster.representative_examples, 1):
        ex_str = (
            f"[{i}] Case: {ex.get('caseID')}\n"
            f"    Text: \"{ex.get('finalText')}\"\n"
            f"    Bond: {ex.get('bondKind')} | Phrase: {ex.get('phraseID')}\n"
            f"    Parameters: {json.dumps(ex.get('parameters', {}))}\n"
            f"    Flag Detail: {ex.get('flagDetail')}\n\n"
        )
        text_widget.insert("end", ex_str)

    text_widget.configure(state="disabled")


def on_sweep_replay(app: Any) -> None:
    """Replay selected cluster's affected cases."""
    cluster = getattr(app, "selected_sweep_cluster", None)
    if not cluster:
        if hasattr(app, "_messagebox"):
            app._messagebox.showinfo("Quality Sweep", "Please select a defect cluster to replay.")
        return

    plan = getattr(app, "current_sweep_plan", None)
    if not plan:
        on_sweep_plan(app)
        plan = getattr(app, "current_sweep_plan", None)
        if not plan:
            return

    service = DialogueQualitySweepService()
    replay_plan = service.plan_replay(plan, cluster.affected_case_ids)
    app.current_sweep_plan = replay_plan
    app.sweep_estimate_var.set(
        f"Replay plan ready: {replay_plan.total_cases} cases for {cluster.cluster_id}."
    )
    on_sweep_run(app)
