"""Controller for the sentence-first Quality Sweep workbench."""

from __future__ import annotations

import json
import queue
import threading
import time
from typing import Any, Sequence

from tools.semantic_harness.testing.sweep_batch import SweepExecutionCancelled
from tools.semantic_harness.testing.sweep_dimensions import SweepDimensionInventory, extract_dimension_inventory
from tools.semantic_harness.testing.sweep_planner import CoveragePlan
from tools.semantic_harness.testing.sweep_service import DialogueQualitySweepService


def init_quality_sweep_state(app: Any) -> None:
    if getattr(app, "_qs_initialized", False):
        return
    app._qs_initialized = True

    app.quality_sweep_strategy_var = app._tk.StringVar(value="review")
    app.quality_sweep_id_var = app._tk.StringVar(value="sentence_review")
    app.quality_sweep_languages_var = app._tk.StringVar(value="EN,TL")
    app.quality_sweep_max_cases_var = app._tk.IntVar(value=256)
    app.quality_sweep_batch_size_var = app._tk.IntVar(value=8)
    app.quality_sweep_status_var = app._tk.StringVar(
        value="Ready. Click Generate Sentences."
    )
    app.quality_sweep_summary_var = app._tk.StringVar(value="")
    app.quality_sweep_progress_var = app._tk.DoubleVar(value=0.0)

    app.qs_filter_text_var = app._tk.StringVar(value="")
    app.qs_filter_severity_var = app._tk.StringVar(value="ALL")
    app.qs_filter_flag_var = app._tk.StringVar(value="ALL")
    app.qs_filter_lang_var = app._tk.StringVar(value="ALL")
    app.qs_filter_surface_var = app._tk.StringVar(value="ALL")
    app.qs_filter_reachability_var = app._tk.StringVar(value="ALL")
    app.qs_filter_invalid_only_var = app._tk.BooleanVar(value=False)
    app.qs_filter_duplicate_only_var = app._tk.BooleanVar(value=False)
    app.qs_filter_flagged_only_var = app._tk.BooleanVar(value=False)
    app.qs_filter_count_var = app._tk.StringVar(value="0 sentences")

    app.quality_sweep_is_running = False
    app.quality_sweep_cancel_requested = False
    app.quality_sweep_plan: CoveragePlan | None = None
    app.quality_sweep_manifest: Any | None = None
    app.quality_sweep_cluster_report: Any | None = None
    app.quality_sweep_reachability_report: Any | None = None
    app.quality_sweep_inventory: SweepDimensionInventory | None = None
    app.quality_sweep_evidence_rows: list[dict[str, Any]] = []
    app.quality_sweep_filtered_rows: list[dict[str, Any]] = []
    app.selected_quality_sweep_row: dict[str, Any] | None = None
    app.selected_quality_sweep_cluster: Any | None = None
    app.quality_sweep_event_queue: queue.Queue = queue.Queue()
    app.qs_advanced_visible = False


def _languages(app: Any) -> list[str]:
    raw = str(app.quality_sweep_languages_var.get() or "EN,TL")
    values = [part.strip().upper() for part in raw.split(",") if part.strip()]
    return values or ["EN"]


def _service() -> DialogueQualitySweepService:
    return DialogueQualitySweepService()


def _inventory_from_app(app: Any, service: DialogueQualitySweepService) -> SweepDimensionInventory:
    catalog = getattr(app, "simulation_control_catalog", None)
    if catalog:
        try:
            return extract_dimension_inventory(
                control_catalog=catalog,
                persona_catalog=getattr(app, "persona_catalog", None),
            )
        except Exception:
            pass
    return service.get_dimension_inventory()


def on_qs_generate_sentences(app: Any) -> None:
    """The primary user action: create a broad balanced sentence review run."""
    if getattr(app, "quality_sweep_is_running", False):
        return

    manifest = getattr(app, "quality_sweep_manifest", None)
    if (
        getattr(app, "quality_sweep_plan", None) is not None
        and manifest is not None
        and getattr(manifest, "status", "") in {"CANCELLED", "RUNNING", "PLANNED"}
    ):
        on_qs_run(app)
        return

    run_id = time.strftime("sentence_review_%Y%m%d_%H%M%S")
    app.quality_sweep_id_var.set(run_id)
    app.quality_sweep_strategy_var.set("review")
    app.quality_sweep_progress_var.set(0.0)
    on_qs_plan(app)
    if getattr(app, "quality_sweep_plan", None) is not None:
        on_qs_run(app)


def on_qs_plan(app: Any) -> None:
    strategy = str(app.quality_sweep_strategy_var.get() or "review")
    sweep_id = str(app.quality_sweep_id_var.get() or "sentence_review")
    max_cases = max(1, int(app.quality_sweep_max_cases_var.get() or 256))
    service = _service()

    try:
        inventory = _inventory_from_app(app, service)
        plan = service.plan_sweep(
            strategy=strategy,
            sweep_id=sweep_id,
            languages=_languages(app),
            max_cases=max_cases,
            inventory=inventory,
        )
        app.quality_sweep_inventory = inventory
        app.quality_sweep_plan = plan
        app.quality_sweep_manifest = None
        app.quality_sweep_summary_var.set(
            f"{plan.total_cases} examples · {len(plan.planned_surfaces)} triggers"
        )
        app.quality_sweep_status_var.set(
            f"Ready to generate {plan.total_cases} dialogue examples across "
            f"{len(plan.planned_surfaces)} triggers."
        )
        if hasattr(app, "qs_advanced_summary_var"):
            app.qs_advanced_summary_var.set(
                f"Plan {plan.plan_digest[:8]} · {plan.total_cases} cases · "
                f"{plan.estimated_batches} engine batch(es) · strategy {plan.strategy}"
            )
    except Exception as exc:
        app.quality_sweep_plan = None
        app.quality_sweep_status_var.set(f"Planning failed: {exc}")
        if hasattr(app, "_messagebox"):
            app._messagebox.showerror("Sentence Review", f"Planning failed: {exc}")


def _load_results(
    app: Any,
    service: DialogueQualitySweepService,
    sweep_id: str,
) -> None:
    rows = service.load_evidence_rows(sweep_id)
    # Quality flags are intentionally calculated here so the main sentence
    # table shows duplicate/fallback/run-level problems immediately.
    service.quality_analyzer.analyze_run(rows)
    app.quality_sweep_evidence_rows = rows
    if rows:
        app.quality_sweep_cluster_report = service.cluster_aggregator.aggregate_rows(
            rows, sweep_id=sweep_id
        )
    on_qs_apply_filter(app)


def on_qs_run(app: Any) -> None:
    if getattr(app, "quality_sweep_is_running", False):
        return
    if getattr(app, "quality_sweep_plan", None) is None:
        on_qs_plan(app)
        if getattr(app, "quality_sweep_plan", None) is None:
            return

    plan = app.quality_sweep_plan
    service = _service()
    batch_size = max(
        1,
        min(64, int(app.quality_sweep_batch_size_var.get() or 8)),
    )

    app.quality_sweep_is_running = True
    app.quality_sweep_cancel_requested = False
    app.quality_sweep_status_var.set(
        "Generating dialogue… sentences will appear as batches finish."
    )
    if hasattr(app, "qs_generate_button"):
        app.qs_generate_button.configure(state="disabled")
    if hasattr(app, "qs_cancel_button"):
        app.qs_cancel_button.configure(state="normal")

    event_queue: queue.Queue = queue.Queue()
    app.quality_sweep_event_queue = event_queue

    def worker_thread_fn() -> None:
        try:
            manifest = service.run_sweep(
                plan,
                inventory=app.quality_sweep_inventory,
                batch_size=batch_size,
                is_cancelled=lambda: bool(app.quality_sweep_cancel_requested),
                progress_callback=lambda batch, manifest: event_queue.put(
                    ("progress", batch, manifest)
                ),
            )
            if plan.strategy in ("review", "full") and not app.quality_sweep_cancel_requested:
                try:
                    service.expand_frontier_sentences(
                        plan.sweep_id,
                        inventory=app.quality_sweep_inventory,
                        max_new_cases=4,
                    )
                    manifest = service.load_manifest(plan.sweep_id)
                except Exception:
                    pass
            event_queue.put(("done", manifest))
        except SweepExecutionCancelled:
            try:
                manifest = service.load_manifest(plan.sweep_id)
            except Exception:
                manifest = None
            event_queue.put(("cancelled", manifest))
        except Exception as exc:
            event_queue.put(("error", str(exc)))

    threading.Thread(target=worker_thread_fn, daemon=True).start()

    def poll() -> None:
        handled = False
        while True:
            try:
                event = event_queue.get_nowait()
            except queue.Empty:
                break
            handled = True
            kind = event[0]

            if kind == "progress":
                batch, manifest = event[1], event[2]
                app.quality_sweep_manifest = manifest
                pct = 100.0 * manifest.completed_cases / max(1, manifest.total_cases)
                app.quality_sweep_progress_var.set(pct)
                _load_results(app, service, plan.sweep_id)
                app.quality_sweep_status_var.set(
                    f"Generated {len(app.quality_sweep_evidence_rows)} sentences "
                    f"from {manifest.completed_cases}/{manifest.total_cases} examples "
                    f"({getattr(manifest, 'invalid_surface_cases', 0)} invalid triggers)."
                )
            elif kind == "done":
                manifest = event[1]
                app.quality_sweep_manifest = manifest
                app.quality_sweep_progress_var.set(100.0)
                _load_results(app, service, plan.sweep_id)
                app.quality_sweep_status_var.set(
                    f"Done: {len(app.quality_sweep_evidence_rows)} NPC sentences generated "
                    f"from {manifest.completed_cases} examples. "
                    f"Click a sentence to see exactly what triggered it."
                )
                _finish_run_ui(app)
                return
            elif kind == "cancelled":
                app.quality_sweep_manifest = event[1]
                _load_results(app, service, plan.sweep_id)
                app.quality_sweep_status_var.set(
                    f"Stopped. {len(app.quality_sweep_evidence_rows)} generated sentences "
                    f"were kept. Click Generate Sentences to continue this run."
                )
                _finish_run_ui(app)
                return
            elif kind == "error":
                app.quality_sweep_status_var.set(f"Generation failed: {event[1]}")
                _finish_run_ui(app)
                return

        if getattr(app, "quality_sweep_is_running", False) and hasattr(app, "root"):
            app.root.after(150 if handled else 250, poll)

    if hasattr(app, "root"):
        app.root.after(100, poll)


def _finish_run_ui(app: Any) -> None:
    app.quality_sweep_is_running = False
    if hasattr(app, "qs_generate_button"):
        app.qs_generate_button.configure(state="normal")
    if hasattr(app, "qs_cancel_button"):
        app.qs_cancel_button.configure(state="disabled")


def on_qs_cancel(app: Any) -> None:
    if not getattr(app, "quality_sweep_is_running", False):
        return
    app.quality_sweep_cancel_requested = True
    app.quality_sweep_status_var.set(
        "Stopping safely… completed sentences will be kept."
    )
    if hasattr(app, "qs_cancel_button"):
        app.qs_cancel_button.configure(state="disabled")


def on_qs_refresh(app: Any) -> None:
    sweep_id = str(app.quality_sweep_id_var.get() or "")
    if not sweep_id:
        return
    service = _service()
    try:
        try:
            app.quality_sweep_manifest = service.load_manifest(sweep_id)
        except Exception:
            pass
        _load_results(app, service, sweep_id)
        app.quality_sweep_status_var.set(
            f"Loaded {len(app.quality_sweep_evidence_rows)} generated NPC sentences."
        )
    except Exception as exc:
        app.quality_sweep_status_var.set(f"Reload failed: {exc}")


def on_qs_toggle_advanced(app: Any) -> None:
    frame = getattr(app, "qs_advanced_frame", None)
    if frame is None:
        return
    if getattr(app, "qs_advanced_visible", False):
        frame.grid_forget()
        app.qs_advanced_visible = False
    else:
        frame.grid(row=3, column=0, sticky="ew", pady=(6, 0))
        app.qs_advanced_visible = True


def on_qs_reachability_scan(app: Any) -> None:
    """Advanced-only analysis; never block the Tk event loop."""
    if getattr(app, "_qs_reachability_running", False):
        return
    app._qs_reachability_running = True
    sweep_id = str(app.quality_sweep_id_var.get() or "")
    if hasattr(app, "qs_advanced_summary_var"):
        app.qs_advanced_summary_var.set("Analyzing response pools and variants…")

    q: queue.Queue = queue.Queue()

    def worker() -> None:
        try:
            report = _service().generate_reachability_report(sweep_id)
            q.put(("ok", report))
        except Exception as exc:
            q.put(("error", str(exc)))

    threading.Thread(target=worker, daemon=True).start()

    def poll() -> None:
        try:
            kind, payload = q.get_nowait()
        except queue.Empty:
            if hasattr(app, "root"):
                app.root.after(150, poll)
            return
        app._qs_reachability_running = False
        if kind == "ok":
            report = payload
            app.quality_sweep_reachability_report = report
            if hasattr(app, "qs_advanced_summary_var"):
                app.qs_advanced_summary_var.set(
                    f"Reachability: {report.enumerated_total_pools}/"
                    f"{report.production_total_pools} pools · {report.total_variants} variants · "
                    f"pagination complete={report.pagination_complete}"
                )
        else:
            if hasattr(app, "qs_advanced_summary_var"):
                app.qs_advanced_summary_var.set(f"Reachability failed: {payload}")

    if hasattr(app, "root"):
        app.root.after(100, poll)


def on_qs_apply_filter(app: Any) -> None:
    rows = list(getattr(app, "quality_sweep_evidence_rows", []) or [])
    search = str(app.qs_filter_text_var.get() or "").casefold().strip()
    language = str(app.qs_filter_lang_var.get() or "ALL").upper()
    flagged_only = bool(app.qs_filter_flagged_only_var.get())
    duplicates_only = bool(app.qs_filter_duplicate_only_var.get())

    filtered: list[dict[str, Any]] = []
    for row in rows:
        flags = row.get("quality", {}).get("flags", [])
        names = {str(f.get("name")) for f in flags}

        if flagged_only and not flags:
            continue
        if duplicates_only and not (
            {"DUPLICATE_RENDERED_TEXT", "FALLBACK_SATURATION", "VARIANT_COLLAPSE"}
            & names
        ):
            continue
        if language != "ALL" and str(
            row.get("identity", {}).get("language") or ""
        ).upper() != language:
            continue

        if search:
            haystack = " ".join(
                [
                    str(row.get("output", {}).get("finalText") or ""),
                    _trigger_text(row),
                    _context_text(row),
                    str(row.get("semanticPath", {}).get("semanticTemplateID") or ""),
                    str(row.get("semanticPath", {}).get("semanticVariantID") or ""),
                    " ".join(names),
                ]
            ).casefold()
            if search not in haystack:
                continue
        filtered.append(row)

    app.quality_sweep_filtered_rows = filtered
    app.qs_filter_count_var.set(
        f"Showing {len(filtered)} of {len(rows)} sentence(s)"
    )
    _populate_evidence_tree(app, filtered)


def on_qs_clear_filter(app: Any) -> None:
    app.qs_filter_text_var.set("")
    app.qs_filter_lang_var.set("ALL")
    app.qs_filter_flagged_only_var.set(False)
    app.qs_filter_duplicate_only_var.set(False)
    on_qs_apply_filter(app)


def _trigger_text(row: dict[str, Any]) -> str:
    ident = row.get("identity", {})
    input_info = ident.get("input") or {}
    if input_info.get("text"):
        return f'Player: "{input_info["text"]}"'
    if input_info.get("rootChoice"):
        return f'Menu: {input_info["rootChoice"]}'
    surface = str(ident.get("plannedSurface") or "")
    if surface.startswith("scenario.utterance:"):
        return f'Player: "{surface.split(":", 1)[1]}"'
    return surface or "(unknown trigger)"


def _context_text(row: dict[str, Any]) -> str:
    trigger = row.get("trigger", {})
    rel = trigger.get("relationshipSummary") or {}
    persona = trigger.get("personaSummary") or {}
    state = trigger.get("stateSummary") or {}

    bits: list[str] = []
    bond = rel.get("bondKind")
    if bond and bond != "none":
        bits.append(f"bond={bond}")
    if rel.get("approval") is not None:
        bits.append(f"approval={rel.get('approval')}")
    style = persona.get("socialStyle")
    if style:
        bits.append(f"style={style}")
    traits = persona.get("traits") or []
    if traits:
        bits.append("traits=" + ",".join(str(x) for x in traits[:2]))
    if state.get("activeBehavior"):
        bits.append(f"behavior={state.get('activeBehavior')}")
    npc_needs = state.get("npcNeeds") or {}
    if npc_needs.get("highest"):
        bits.append(f"need={npc_needs.get('highest')}:{npc_needs.get('level')}")
    return " · ".join(bits) or "baseline"


def _problem_text(row: dict[str, Any]) -> str:
    flags = row.get("quality", {}).get("flags", [])
    if not flags:
        return "—"
    names = [str(f.get("name") or "") for f in flags if f.get("name")]
    return ", ".join(names[:3])


def _source_owner_text(row: dict[str, Any]) -> str:
    sel = row.get("selectionProvenance") or {}
    source = sel.get("canonicalSourceOwner")
    if source and source != "UNKNOWN":
        return str(source)
    # Infer for display if missing from older serialized rows
    sem = row.get("semanticPath") or {}
    out = row.get("output") or {}
    txt = str(out.get("finalText") or "")
    sem_tpl = str(sem.get("semanticTemplateID") or "")
    sem_var = str(sem.get("semanticVariantID") or sel.get("selectedVariantID") or "")
    ren_key = str(out.get("renderedKey") or "")
    reached = str(sem.get("reachedRoute") or "")

    if (
        sem_tpl == "semantic.ask_clarification"
        or reached == "semantic.ask_clarification"
        or txt == "I'm not sure what you mean."
    ):
        return "core.fallback"
    if ren_key.startswith("response.") or sem_tpl.startswith("response."):
        return "categories.json"
    if ".dataset." in sem_var:
        parts = sem_var.split(".dataset.")[0].split(".")
        return f"dialogue_dataset.{parts[-1] if parts else 'dialogue'}"
    if ".dataset." in sem_tpl:
        parts = sem_tpl.split(".dataset.")[0].split(".")
        return f"dialogue_dataset.{parts[-1] if parts else 'dialogue'}"
    if "whats_up" in sem_var or "whats_up" in sem_tpl:
        return "PNC_SemanticDialogueResponseCatalog_Questions_IdentityActivity.lua"
    if "greeting" in sem_var or "greeting" in sem_tpl:
        return "PNC_SemanticDialogueResponseCatalog_FlowGreeting.lua"
    if "wellbeing" in sem_var or "wellbeing" in sem_tpl:
        return "PNC_SemanticDialogueResponseCatalog_Questions_WellbeingMedical.lua"
    return "UNKNOWN"


def _populate_evidence_tree(app: Any, rows: Sequence[dict[str, Any]]) -> None:
    tree = getattr(app, "qs_evidence_tree", None)
    if tree is None:
        return
    for item in tree.get_children():
        tree.delete(item)

    for index, row in enumerate(rows):
        row_id = str(row.get("rowID") or f"row-{index}")
        tree.insert(
            "",
            "end",
            iid=row_id,
            values=(
                str(row.get("output", {}).get("finalText") or ""),
                _trigger_text(row),
                _context_text(row),
                str(row.get("identity", {}).get("language") or ""),
                _problem_text(row),
                _source_owner_text(row),
            ),
        )


def on_qs_evidence_select(app: Any) -> None:
    tree = getattr(app, "qs_evidence_tree", None)
    if tree is None:
        return
    selection = tree.selection()
    if not selection:
        return
    row_id = selection[0]
    row = next(
        (
            item
            for item in app.quality_sweep_filtered_rows
            if str(item.get("rowID")) == row_id
        ),
        None,
    )
    if row is None:
        return
    app.selected_quality_sweep_row = row
    _populate_evidence_inspector(app, row)


def _populate_evidence_inspector(app: Any, row: dict[str, Any]) -> None:
    text_widget = getattr(app, "qs_inspector_text", None)
    if text_widget is None:
        return

    ident = row.get("identity", {})
    trig = row.get("trigger", {})
    rel = trig.get("relationshipSummary") or {}
    persona = trig.get("personaSummary") or {}
    state = trig.get("stateSummary") or {}
    sem = row.get("semanticPath") or {}
    out = row.get("output") or {}
    sel = row.get("selectionProvenance") or {}
    flags = row.get("quality", {}).get("flags", [])

    lines = [
        f'NPC: "{out.get("finalText") or ""}"',
        f"Trigger: {_trigger_text(row)}",
        f"Language: {ident.get('language')}",
        "",
        "CONTEXT",
        f"Bond: {rel.get('bondKind')} · Relationship: {rel.get('relationshipState')}",
        f"Approval: {rel.get('approval')} · Respect: {rel.get('respect')} · "
        f"Familiarity: {rel.get('familiarity')} · Identity trust: {rel.get('identityTrust')}",
        f"Social style: {persona.get('socialStyle')} · Traits: {persona.get('traits')}",
        f"Personality: {json.dumps(persona.get('personality') or {}, ensure_ascii=False)}",
        f"NPC needs: {json.dumps(state.get('npcNeeds') or {}, ensure_ascii=False)}",
        f"Health: {json.dumps(state.get('npcHealth') or {}, ensure_ascii=False)} · "
        f"Behavior: {state.get('activeBehavior')} · Activity: {state.get('activity')}",
        "",
        "SEMANTIC PATH",
        f"Intent: {sem.get('intent')} · Subject: {sem.get('subject')} · Speech act: {sem.get('speechAct')}",
        f"Template: {sem.get('semanticTemplateID')}",
        f"Variant: {sem.get('semanticVariantID') or sel.get('selectedVariantID')}",
        f"Realization: {sem.get('realizationFamily')} / {sem.get('realizationVariant')}",
        f"Phrase: {sem.get('phraseID')} · Translation: {sem.get('translationKey')}",
        "",
        "QUALITY",
        json.dumps(flags, indent=2, ensure_ascii=False) if flags else "No automatic flags.",
        "",
        "SOURCE",
        _source_owner_text(row),
        "",
        "RAW CHANGED PARAMETERS",
        json.dumps(trig.get("parameters") or {}, indent=2, ensure_ascii=False),
    ]

    text_widget.configure(state="normal")
    text_widget.delete("1.0", "end")
    text_widget.insert("end", "\n".join(lines))
    text_widget.configure(state="disabled")


def on_qs_open_full_inspector(app: Any) -> None:
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row:
        if hasattr(app, "_messagebox"):
            app._messagebox.showinfo(
                "Sentence Review", "Select a generated sentence first."
            )
        return

    ident = row.get("identity") or {}
    input_spec = dict(ident.get("input") or {})
    language = str(ident.get("language") or "EN")
    trace_handle = row.get("traceHandle") or {}
    service = _service()

    try:
        resolved = service.resolve_trace(
            trace_handle,
            turn_input_spec=input_spec,
            language=language,
            parameters=row.get("trigger", {}).get("parameters") or {},
            inventory=getattr(app, "quality_sweep_inventory", None),
        )
        if resolved.get("stale"):
            if hasattr(app, "_messagebox"):
                app._messagebox.showwarning(
                    "Stale Trace", str(resolved.get("staleReason"))
                )
            return
        _show_inspector_dialog(app, row, resolved)
    except Exception as exc:
        if hasattr(app, "_messagebox"):
            app._messagebox.showerror(
                "Inspector Error", f"Could not recreate this sentence: {exc}"
            )


def _show_inspector_dialog(
    app: Any,
    row: dict[str, Any],
    resolved: dict[str, Any],
) -> None:
    top = app._tk.Toplevel(app.root)
    top.title(
        f"Full Conversation Inspector · {row.get('identity', {}).get('caseID')}"
    )
    top.geometry("900x650")
    widget = app._ScrolledText(top, wrap="none")
    widget.pack(fill="both", expand=True, padx=8, pady=8)
    widget.insert("end", json.dumps(resolved, indent=2, ensure_ascii=False))
    widget.configure(state="disabled")


def on_qs_copy_evidence(app: Any) -> None:
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row or not hasattr(app, "root"):
        return
    app.root.clipboard_clear()
    app.root.clipboard_append(json.dumps(row, indent=2, ensure_ascii=False))
    app.quality_sweep_status_var.set("Selected sentence evidence copied.")


def on_qs_export_bundle(app: Any) -> None:
    sweep_id = str(app.quality_sweep_id_var.get() or "")
    if not sweep_id:
        return
    service = _service()
    try:
        bundle = service.generate_review_bundle(sweep_id)
        out_path = service.base_dir / sweep_id / "review_bundle.json"
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(
            json.dumps(bundle, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        if hasattr(app, "qs_advanced_summary_var"):
            app.qs_advanced_summary_var.set(
                f"Review bundle saved to {out_path}"
            )
    except Exception as exc:
        if hasattr(app, "qs_advanced_summary_var"):
            app.qs_advanced_summary_var.set(f"Export failed: {exc}")


# Compatibility hooks retained for older tests / the compact Simulation launcher.
def on_qs_cluster_select(app: Any) -> None:
    return


def on_qs_replay_case(app: Any) -> None:
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row or not app.quality_sweep_plan:
        return
    case_id = row.get("identity", {}).get("caseID")
    if not case_id:
        return
    app.quality_sweep_plan = _service().plan_replay(
        app.quality_sweep_plan, [case_id]
    )
    on_qs_run(app)


def on_qs_replay_cluster(app: Any) -> None:
    cluster = getattr(app, "selected_quality_sweep_cluster", None)
    if not cluster or not app.quality_sweep_plan:
        return
    app.quality_sweep_plan = _service().plan_replay(
        app.quality_sweep_plan, cluster.affected_case_ids
    )
    on_qs_run(app)


def on_qs_locate_source(app: Any) -> None:
    row = getattr(app, "selected_quality_sweep_row", None)
    if not row:
        return
    owner = _source_owner_text(row)
    if hasattr(app, "_messagebox"):
        app._messagebox.showinfo(
            "Source",
            f"Canonical source owner: {owner}\n"
            "Direct Studio navigation remains an advanced developer feature.",
        )
