"""Own GUI shutdown and entry-point concerns outside the shell façade."""

from __future__ import annotations

import argparse
import sys
from typing import Any

from tools.semantic_harness.runtime.config import ConfigurationError
from tools.semantic_harness.transport.process import HarnessError


def close_app(app: Any) -> None:
    if app.closed:
        return
    app.closed = True
    app.activity_log.record("ui", "window_close")
    app._save_ui_state()
    for after_id in (
        app._relationship_preview_after,
        app._personality_preview_after,
        app._auto_replay_after,
        app._auto_apply_after,
        app._splitter_restore_after,
        app._activity_after,
        app._foreground_poll_after,
        app._background_poll_after,
        getattr(app, "_worker_ready_hydration_after", None),
        getattr(app, "_selection_ensure_after", None),
        getattr(app, "_initial_ui_ready_after", None),
        getattr(app, "_studio_editor_build_after", None),
        getattr(app, "_selection_poll_after", None),
        app._start_worker_after,
        app._startup_after,
        app._explore_retry_after,
        app._layout_restore_after,
        app._restore_workbench_tabs_after,
        app._restore_ui_state_after,
        getattr(app, "_ui_state_save_after", None),
    ):
        if after_id is not None:
            try:
                app.root.after_cancel(after_id)
            except app._tk.TclError:
                pass
    # A few Tk widgets and startup callbacks schedule short-lived timers that
    # are not owned by a single controller.  On normal close they must not
    # survive the interpreter teardown and later touch destroyed StringVars.
    try:
        pending_after = app.root.tk.call("after", "info")
    except app._tk.TclError:
        pending_after = ()
    for after_id in pending_after:
        try:
            app.root.after_cancel(after_id)
        except app._tk.TclError:
            pass
    # Tk shutdown must not wait on the serialized worker executor.  The
    # worker/process close operation is bounded and is submitted for cleanup;
    # waiting here can make the window appear frozen when the worker is still
    # draining a request or its stdout reader is unwinding.
    app.session.close(wait=False)
    app.root.destroy()


def run_gui(app_class: Any, arguments: argparse.Namespace) -> int:
    try:
        import tkinter as tk
    except ImportError as error:
        print(
            f"semantic harness GUI unavailable: install Tk or use --no-gui ({error})",
            file=sys.stderr,
        )
        return 2
    try:
        root = tk.Tk()
    except tk.TclError as error:
        print(
            f"semantic harness GUI unavailable: {error}; use --no-gui or run with a display",
            file=sys.stderr,
        )
        return 2

    # Keep a real, paintable window alive while the provider-neutral shell is
    # being assembled. The full Semantic Lab contains many Tk panes and must
    # not be constructed before the first main-loop pass; doing so makes a
    # double-click look like a no-op while Python and Lua are still busy.
    from tkinter import ttk

    root.title("Semantic Lab")
    root.minsize(720, 420)
    root.geometry("980x620")
    bootstrap = ttk.Frame(root, padding=18)
    bootstrap.pack(fill="both", expand=True)
    bootstrap.columnconfigure(0, weight=1)
    bootstrap.rowconfigure(2, weight=1)
    status_var = tk.StringVar(value="Starting Semantic Lab…")
    ttk.Label(
        bootstrap,
        textvariable=status_var,
        font=("TkDefaultFont", 12, "bold"),
    ).grid(row=0, column=0, sticky="w", pady=(0, 8))
    ttk.Label(
        bootstrap,
        text="Loading the shared Core interface and selected provider…",
        anchor="w",
    ).grid(row=1, column=0, sticky="ew")
    detail = tk.Text(bootstrap, height=8, wrap="word", state="disabled")
    detail.grid(row=2, column=0, sticky="nsew", pady=(16, 0))
    root._semantic_harness_bootstrap = bootstrap

    exit_code = [0]

    def close_bootstrap() -> None:
        root.destroy()

    def show_failure(error: BaseException) -> None:
        exit_code[0] = 2
        message = f"{type(error).__name__}: {error}"
        print(f"semantic harness GUI error: {message}", file=sys.stderr)
        try:
            status_var.set("Startup failed")
            detail.configure(state="normal")
            detail.delete("1.0", "end")
            detail.insert(
                "end",
                message
                + "\n\nThe window is still open so the failure is visible. "
                "Close it after reviewing this message.",
            )
            detail.configure(state="disabled")
        except tk.TclError:
            pass
        root.protocol("WM_DELETE_WINDOW", close_bootstrap)

    def start_app() -> None:
        try:
            # Force the small bootstrap to map before the expensive full
            # widget tree is constructed. This call is safe here because the
            # bootstrap has no layout-restoration or worker callbacks yet.
            root.update_idletasks()
            root.update()
            root.title("Semantic Lab — starting")
            root._semantic_harness_app = app_class(root, arguments)
        except (HarnessError, ConfigurationError, OSError, ValueError) as error:
            show_failure(error)
        except Exception as error:  # pragma: no cover - defensive GUI boundary
            show_failure(error)

    root.protocol("WM_DELETE_WINDOW", close_bootstrap)
    try:
        # Paint the bootstrap before expensive shell construction. This uses
        # a timer instead of an idle callback so worker polling cannot starve
        # the first visible frame.
        root.after(50, start_app)
        root.mainloop()
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        print(f"semantic harness GUI error: {error}", file=sys.stderr)
        try:
            root.destroy()
        except tk.TclError:
            pass
        return 2
    return exit_code[0]
