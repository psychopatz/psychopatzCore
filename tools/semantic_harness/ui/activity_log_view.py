"""Tk activity-log polling and rendering for the semantic harness UI."""

from __future__ import annotations

from typing import Any

from tools.semantic_harness.activity import format_activity_event


def schedule_activity_poll(app: Any) -> None:
    """Schedule the next bounded refresh of the shared activity timeline."""

    if app.closed:
        return
    if app._activity_after is not None:
        try:
            app.root.after_cancel(app._activity_after)
        except app._tk.TclError:
            pass
    app._activity_after = app.root.after(150, app._poll_activity_log)


def poll_activity_log(app: Any) -> None:
    """Render only activity records not already shown in the UI."""

    if app._activity_after is not None:
        try:
            app.root.after_cancel(app._activity_after)
        except app._tk.TclError:
            pass
    app._activity_after = None
    if app.closed:
        return
    records = app.activity_log.new_shared_events(app._activity_seen_ids)
    if records:
        app.activity_log_widget.configure(state="normal")
        for record in records:
            app.activity_log_widget.insert(
                "end", format_activity_event(record) + "\n"
            )
            event_id = str(record.get("eventID") or "")
            if event_id:
                app._activity_seen_ids.add(event_id)
        app.activity_log_widget.see("end")
        app.activity_log_widget.configure(state="disabled")
        app.activity_log_status.set(
            f"{len(app._activity_seen_ids)} shown · shared GUI/CLI/agent timeline"
        )
    schedule_activity_poll(app)


def clear_activity_log(app: Any) -> None:
    """Clear the visible activity view while retaining shared history."""

    app._activity_seen_ids.update(
        str(record.get("eventID") or "")
        for record in app.activity_log.shared_snapshot()
        if record.get("eventID")
    )
    app.activity_log.clear()
    app.activity_log_widget.configure(state="normal")
    app.activity_log_widget.delete("1.0", "end")
    app.activity_log_widget.configure(state="disabled")
    app.activity_log_status.set("Activity view cleared · shared history retained")
